import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentMedicalRecordsScreen extends StatefulWidget {
  const StudentMedicalRecordsScreen({super.key});

  @override
  State<StudentMedicalRecordsScreen> createState() =>
      _StudentMedicalRecordsScreenState();
}

class _StudentMedicalRecordsScreenState
    extends State<StudentMedicalRecordsScreen> {
  bool _loading = true;
  DocumentSnapshot? _record;

  @override
  void initState() {
    super.initState();
    _fetchMedicalRecord();
  }

  Future<void> _fetchMedicalRecord() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 🔹 Step 1: Find student document by email to get registration number
      final querySnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: user.email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student record not found.')),
        );
        setState(() => _loading = false);
        return;
      }

      final studentDoc = querySnapshot.docs.first;
      final regNo = studentDoc.id; // Document ID is registration number

      // 🔹 Step 2: Fetch medical record using same registration number
      final recordDoc = await FirebaseFirestore.instance
          .collection('medical_records')
          .doc(regNo)
          .get();

      if (recordDoc.exists) {
        setState(() => _record = recordDoc);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No medical record found.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Medical Record')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _record == null
          ? const Center(child: Text('No medical record found.'))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GestureDetector(
              onTap: () => _showDetailsPopup(_record!),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Name: ${_record!['name'] ?? 'N/A'}",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                          "Registration No: ${_record!['regNo'] ?? 'N/A'}"),
                      Text("Age: ${_record!['age'] ?? 'N/A'}"),
                      Text(
                          "Condition: ${_record!['condition'] ?? 'N/A'}"),
                      const SizedBox(height: 8),
                      const Text("Tap to view full details",
                          style: TextStyle(color: Colors.teal)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsPopup(DocumentSnapshot record) {
    final data = record.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Medical Record Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow("Name", data['name']),
                _infoRow("Reg No", data['regNo']),
                _infoRow("Age", data['age']),
                _infoRow("Weight", data['weight']),
                _infoRow("Blood Group", data['bloodGroup']),
                _infoRow("Condition", data['condition']),
                _infoRow("Diagnosis", data['diagnosis']),
                _infoRow("Medication", data['medication']),
                _infoRow("Diet", data['diet']),
                _infoRow("Notes", data['notes']),
                _infoRow("Created At", _formatDate(data['createdAt'])),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        );
      },
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value?.toString() ?? "N/A"),
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }
}
