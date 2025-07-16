import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecordsDeleteScreen extends StatefulWidget {
  @override
  _MedicalRecordsDeleteScreenState createState() => _MedicalRecordsDeleteScreenState();
}

class _MedicalRecordsDeleteScreenState extends State<MedicalRecordsDeleteScreen> {
  TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _allRecords = [];
  List<DocumentSnapshot> _filteredRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchRecords();
    _searchController.addListener(_searchRecords);
  }

  Future<void> _fetchRecords() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('medical_records')
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      _allRecords = snapshot.docs;
      _filteredRecords = _allRecords;
    });
  }

  void _searchRecords() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredRecords = _allRecords.where((doc) {
        String name = (doc['name'] ?? '').toLowerCase();
        String regNo = (doc['regNo'] ?? '').toLowerCase();
        return name.contains(query) || regNo.contains(query);
      }).toList();
    });
  }

  Future<void> _deleteRecord(String recordId) async {
    try {
      await FirebaseFirestore.instance
          .collection('medical_records')
          .doc(recordId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record deleted successfully!')),
      );

      setState(() {
        _filteredRecords.removeWhere((record) => record.id == recordId);
        _allRecords.removeWhere((record) => record.id == recordId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete Medical Records'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            SizedBox(height: 16),
            Expanded(child: _buildListView()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by name or reg no...',
        prefixIcon: Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (_filteredRecords.isEmpty) {
      return Center(child: Text('No records found.'));
    }

    return ListView.builder(
      itemCount: _filteredRecords.length,
      itemBuilder: (context, index) {
        var record = _filteredRecords[index];

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(
              record['name'] ?? 'No Name',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Reg No: ${record['regNo'] ?? 'N/A'}'),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteRecord(record.id),
            ),
          ),
        );
      },
    );
  }
}
