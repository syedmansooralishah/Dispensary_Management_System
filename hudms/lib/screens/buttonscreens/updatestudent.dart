import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateStudentsScreen extends StatefulWidget {
  const UpdateStudentsScreen({Key? key}) : super(key: key);

  @override
  _UpdateStudentsScreenState createState() => _UpdateStudentsScreenState();
}

class _UpdateStudentsScreenState extends State<UpdateStudentsScreen> {
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

  void showUpdateDialog(DocumentSnapshot studentDoc) {
    final data = studentDoc.data() as Map<String, dynamic>? ?? {};

    final regNoController = TextEditingController(text: data['registration_number']?.toString() ?? '');
    final nameController = TextEditingController(text: data['name']?.toString() ?? '');
    final fatherNameController = TextEditingController(text: data['father_name']?.toString() ?? '');
    final departmentController = TextEditingController(text: data['department']?.toString() ?? '');
    final emailController = TextEditingController(text: data['email']?.toString() ?? '');
    final phoneController = TextEditingController(text: data['phone']?.toString() ?? '');
    final passwordController = TextEditingController(text: data['password']?.toString() ?? '');

    final _formKey = GlobalKey<FormState>();
    bool _obscurePassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setStateModal) => SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Update Student Info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: regNoController,
                    decoration: InputDecoration(labelText: 'Registration Number'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Registration Number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: fatherNameController,
                    decoration: InputDecoration(labelText: 'Father Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Father Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: departmentController,
                    decoration: InputDecoration(labelText: 'Department'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Department is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email (optional)'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Enter a valid email';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone Number is required';
                      }
                      if (value.trim().length < 7) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setStateModal(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text('Save Changes'),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final existing = await FirebaseFirestore.instance
                            .collection('students')
                            .where('registration_number',
                            isEqualTo: regNoController.text.trim())
                            .get();

                        bool isDuplicate = existing.docs.any((doc) => doc.id != studentDoc.id);

                        if (isDuplicate) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('⚠️ Registration Number already exists!')),
                          );
                          return;
                        }

                        await FirebaseFirestore.instance
                            .collection('students')
                            .doc(studentDoc.id)
                            .update({
                          'registration_number': regNoController.text.trim(),
                          'name': nameController.text.trim(),
                          'father_name': fatherNameController.text.trim(),
                          'department': departmentController.text.trim(),
                          'email': emailController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'password': passwordController.text.trim(),
                        });

                        Navigator.pop(context);
                        fetchStudents();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Students'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
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
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
              child: filteredStudents.isEmpty
                  ? Center(child: Text("No students found."))
                  : ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  final data = student.data() as Map<String, dynamic>? ?? {};
                  final name = data['name']?.toString() ?? 'N/A';
                  final regNo = data['registration_number']?.toString() ?? 'N/A';

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text(regNo),
                      trailing: ElevatedButton(
                        onPressed: () => showUpdateDialog(student),
                        child: Text('Update'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
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
