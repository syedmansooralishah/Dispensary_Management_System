import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewStudentsScreen extends StatefulWidget {
  const ViewStudentsScreen({Key? key}) : super(key: key);

  @override
  _ViewStudentsScreenState createState() => _ViewStudentsScreenState();
}

class _ViewStudentsScreenState extends State<ViewStudentsScreen> {
  List<DocumentSnapshot> allStudents = [];
  List<DocumentSnapshot> filteredStudents = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('students').get();

    final docs = snapshot.docs;

    setState(() {
      allStudents = docs;
      filteredStudents = docs;
      isLoading = false;
    });
  }

  void filterSearch(String query) {
    final List<DocumentSnapshot> results = allStudents.where((doc) {
      final name = (doc.data() as Map<String, dynamic>)['name']?.toString().toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredStudents = results;
    });
  }

  void showStudentDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(data['name'] ?? 'Student Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetail("Father Name", data['father_name']),
                _buildDetail("Registration Number", data['registration_number']),
                _buildDetail("Department", data['department']),
                _buildDetail("Program", data['program']),
                _buildDetail("Email", data['email']),
                _buildDetail("Password", data['password']),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        "$label: ${value ?? 'N/A'}",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Registered Students'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: filterSearch,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
              child: filteredStudents.isEmpty
                  ? const Center(child: Text("No students found."))
                  : ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  final data = student.data() as Map<String, dynamic>;

                  final name = data['name'] ?? 'No Name';
                  final regNo = data['registration_number'] ?? 'N/A';

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text('Reg No: $regNo'),
                      onTap: () => showStudentDetails(data),
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
