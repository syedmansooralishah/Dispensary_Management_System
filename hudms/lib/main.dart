import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hudms/doctordashboards.dart';
import 'package:hudms/driverdashboard.dart';
import 'package:hudms/UserDashboard.dart';
import 'package:hudms/login.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Widget> getInitialScreen() async {
    User? user = _auth.currentUser;
    if (user == null) return LoginScreen();

    final uid = user.uid;

    // Check driver
    final ambulanceDoc = await FirebaseFirestore.instance.collection('ambulances').doc(uid).get();
    if (ambulanceDoc.exists && ambulanceDoc.data()?['role'] == 'driver') {
      return  DriverDashboard();
    }

    // Check student
    final userDoc = await FirebaseFirestore.instance.collection('students').doc(uid).get();
    if (userDoc.exists && userDoc.data()?['role'] == 'student') {
      return const UserDashboardPage();
    }

    // Check doctor
    final doctorDoc = await FirebaseFirestore.instance.collection('doctors').doc(uid).get();
    if (doctorDoc.exists && doctorDoc.data()?['role'] == 'doctor') {
      return DoctorDashboardApp();
    }

    // No valid role, sign out
    await _auth.signOut();
    return LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dispensary Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: FutureBuilder<Widget>(
        future: getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          }
          return snapshot.data!;
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/driverDashboard': (context) => DriverDashboard(),
        '/userDashboard': (context) => const UserDashboardPage(),
        '/doctorDashboard': (context) =>  DoctorDashboardApp(),
      },
    );
  }
}
