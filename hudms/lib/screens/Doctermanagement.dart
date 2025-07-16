import 'package:flutter/material.dart';
import 'package:hudms/screens/doctorbutton/adddoctor.dart';
import 'package:hudms/screens/doctorbutton/removedocter.dart';
import 'package:hudms/screens/doctorbutton/staffchecklist.dart';

class DoctorManagementScreen extends StatelessWidget {
  const DoctorManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Management'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton(
              context: context,
              label: '➕ Add Doctor',
              color: Colors.green,
              screen: const  AddDoctorScreen(),
            ),
            const SizedBox(height: 16),
            _buildButton(
              context: context,
              label: '🗑️ Remove Doctor',
              color: Colors.red,
              screen: const DoctorListScreen(),
            ),

            const SizedBox(height: 16),
            _buildButton(
              context: context,
              label: '📋 Check Doctor List',
              color: Colors.purple,
              screen: const DoctorGridScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required Color color,
    required Widget screen,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
