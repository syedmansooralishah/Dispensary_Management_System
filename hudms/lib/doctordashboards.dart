import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Added for fetching doctor data
import 'package:hudms/login.dart';
import 'package:hudms/screens/docterscreens/DocterAppionments.dart';
import 'package:hudms/screens/docterscreens/Doctorprescription/docterprescription.dart';
import 'package:hudms/screens/docterscreens/doctermedicalrecords.dart';
import 'package:hudms/screens/docterscreens/profilesetting.dart';
import 'package:hudms/screens/medicalrecords.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Required for Firebase
  runApp(DoctorDashboardApp());
}

class DoctorDashboardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor Dashboard',
      debugShowCheckedModeBanner: false,
      initialRoute: '/dashboard',
      routes: {
        '/': (context) => LoginScreen(),
        '/dashboard': (context) => DoctorDashboard(),
      },
    );
  }
}

class DoctorDashboard extends StatefulWidget {
  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  String doctorName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDoctorData();
  }

  Future<void> fetchDoctorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          doctorName = docSnapshot['name'] ?? 'Doctor';
          isLoading = false;
        });
      } else {
        setState(() {
          doctorName = 'Doctor';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_DashboardItem> tiles = [
      _DashboardItem(
        title: 'Appointments',
        image: 'assets/images/appiontments.png',
        screen: DDDoctorAppointmentsScreen(),
      ),
      _DashboardItem(
        title: 'Medical Records',
        image: 'assets/images/records.png',
        screen: MedicalRecordSearchScreen(),
      ),
      _DashboardItem(
        title: 'Prescriptions',
        image: 'assets/images/prescription.png',
        screen: PrescriptionForm(),
      ),
      _DashboardItem(
        title: "Logout",
        image: "assets/images/logout.png",
        onTap: (ctx) async {
          await FirebaseAuth.instance.signOut();
          Navigator.of(ctx).pushNamedAndRemoveUntil('/', (route) => false);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Doctor Dashboard'),
        backgroundColor: Colors.teal[600],
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProfileSettingsScreen()),
              );
            },
            child: _buildProfileTile(),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: tiles.map((tile) {
                return GestureDetector(
                  onTap: () {
                    if (tile.onTap != null) {
                      tile.onTap!(context);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => tile.screen!),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: tile.title == "Logout"
                          ? Colors.red[50]
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: tile.title == "Logout"
                          ? Border.all(color: Colors.red.shade200)
                          : null,
                      boxShadow: tile.title == "Logout"
                          ? []
                          : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(tile.image, height: 64),
                        SizedBox(height: 12),
                        Text(
                          tile.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: tile.title == "Logout"
                                ? Colors.red[800]
                                : Colors.teal[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/images/doctor_avatar.png'),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. $doctorName',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
                  ),
                ),
                Text(
                  'Profile Settings',
                  style: TextStyle(color: Colors.teal[700]),
                ),
              ],
            ),
          ),
          Icon(Icons.settings, color: Colors.teal[700]),
        ],
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final String image;
  final Widget? screen;
  final Future<void> Function(BuildContext)? onTap;

  _DashboardItem({
    required this.title,
    required this.image,
    this.screen,
    this.onTap,
  });
}
