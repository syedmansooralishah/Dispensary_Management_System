import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hudms/screens/buttonscreens/studentprofilrsetting.dart';
import 'package:hudms/screens/userdhboardsscreen/appiontmentbuttonsscreen/bookAppiontment.dart';
import 'package:hudms/screens/userdhboardsscreen/studentmedicalrecords.dart';
import 'package:hudms/screens/userdhboardsscreen/studentsetting.dart';
import 'package:hudms/screens/userdhboardsscreen/requestambulance.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  String userName = '';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  /// ✅ Fetch user data using currently logged-in user's UID
  Future<void> fetchUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final String uid = currentUser.uid;

      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('uid', isEqualTo: uid)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          setState(() {
            userName = data['name'] ?? 'Student';
            userEmail = data['email'] ?? 'No Email';
          });
        } else {
          setState(() {
            userName = 'Student';
            userEmail = 'No Email';
          });
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Portal'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ✅ Profile Card
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentProfileSettingsScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage('assets/images/student.png'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${userName.isNotEmpty ? userName : 'Student'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail.isNotEmpty ? userEmail : 'Fetching email...',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),

          // ✅ Dashboard Tiles
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(20),
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                _dashboardTile(
                  context,
                  title: 'AMBULANCE',
                  imagePath: 'assets/images/ambulance-png.png',
                  destinationScreen:RequestAmbulanceScreen(),
                ),
                _dashboardTile(
                  context,
                  title: 'Book Appointment',
                  imagePath: 'assets/images/male-doctor.png',
                  destinationScreen:StudentBookAppointmentScreen(),
                ),
                _dashboardTile(
                  context,
                  title: 'Medical Records',
                  imagePath: 'assets/images/medical_reports.png',
                  destinationScreen: const StudentMedicalRecordsScreen(),
                ),
                _dashboardTile(
                  context,
                  title: 'Settings',
                  imagePath: 'assets/images/setting.png',
                  destinationScreen: const StudentSettingsScreen(),
                ),

                // ✅ Logout tile
                GestureDetector(
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out successfully')),
                    );
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (route) => false);
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/logout.png',
                            height: 50,
                            width: 50,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Logout',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Reusable dashboard tile widget
  Widget _dashboardTile(BuildContext context,
      {required String title,
        required String imagePath,
        required Widget destinationScreen}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destinationScreen),
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(imagePath, height: 50, width: 50),
              const SizedBox(height: 10),
              Text(
                title,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
