import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AmbulanceRegistrationScreen extends StatefulWidget {
  const AmbulanceRegistrationScreen({Key? key}) : super(key: key);

  @override
  _AmbulanceRegistrationScreenState createState() => _AmbulanceRegistrationScreenState();
}

class _AmbulanceRegistrationScreenState extends State<AmbulanceRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _engineNoController = TextEditingController();
  final TextEditingController _chassisNoController = TextEditingController();
  final TextEditingController _registrationNoController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _driverPhoneController = TextEditingController();
  final TextEditingController _driverEmailController = TextEditingController();
  final TextEditingController _driverPasswordController = TextEditingController();

  String? _ambulanceType;
  String? _availability;
  final List<String> _ambulanceTypes = ['Basic', 'ICU', 'Neonatal', 'Other'];
  final List<String> _availabilityOptions = ['Available', 'Unavailable'];

  bool _isSubmitting = false;
  bool _obscurePassword = true;

  String? _validateText(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return 'Please enter $fieldName';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter phone number';
    if (!RegExp(r'^\d{10,15}$').hasMatch(value)) return 'Enter valid phone number';
    return null;
  }

  String? _validateRegistration(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter registration number';
    if (!RegExp(r'^[A-Z]{3}-\d{4}$').hasMatch(value)) {
      return 'Format: AAA-1234';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}').hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> registerAmbulance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _driverEmailController.text.trim(),
        password: _driverPasswordController.text.trim(),
      );

      String driverUID = userCredential.user!.uid;

      final data = {
        'uid': driverUID,
        'model': _modelController.text.trim(),
        'engineNo': _engineNoController.text.trim(),
        'chassisNo': _chassisNoController.text.trim(),
        'registrationNo': _registrationNoController.text.trim(),
        'hospital': _hospitalController.text.trim(),
        'driverName': _driverNameController.text.trim(),
        'driverPhone': _driverPhoneController.text.trim(),
        'driverEmail': _driverEmailController.text.trim(),
        'ambulanceType': _ambulanceType,
        'availability': _availability,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'driver',
      };

      await FirebaseFirestore.instance.collection('ambulances').doc(driverUID).set(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Ambulance & Driver Registered')),
      );

      _formKey.currentState!.reset();
      setState(() {
        _ambulanceType = null;
        _availability = null;
        _isSubmitting = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Auth Error: ${e.message}')),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Widget _buildInputField(
      String label,
      TextEditingController controller,
      String? Function(String?) validator, {
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
        filled: true,
        fillColor: Colors.blueGrey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.blueGrey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value == null ? 'Please select $label' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text("Ambulance Registration"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInputField("Ambulance Model", _modelController, (val) => _validateText(val, "Ambulance Model")),
              SizedBox(height: 16),
              _buildInputField("Engine Number", _engineNoController, (val) => _validateText(val, "Engine Number")),
              SizedBox(height: 16),
              _buildInputField("Chassis Number", _chassisNoController, (val) => _validateText(val, "Chassis Number")),
              SizedBox(height: 16),
              _buildInputField("Registration Number", _registrationNoController, _validateRegistration),
              SizedBox(height: 16),
              _buildInputField("Hospital/Organization", _hospitalController, (val) => _validateText(val, "Hospital")),
              SizedBox(height: 16),
              _buildInputField("Driver Name", _driverNameController, (val) => _validateText(val, "Driver Name")),
              SizedBox(height: 16),
              _buildInputField("Driver Phone Number", _driverPhoneController, _validatePhone, inputType: TextInputType.phone),
              SizedBox(height: 16),
              _buildInputField("Driver Email", _driverEmailController, _validateEmail, inputType: TextInputType.emailAddress),
              SizedBox(height: 16),
              _buildInputField(
                "Driver Password",
                _driverPasswordController,
                _validatePassword,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              SizedBox(height: 16),
              _buildDropdown("Ambulance Type", _ambulanceType, _ambulanceTypes, (val) => setState(() => _ambulanceType = val)),
              SizedBox(height: 16),
              _buildDropdown("Availability", _availability, _availabilityOptions, (val) => setState(() => _availability = val)),
              SizedBox(height: 30),
              _isSubmitting
                  ? CircularProgressIndicator()
                  : ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text("Register Ambulance"),
                onPressed: registerAmbulance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
