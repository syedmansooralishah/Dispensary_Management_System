import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _saveDoctor() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Save current user (admin) credentials to restore after doctor account creation
        final adminUser = FirebaseAuth.instance.currentUser;
        final adminEmail = adminUser?.email;
        final adminToken = await adminUser?.getIdToken();

        // Create doctor account
        UserCredential doctorCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Add doctor details in Firestore
        await FirebaseFirestore.instance.collection('doctors').doc(doctorCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'license': _licenseController.text.trim(),
          'address': _addressController.text.trim(),
          'phone': _phoneController.text.trim(),
          'specialization': _specializationController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'doctor',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // ✅ Optionally, add to users collection too
        await FirebaseFirestore.instance.collection('users').doc(doctorCredential.user!.uid).set({
          'email': _emailController.text.trim(),
          'role': 'doctor',
        });

        // Re-login as admin (important!)
        if (adminEmail != null && adminToken != null) {
          await FirebaseAuth.instance.signOut();
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: adminEmail,
            password: '', // 🚫 You must handle admin re-auth securely!
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor account created successfully')),
        );

        Navigator.pop(context); // Return to previous screen
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Doctor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(controller: _nameController, label: 'Doctor Name', hint: 'Enter doctor\'s full name'),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _licenseController, label: 'License Number', hint: 'Enter license number'),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _addressController, label: 'Address', hint: 'Enter address'),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _phoneController, label: 'Phone Number', hint: 'Enter phone number', keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _specializationController, label: 'Specialization', hint: 'e.g., Cardiologist'),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _emailController, label: 'Email', hint: 'Enter email', keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _passwordController, label: 'Password', hint: 'Enter password', obscure: true),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _confirmPasswordController, label: 'Confirm Password', hint: 'Re-enter password', obscure: true),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveDoctor,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueAccent,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Doctor'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }
}
