import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteStudentsScreen extends StatefulWidget {
  const DeleteStudentsScreen({Key? key}) : super(key: key);

  @override
  _DeleteStudentsScreenState createState() => _DeleteStudentsScreenState();
}

class _DeleteStudentsScreenState extends State<DeleteStudentsScreen> {
  List<DocumentSnapshot> allStudents = [];
  List<DocumentSnapshot> filteredStudents = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final snapshot = await FirebaseFirestore.instance.collection('students').get();
    setState(() {
      allStudents = snapshot.docs;
      filteredStudents = allStudents;
      isLoading = false;
    });
  }

  void filterSearch(String query) {
    final results = allStudents.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final name = data['name']?.toString().toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredStudents = results;
    });
  }

  Future<void> deleteStudent(String docId) async {
    await FirebaseFirestore.instance.collection('students').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student record deleted')),
    );
    fetchStudents(); // Refresh list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Student Records')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: filterSearch,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            filteredStudents.isEmpty
                ? const Expanded(
              child: Center(child: Text("No students found.")),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  final data = student.data() as Map<String, dynamic>? ?? {};
                  final name = data['name']?.toString() ?? 'No Name';
                  final regNo = data['registration_number']?.toString() ?? 'No Registration Number';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text(regNo),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: const Text('Are you sure you want to delete this student?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(context),
                              ),
                              TextButton(
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                onPressed: () {
                                  deleteStudent(student.id);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
