import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineListScreen extends StatefulWidget {
  @override
  _MedicineListScreenState createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine List'),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 5,
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medicines')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No medicines found.'));
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final name = doc['name'].toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(child: Text('No match found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final medicine = filteredDocs[index];
                    return _buildMedicineCard(medicine);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search Medicines...',
          prefixIcon: Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade200,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(QueryDocumentSnapshot medicine) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        onTap: () {
          _showMedicineDetailsDialog(medicine);
        },
        title: Text(
          medicine['name'],
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          '${medicine['quantity']} pcs - ${medicine['milligrams']} mg',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurpleAccent,
          child: Icon(Icons.medical_services, color: Colors.white),
        ),
      ),
    );
  }

  void _showMedicineDetailsDialog(QueryDocumentSnapshot medicine) {
    showDialog(
      context: context,
      builder: (context) {
        final expiryDateTimestamp = medicine['expiry_date'] as Timestamp?;
        final expiryDate = expiryDateTimestamp != null
            ? expiryDateTimestamp.toDate()
            : null;

        return AlertDialog(
          title: Text(medicine['name']),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Manufacturer: ${medicine['manufacturer'] ?? 'N/A'}'),
                SizedBox(height: 8),
                Text('Quantity: ${medicine['quantity']} pcs'),
                SizedBox(height: 8),
                Text('Milligrams: ${medicine['milligrams']} mg'),
                SizedBox(height: 8),
                Text('Price per Unit: \$${medicine['price_per_unit'].toString()}'),
                SizedBox(height: 8),
                Text('Medicine Type: ${medicine['medicine_type'] ?? 'N/A'}'),
                SizedBox(height: 8),
                Text(
                  'Expiry Date: ${expiryDate != null ? "${expiryDate.day.toString().padLeft(2,'0')}-${expiryDate.month.toString().padLeft(2,'0')}-${expiryDate.year}" : 'N/A'}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.deepPurpleAccent)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
