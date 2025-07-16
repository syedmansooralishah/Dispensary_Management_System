import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';

class LocationUploader extends StatefulWidget {
  final String userId;

  const LocationUploader({required this.userId});

  @override
  State<LocationUploader> createState() => _LocationUploaderState();
}

class _LocationUploaderState extends State<LocationUploader> {
  Location location = Location();
  late bool _isListening;

  @override
  void initState() {
    super.initState();
    _isListening = true;
    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    location.changeSettings(interval: 3000); // 3 seconds

    location.onLocationChanged.listen((LocationData currentLocation) {
      print('Latitude: ${currentLocation.latitude}, Longitude: ${currentLocation.longitude}');

      if (!_isListening) return;
      FirebaseFirestore.instance.collection('locations').doc(widget.userId).set({
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }).then((_) {
        print('Location updated to Firestore');
      }).catchError((error) {
        print('Failed to update location: $error');
      });

    });
  }

  @override
  void dispose() {
    _isListening = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(); // Background service
  }
}
