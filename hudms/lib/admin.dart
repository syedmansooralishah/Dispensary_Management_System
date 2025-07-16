import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hudms/adminprofile.dart';
import 'package:hudms/screens/Doctermanagement.dart';
import 'package:hudms/screens/medicalrecord/addmedicalrecords.dart';
import 'package:hudms/screens/studentmanagement.dart';
import 'package:hudms/screens/ambulancescreen.dart';
import 'package:hudms/screens/medicineinventory.dart';
import 'package:hudms/screens/medicalrecords.dart';

import 'components/LocationUploader.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<_DashboardItem> items = [
      _DashboardItem(
        title: "Ambulance Management",
        image: "assets/images/ambulance-png.png",
        screen: AmbulanceManagementScreen(),
      ),
      _DashboardItem(
        title: "Medicine Inventory",
        image: "assets/images/inventory.png",
        screen: MedicineInventoryScreen(),
      ),
      _DashboardItem(
        title: "Student Management",
        image: "assets/images/registration.png",
        screen: StudentManagementScreen(),
      ),
      _DashboardItem(
        title: "Medical Records",
        image: "assets/images/records.png",
        screen: AddMedicalRecordScreen(),
      ),
      _DashboardItem(
        title: "Doctors Management",
        image: "assets/images/male-doctor.png",
        screen: DoctorManagementScreen(),
      ),
      _DashboardItem(
        title: "Logout",
        image: "assets/images/logout.png",
        onTap: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); // Back to login
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Dispensary Admin Dashboard")),
      body: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileSettingsScreen()),
              );
            },
            child: _buildProfileTile(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: items.map((item) {
                  return GestureDetector(
                    onTap: () async {
                      if (item.onTap != null) {
                        await item.onTap!();
                      } else if (item.screen != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => item.screen!),
                        );
                      }
                    },
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(item.image, height: 80),
                          SizedBox(height: 10),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.teal[100],
            child: Icon(
              Icons.person,
              size: 30,
              color: Colors.teal[800],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
                  ),
                ),
                Text(
                  'limeliner8@gmail.com',
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
  final Future<void> Function()? onTap;

  _DashboardItem({
    required this.title,
    required this.image,
    this.screen,
    this.onTap,
  });
}
