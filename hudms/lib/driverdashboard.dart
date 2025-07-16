import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hudms/screens/driverscreens/driversetting.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:hudms/components/LocationUploader.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({Key? key}) : super(key: key);

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  final Location _location = Location();
  Timer? _refreshTimer;

  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<DocumentSnapshot>? _userLocationSubscription;

  String driverId = "userI122d"; // Replace with actual driver ID
  String driverName = "";
  String driverPhone = "";
  String ambulanceNumber = "";
  List<Map<String, dynamic>> pendingRequests = [];
  Map<String, dynamic>? acceptedUserLocation;

  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  final PolylinePoints polylinePoints = PolylinePoints();
  final String googleMapsApiKey = "YOUR_GOOGLE_MAPS_API_KEY";

  @override
  void initState() {
    super.initState();
    _getLocation();
    _fetchDriverInfo();
    _fetchAmbulanceRequests();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationSubscription?.cancel();
    _userLocationSubscription?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchAmbulanceRequests();
    });
  }

  final user = FirebaseAuth.instance.currentUser;

  Future<void> _getLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final locationData = await _location.getLocation();
    setState(() {
      _currentPosition = LatLng(locationData.latitude!, locationData.longitude!);
    });
  }

  Future<void> _fetchDriverInfo() async {
    final doc = await FirebaseFirestore.instance.collection('ambulances').doc(user?.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        driverName = data['driverName'] ?? '';
        driverPhone = data['driverPhone'] ?? '';
        ambulanceNumber = data['registrationNo'] ?? '';
      });
    }
  }

  Future<void> _fetchAmbulanceRequests() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ambulance_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      List<Map<String, dynamic>> requestsWithUserData = [];

      for (var doc in snapshot.docs) {
        final request = {'id': doc.id, ...doc.data()};
        final registrationNumber = request['userId'];

        if (registrationNumber != null) {
          final studentDoc = await FirebaseFirestore.instance
              .collection('ambulance_request')
              .doc(registrationNumber)
              .get();

          if (studentDoc.exists) {
            final studentData = studentDoc.data()!;
            request['studentName'] = studentData['name'] ?? 'Unknown';
            request['studentPhone'] = studentData['phone'] ?? 'N/A';
            request['registrationNumber'] = registrationNumber;
          }
        }

        requestsWithUserData.add(request);
      }

      setState(() {
        pendingRequests = requestsWithUserData;
      });
    } catch (e) {
      print("Error fetching requests: $e");
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    final locationData = await _location.getLocation();

    final requestDoc = await FirebaseFirestore.instance
        .collection('ambulance_requests')
        .doc(requestId)
        .get();

    final requestData = requestDoc.data();
    if (requestData == null) return;

    final double? userLat = requestData['latitude'];
    final double? userLng = requestData['longitude'];

    if (userLat != null && userLng != null) {
      acceptedUserLocation = {'latitude': userLat, 'longitude': userLng};
      await _createRoute(_currentPosition!, LatLng(userLat, userLng));
    }

    await FirebaseFirestore.instance
        .collection('ambulance_requests')
        .doc(requestId)
        .update({
      'status': 'accepted',
      'driverId': user?.uid,
      'handledBy': user?.uid,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'ambulanceNumber': ambulanceNumber,
      'driverLocation': {
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
      },
    });

    setState(() {
      pendingRequests.removeWhere((req) => req['id'] == requestId);
    });

    // Start live location updates for driver
    _locationSubscription?.cancel();
    _locationSubscription = _location.onLocationChanged.listen((newLocation) {
      FirebaseFirestore.instance
          .collection('ambulance_requests')
          .doc(requestId)
          .update({
        'driverLocation': {
          'latitude': newLocation.latitude,
          'longitude': newLocation.longitude,
        },
      });
    });

    // Listen for user location changes every time Firestore updates the request
    _userLocationSubscription?.cancel();
    _userLocationSubscription = FirebaseFirestore.instance
        .collection('ambulance_requests')
        .doc(requestId)
        .snapshots()
        .listen((docSnapshot) {
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final userLoc = data['userLocation'] ?? data['location'] ?? null;

        if (userLoc != null && mounted) {
          final double? lat = userLoc['latitude'];
          final double? lng = userLoc['longitude'];
          if (lat != null && lng != null) {
            setState(() {
              acceptedUserLocation = {'latitude': lat, 'longitude': lng};
            });
          }
        }
      }
    });

    Navigator.pop(context);
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    await FirebaseFirestore.instance
        .collection('ambulance_requests')
        .doc(requestId)
        .update({'status': status});

    _locationSubscription?.cancel(); // stop live tracking
    _userLocationSubscription?.cancel(); // stop user location tracking

    setState(() {
      pendingRequests.removeWhere((req) => req['id'] == requestId);
      if (status != 'accepted') {
        polylines.clear();
        acceptedUserLocation = null;
      }
    });

    Navigator.pop(context);
  }

  Future<void> _createRoute(LatLng start, LatLng end) async {
    final result = await polylinePoints.getRouteBetweenCoordinates(
      googleMapsApiKey,
      PointLatLng(start.latitude, start.longitude),
      PointLatLng(end.latitude, end.longitude),
    );

    if (result.points.isNotEmpty) {
      polylineCoordinates = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      setState(() {
        polylines.clear();
        polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            color: Colors.blue,
            width: 5,
            points: polylineCoordinates,
          ),
        );
      });
    }
  }

  void _showRequestsPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(12.0),
          child: pendingRequests.isEmpty
              ? const Center(child: Text("No pending requests."))
              : ListView.builder(
            controller: controller,
            itemCount: pendingRequests.length,
            itemBuilder: (context, index) {
              final request = pendingRequests[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name: ${request['userName'] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 16)),
                      Text("Contact: ${request['userPhone'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => _acceptRequest(request['id']),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            child: const Text("Accept"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _updateRequestStatus(request['id'], 'rejected'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text("Reject"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _updateRequestStatus(request['id'], 'completed'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue),
                            child: const Text("Complete"),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _updateRequestStatus(request['id'], 'cancelled'),
                        child: const Text("Cancel Ride",
                            style: TextStyle(color: Colors.red)),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {};

    for (var request in pendingRequests) {
      if (request['latitude'] != null && request['longitude'] != null) {
        markers.add(
          Marker(
            markerId: MarkerId(request['id']),
            position: LatLng(request['latitude'], request['longitude']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: request['userName'] ?? 'Request'),
          ),
        );
      }
    }

    if (acceptedUserLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("acceptedUser"),
          position: LatLng(
            acceptedUserLocation!['latitude'],
            acceptedUserLocation!['longitude'],
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: "User Location"),
        ),
      );
    }

    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("driver"),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: "Your Location"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text("WELCOME $driverName"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DriverSettingsScreens(),
                ),
              );
            },
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition!,
          zoom: 14,
        ),
        markers: markers,
        polylines: polylines,
        onMapCreated: (controller) => _mapController = controller,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestsPopup,
        label: const Text("User Requests"),
        icon: const Icon(Icons.directions_car_filled),
        backgroundColor: Colors.teal,
      ),
    );
  }}