import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hudms/screens/userdhboardsscreen/driverinfo.dart';

class RequestAmbulanceScreen extends StatefulWidget {
  @override
  _RequestAmbulanceScreenState createState() => _RequestAmbulanceScreenState();
}

class _RequestAmbulanceScreenState extends State<RequestAmbulanceScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LatLng? _userLatLng;
  LatLng? _driverLatLng;
  GoogleMapController? _mapController;
  Timer? _locationTimer;
  String? _requestId;
  bool isRequestActive = false;
  bool isDriverAccepted = false;

  String? driverName;
  String? driverPhone;
  String? ambulanceNumber;

  StreamSubscription<DocumentSnapshot>? _requestSubscription;
  Timer? _driverLocationTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _userLatLng = LatLng(position.latitude, position.longitude);
    });

    _moveCameraTo(_userLatLng!);
  }

  Future<void> _startLocationUpdates() async {
    _locationTimer = Timer.periodic(Duration(seconds: 3), (_) async {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted && isRequestActive) {
        setState(() {
          _userLatLng = LatLng(position.latitude, position.longitude);
        });

        _moveCameraTo(_userLatLng!);

        if (_requestId != null) {
          await _firestore.collection('ambulance_requests').doc(_requestId).update({
            'userLocation.lat': _userLatLng!.latitude,
            'userLocation.lng': _userLatLng!.longitude,
          });
        }
      }
    });
  }

  Future<void> _sendAmbulanceRequest() async {
    final user = _auth.currentUser;
    if (user == null || _userLatLng == null) return;

    final existingRequests = await _firestore
        .collection('ambulance_requests')
        .where('userId', isEqualTo: user.uid)
        .where('status', whereIn: ['pending', 'accepted'])
        .get();

    if (existingRequests.docs.isNotEmpty) {
      _showPopup('You already have a request in progress.');
      return;
    }

    final studentSnap = await _firestore
        .collection('students')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();

    final studentData = studentSnap.docs.first.data();

    final docRef = await _firestore.collection('ambulance_requests').add({
      'userId': user.uid,
      'userName': studentData['name'],
      'userPhone': studentData['phone'],
      'userLocation': {
        'lat': _userLatLng!.latitude,
        'lng': _userLatLng!.longitude,
      },
      'status': 'pending',
      'timestamp': DateTime.now(),
    });

    setState(() {
      _requestId = docRef.id;
      isRequestActive = true;
    });

    _startLocationUpdates();
    _listenForRequestUpdates(docRef.id);
  }

  void _listenForRequestUpdates(String docId) {
    _requestSubscription?.cancel();

    _requestSubscription = _firestore
        .collection('ambulance_requests')
        .doc(docId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data()!;
      final status = data['status'];

      if (status == 'rejected') {
        _showPopup('Your request was rejected.');
        _cleanup();
      } else if (status == 'accepted') {
        setState(() {
          isDriverAccepted = true;
          driverName = data['driverName'];
          driverPhone = data['driverPhone'];
          ambulanceNumber = data['ambulanceNumber'];
          _driverLatLng = LatLng(
            data['driverLocation']['latitude'],
            data['driverLocation']['longitude'],
          );
        });

        _moveCameraTo(_driverLatLng!);
        _startDriverLocationUpdates(docId);
      }
    });
  }

  void _startDriverLocationUpdates(String docId) {
    _driverLocationTimer?.cancel();
    _driverLocationTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      final doc = await _firestore.collection('ambulance_requests').doc(docId).get();
      if (!doc.exists || doc['status'] != 'accepted') {
        timer.cancel();
        return;
      }

      final loc = doc['driverLocation'];
      if (mounted) {
        setState(() {
          _driverLatLng = LatLng(loc['latitude'], loc['longitude']);
        });

        _moveCameraTo(_driverLatLng!);
      }
    });
  }

  void _cancelRequest() async {
    if (_requestId != null) {
      await _firestore.collection('ambulance_requests').doc(_requestId).update({'status': 'cancelled'});
      _showPopup('Your request has been cancelled.');
      _cleanup();
    }
  }

  void _showPopup(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Info', style: TextStyle(color: Colors.white)),
        content: Text(msg, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _moveCameraTo(LatLng target) {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(target));
    }
  }

  void _cleanup() {
    _locationTimer?.cancel();
    _driverLocationTimer?.cancel();
    _requestSubscription?.cancel();

    setState(() {
      _requestId = null;
      isRequestActive = false;
      isDriverAccepted = false;
      _driverLatLng = null;
      driverName = null;
      driverPhone = null;
      ambulanceNumber = null;
    });

    _mapController = null;
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _driverLocationTimer?.cancel();
    _requestSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Ambulance', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => NewScreen()));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _userLatLng == null
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: CameraPosition(target: _userLatLng!, zoom: 15),
            markers: {
              Marker(
                markerId: MarkerId('user'),
                position: _userLatLng!,
                infoWindow: InfoWindow(title: 'You'),
              ),
              if (_driverLatLng != null)
                Marker(
                  markerId: MarkerId('driver'),
                  position: _driverLatLng!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  infoWindow: InfoWindow(title: 'Driver'),
                ),
            },
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          Positioned(
            bottom: 20,
            left: 40,
            right: 40,
            child: isRequestActive
                ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _cancelRequest,
              child: Text('Cancel Request', style: TextStyle(color: Colors.white)),
            )
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _sendAmbulanceRequest,
              child: Text('Request Ambulance', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// Dummy NewScreen class, replace it with your actual screen
class NewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Info', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: DriverDashboard(),
    );
  }
}
