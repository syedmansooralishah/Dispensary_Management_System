import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMedicineScreen extends StatefulWidget {
  @override
  _AddMedicineScreenState createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _milligramsController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  DateTime? _expiryDate;
  String? _medicineType;

  bool _isLoading = false;

  final List<String> _medicineTypes = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Ointment',
    'Drops',
    'Others'
  ];

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  void _saveMedicine() async {
    if (_formKey.currentState!.validate()) {
      if (_expiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an expiry date')),
        );
        return;
      }
      if (_medicineType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select medicine type')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance.collection('medicines').add({
          'name': _nameController.text.trim(),
          'manufacturer': _manufacturerController.text.trim(),
          'quantity': int.parse(_quantityController.text.trim()),
          'milligrams': int.parse(_milligramsController.text.trim()),
          'price_per_unit': double.parse(_priceController.text.trim()),
          'expiry_date': Timestamp.fromDate(_expiryDate!),
          'medicine_type': _medicineType,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine saved successfully')),
        );

        // Clear all fields
        _nameController.clear();
        _manufacturerController.clear();
        _quantityController.clear();
        _milligramsController.clear();
        _priceController.clear();
        setState(() {
          _expiryDate = null;
          _medicineType = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ??
              (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Medicine"),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Medicine Details",
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: "Medicine Name",
                hintText: "Enter medicine name",
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _manufacturerController,
                label: "Manufacturer",
                hintText: "Enter manufacturer name",
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _quantityController,
                label: "Quantity",
                hintText: "Enter quantity",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter Quantity';
                  if (int.tryParse(value) == null || int.parse(value) < 1) {
                    return 'Enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _milligramsController,
                label: "Milligrams",
                hintText: "Enter milligrams",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter Milligrams';
                  if (int.tryParse(value) == null || int.parse(value) < 1) {
                    return 'Enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                label: "Price per Unit",
                hintText: "Enter price per unit (e.g., 25.5)",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter Price per Unit';
                  if (double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'Enter a valid positive price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Medicine Type dropdown
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Medicine Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _medicineType,
                    isExpanded: true,
                    hint: const Text('Select medicine type'),
                    items: _medicineTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _medicineType = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Expiry Date picker
              GestureDetector(
                onTap: _selectExpiryDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'Select expiry date',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (_expiryDate == null) {
                        return 'Please select expiry date';
                      }
                      return null;
                    },
                    controller: TextEditingController(
                      text: _expiryDate == null
                          ? ''
                          : "${_expiryDate!.day.toString().padLeft(2, '0')}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.year}",
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMedicine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Save Medicine',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
