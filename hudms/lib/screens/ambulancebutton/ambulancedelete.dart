import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteAmbulanceScreen extends StatefulWidget {
  @override
  _DeleteAmbulanceScreenState createState() => _DeleteAmbulanceScreenState();
}

class _DeleteAmbulanceScreenState extends State<DeleteAmbulanceScreen> {
  final CollectionReference ambulanceRef =
  FirebaseFirestore.instance.collection('ambulances');
  String searchQuery = '';
  Future<QuerySnapshot>? _ambulanceFuture;

  @override
  void initState() {
    super.initState();
    _loadAmbulances();
  }

  void _loadAmbulances() {
    _ambulanceFuture = ambulanceRef.get();
  }

  Future<void> deleteAmbulance(String id) async {
    await ambulanceRef.doc(id).delete();
  }

  bool _shouldExcludeField(String key) {
    final lowerKey = key.toLowerCase();
    return lowerKey == 'role' ||
        lowerKey == 'uid' ||
        lowerKey == 'createdat' ||
        lowerKey.contains('nanoseconds') ||
        lowerKey.contains('seconds');
  }

  String _getAmbulanceTitle(Map<String, dynamic> data) {
    final driverName = data['driverName'] ?? '';
    if (driverName.isNotEmpty) {
      final firstName = driverName.split(' ').first;
      return "$firstName's Ambulance";
    }
    return "Unnamed Ambulance";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text('Delete Ambulances'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by driver name or plate...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: _ambulanceFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No ambulances found.'));
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final driverName =
                      data['driver_name']?.toString().toLowerCase() ?? '';
                  final plate = data['plate']?.toString().toLowerCase() ?? '';
                  return driverName.contains(searchQuery) ||
                      plate.contains(searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(child: Text('No ambulances match your search.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 6,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + delete button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getAmbulanceTitle(data),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text("Confirm Delete"),
                                        content: Text(
                                            "Are you sure you want to delete this ambulance?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text("Delete",
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await deleteAmbulance(doc.id);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text("🚑 Ambulance deleted")),
                                      );
                                      setState(() {
                                        _loadAmbulances();
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            Divider(color: Colors.grey[400]),
                            // Show all filtered fields
                            ...data.entries
                                .where((entry) => !_shouldExcludeField(entry.key))
                                .map((entry) {
                              return Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  "${entry.key}: ${entry.value}",
                                  style: TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
