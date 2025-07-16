import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionForm extends StatefulWidget {
  @override
  _PrescriptionFormState createState() => _PrescriptionFormState();
}

class _PrescriptionFormState extends State<PrescriptionForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _conditionController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _medicationController = TextEditingController();
  final _dietController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  void _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final regNo = _regNoController.text.trim();

        await FirebaseFirestore.instance
            .collection('medical_records')
            .doc(regNo) // Save as document ID
            .set({
          'name': _nameController.text.trim(),
          'regNo': regNo,
          'age': _ageController.text.trim(),
          'weight': _weightController.text.trim(),
          'bloodGroup': _bloodGroupController.text.trim(),
          'condition': _conditionController.text.trim(),
          'diagnosis': _diagnosisController.text.trim(),
          'medication': _medicationController.text.trim(),
          'diet': _dietController.text.trim(),
          'notes': _notesController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Record saved successfully')),
        );

        _formKey.currentState!.reset();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (val) => val == null || val.isEmpty ? 'Enter $label' : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(
        title: Text("Add Medical Record"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSectionTitle("Personal Information"),
                      _buildField("Name", _nameController),
                      _buildField("Registration No", _regNoController),
                      Row(
                        children: [
                          Expanded(child: _buildField("Age", _ageController)),
                          SizedBox(width: 10),
                          Expanded(child: _buildField("Weight", _weightController)),
                        ],
                      ),
                      _buildField("Blood Group", _bloodGroupController),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSectionTitle("Medical Details"),
                      _buildField("Medical Condition", _conditionController, maxLines: 2),
                      _buildField("Diagnosis", _diagnosisController, maxLines: 2),
                      _buildField("Medication", _medicationController, maxLines: 2),
                      _buildField("Diet", _dietController, maxLines: 2),
                      _buildField("Other/Notes", _notesController, maxLines: 3),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Save Record", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
