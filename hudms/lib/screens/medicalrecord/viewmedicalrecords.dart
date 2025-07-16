import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewMedicalRecordsScreen extends StatefulWidget {
  @override
  _ViewMedicalRecordsScreenState createState() => _ViewMedicalRecordsScreenState();
}

class _ViewMedicalRecordsScreenState extends State<ViewMedicalRecordsScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("View Medical Records"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or reg no',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medical_records')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No medical records found."));
                }

                final records = snapshot.data!.docs.where((doc) {
                  final name = doc['name']?.toLowerCase() ?? '';
                  final regNo = doc['regNo']?.toLowerCase() ?? '';
                  return name.contains(searchQuery) || regNo.contains(searchQuery);
                }).toList();

                if (records.isEmpty) {
                  return Center(child: Text("No results match your search."));
                }

                return ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (_, __) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final name = record['name'] ?? 'Unknown';
                    final regNo = record['regNo'] ?? 'N/A';

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(Icons.person_outline, color: Colors.teal),
                        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Reg No: $regNo"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showRecordDialog(context, record),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _showRecordDialog(BuildContext context, QueryDocumentSnapshot record) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Medical Record Detail", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetail("Name", record['name']),
                _buildDetail("Reg No", record['regNo']),
                _buildDetail("Age", record['age']),
                _buildDetail("Weight", record['weight']),
                _buildDetail("Blood Group", record['bloodGroup']),
                _buildDetail("Condition", record['condition']),
                _buildDetail("Diagnosis", record['diagnosis']),
                _buildDetail("Medication", record['medication']),
                _buildDetail("Diet", record['diet']),
                _buildDetail("Other/Notes", record['notes']),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Close", style: TextStyle(color: Colors.teal)),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        );
      },
    );
  }

  Widget _buildDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.black87, fontSize: 15),
          children: [
            TextSpan(text: "$label: ", style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
