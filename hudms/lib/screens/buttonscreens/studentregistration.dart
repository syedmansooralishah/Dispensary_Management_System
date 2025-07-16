import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentRegistrationScreen extends StatefulWidget {
  @override
  _StudentRegistrationScreenState createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _departmentController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedProgram;
  final List<String> _programOptions = ['Bachelor', 'Master', 'PhD'];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text("Student Registration"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildInputField(_nameController, "Student Name"),
                      SizedBox(height: 16),
                      _buildInputField(_fatherNameController, "Father Name"),
                      SizedBox(height: 16),
                      _buildRegNoField(),
                      SizedBox(height: 16),
                      _buildInputField(_departmentController, "Department"),
                      SizedBox(height: 16),
                      _buildInputField(_emailController, "Email", inputType: TextInputType.emailAddress),
                      SizedBox(height: 16),
                      _buildInputField(
                        _passwordController,
                        "Password",
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildInputField(
                        _confirmPasswordController,
                        "Confirm Password",
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildInputField(_phoneController, "Phone Number", inputType: TextInputType.phone),
                      SizedBox(height: 16),
                      _buildDropdownField(),
                      SizedBox(height: 30),
                      _buildSubmitButton(),
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

  Widget _buildInputField(
      TextEditingController controller,
      String label, {
        TextInputType inputType = TextInputType.text,
        bool obscureText = false,
        Widget? suffixIcon,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.teal),
        filled: true,
        fillColor: Colors.blueGrey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: suffixIcon,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (label == "Confirm Password" && value != _passwordController.text) {
          return "Passwords do not match";
        }
        return null;
      },
    );
  }

  Widget _buildRegNoField() {
    return TextFormField(
      controller: _regNoController,
      decoration: InputDecoration(
        labelText: "Registration Number",
        labelStyle: TextStyle(color: Colors.teal),
        filled: true,
        fillColor: Colors.blueGrey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter Registration Number';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Graduate Program",
        labelStyle: TextStyle(color: Colors.teal),
        filled: true,
        fillColor: Colors.blueGrey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      value: _selectedProgram,
      items: _programOptions.map((program) {
        return DropdownMenuItem(
          value: program,
          child: Text(program),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedProgram = value),
      validator: (value) => value == null ? 'Please select a graduate program' : null,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          final regNo = _regNoController.text.trim();

          try {
            final existing = await FirebaseFirestore.instance.collection('students').doc(regNo).get();
            if (existing.exists) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("⚠️ Registration Number already exists.")),
              );
              return;
            }

            final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

            final uid = credential.user!.uid;

            await FirebaseFirestore.instance.collection('students').doc(regNo).set({
              'uid': uid,
              'name': _nameController.text.trim(),
              'father_name': _fatherNameController.text.trim(),
              'registration_number': regNo,
              'department': _departmentController.text.trim(),
              'email': _emailController.text.trim(),
              'phone': _phoneController.text.trim(),
              'program': _selectedProgram,
              'role': 'student',
              'created_at': FieldValue.serverTimestamp(),
            });

            await FirebaseFirestore.instance.collection('students').doc(uid).set({
              'uid': uid,
              'email': _emailController.text.trim(),
              'role': 'student',
              'created_at': FieldValue.serverTimestamp(),
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Student Registered Successfully")),
            );

            _formKey.currentState!.reset();
            _nameController.clear();
            _fatherNameController.clear();
            _regNoController.clear();
            _departmentController.clear();
            _emailController.clear();
            _phoneController.clear();
            _passwordController.clear();
            _confirmPasswordController.clear();
            setState(() => _selectedProgram = null);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Registration Failed: $e")),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text("Register Student", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
