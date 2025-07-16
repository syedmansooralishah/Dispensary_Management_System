import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AmbulanceLocationScreen extends StatefulWidget {
  @override
  _AmbulanceLocationScreenState createState() => _AmbulanceLocationScreenState();
}

class _AmbulanceLocationScreenState extends State<AmbulanceLocationScreen> {
  GoogleMapController? _mapController;
  LatLng? _ambulanceLocation;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchAmbulanceLocation();
  }

  Future<void> _fetchAmbulanceLocation() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('locations')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;

        if (lat != null && lng != null) {
          setState(() {
            _ambulanceLocation = LatLng(lat, lng);
          });
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_ambulanceLocation!, 15),
            );
          }
        } else {
          setState(() {
            _error = 'Invalid location data.';
          });
        }
      } else {
        setState(() {
          _error = 'No location data found.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching location: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ambulance Location')),
      body: _ambulanceLocation != null
          ? GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _ambulanceLocation!,
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: MarkerId('ambulance'),
            position: _ambulanceLocation!,
            infoWindow: InfoWindow(title: 'Ambulance'),
          ),
        },
        onMapCreated: (controller) {
          _mapController = controller;
        },
      )
          : Center(
        child: _error.isNotEmpty
            ? Text(_error, style: TextStyle(color: Colors.red))
            : CircularProgressIndicator(),
      ),
    );
  }
}
