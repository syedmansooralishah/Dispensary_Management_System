import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DDDoctorAppointmentsScreen extends StatefulWidget {
  const DDDoctorAppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<DDDoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DDDoctorAppointmentsScreen> {
  String? doctorUid;

  @override
  void initState() {
    super.initState();
    fetchDoctorUid();
  }

  void fetchDoctorUid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        doctorUid = user.uid;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchDoctorAppointments() async {
    final snapshot = await FirebaseFirestore.instance.collection('appointments').get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .where((data) => data['doctorId'] == doctorUid)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor's Appointments"),
        backgroundColor: Colors.teal[600],
      ),
      body: doctorUid == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchDoctorAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong."));
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return const Center(child: Text("No appointments found for this doctor."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final data = appointments[index];
              final studentName = data['studentName'] ?? 'Unknown';
              final timeSlot = data['timeSlot'] ?? 'No time';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text("Student: $studentName", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Time Slot: $timeSlot"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
