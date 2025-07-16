import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecordSearchScreen extends StatefulWidget {
  const MedicalRecordSearchScreen({super.key});

  @override
  _MedicalRecordSearchScreenState createState() => _MedicalRecordSearchScreenState();
}

class _MedicalRecordSearchScreenState extends State<MedicalRecordSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  DocumentSnapshot? searchedRecord;
  bool isSearching = false;

  Future<void> fetchRecord(String registrationNumber) async {
    setState(() {
      isSearching = true;
      searchedRecord = null;
    });

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('medical_records')
          .doc(registrationNumber)
          .get();

      if (doc.exists) {
        setState(() {
          searchedRecord = doc;
        });
      } else {
        setState(() {
          searchedRecord = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No record found for $registrationNumber')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    } finally {
      setState(() {
        isSearching = false;
      });
    }
  }

  void showRecordPopup(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Medical Record'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.entries
                .map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${e.key}: ${e.value}'),
            ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Medical Records'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Enter Registration Number",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    final regNum = _searchController.text.trim();
                    if (regNum.isNotEmpty) fetchRecord(regNum);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isSearching) const CircularProgressIndicator(),

            // Searched record shown at the top
            if (searchedRecord != null)
              Card(
                color: Colors.teal.shade50,
                child: ListTile(
                  title: Text("Registration #: ${searchedRecord!.id}"),
                  subtitle: const Text("Tap to view details"),
                  onTap: () => showRecordPopup(searchedRecord!.data() as Map<String, dynamic>),
                  trailing: const Icon(Icons.info_outline),
                ),
              ),

            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("All Medical Records:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('medical_records').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return Card(
                        child: ListTile(
                          title: Text("Registration #: ${doc.id}"),
                          onTap: () => showRecordPopup(doc.data() as Map<String, dynamic>),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
