import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IssueMedicineScreen extends StatefulWidget {
  @override
  _IssueMedicineScreenState createState() => _IssueMedicineScreenState();
}

class _IssueMedicineScreenState extends State<IssueMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _studentRollNoController = TextEditingController();
  DateTime? _selectedIssueDate;
  bool _isLoading = false;

  // List to hold multiple medicine entries
  List<MedicineEntry> medicineEntries = [MedicineEntry()];

  final List<String> _medicineTypes = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Ointment',
    'Drops',
    'Others',
  ];

  Future<void> _selectIssueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedIssueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedIssueDate = picked;
      });
    }
  }

  void _addMedicineEntry() {
    setState(() {
      medicineEntries.add(MedicineEntry());
    });
  }

  void _removeMedicineEntry(int index) {
    setState(() {
      if (medicineEntries.length > 1) {
        medicineEntries.removeAt(index);
      }
    });
  }

  Future<void> _issueMedicines() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedIssueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an issue date')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Create a list of medicine details
        List<Map<String, dynamic>> medicinesToIssue = medicineEntries.map((entry) {
          return {
            'medicineName': entry.selectedMedicineName,
            'medicineType': entry.selectedMedicineType,
            'amountIssued': int.parse(entry.amountController.text.trim()),
          };
        }).toList();

        await FirebaseFirestore.instance.collection('issued_medicines').add({
          'studentRollNo': _studentRollNoController.text.trim(),
          'medicines': medicinesToIssue,
          'issueDate': Timestamp.fromDate(_selectedIssueDate!),
          'issuedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Medicines issued successfully!')),
        );

        // Clear form
        setState(() {
          medicineEntries = [MedicineEntry()];
          _selectedIssueDate = null;
        });
        _studentRollNoController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error issuing medicines: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMedicineNameDropdown(MedicineEntry entry) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('medicines').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: 'Medicine Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text(
            'No medicines available',
            style: TextStyle(color: Colors.red),
          );
        }

        final medicineDocs = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          value: entry.selectedMedicineName,
          onChanged: (value) {
            setState(() {
              entry.selectedMedicineName = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a medicine';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Medicine Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          items: medicineDocs.map<DropdownMenuItem<String>>((doc) {
            final name = doc['name'] as String? ?? '';
            return DropdownMenuItem<String>(
              value: name,
              child: Text(name),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMedicineTypeDropdown(MedicineEntry entry) {
    return DropdownButtonFormField<String>(
      value: entry.selectedMedicineType,
      onChanged: (value) {
        setState(() {
          entry.selectedMedicineType = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select medicine type';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Medicine Type',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      items: _medicineTypes
          .map((type) => DropdownMenuItem<String>(
        value: type,
        child: Text(type),
      ))
          .toList(),
    );
  }

  Widget _buildAmountField(MedicineEntry entry) {
    return TextFormField(
      controller: entry.amountController,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter amount issued';
        if (int.tryParse(value) == null || int.parse(value) < 1) {
          return 'Enter a valid positive number';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Amount Issued',
        hintText: 'Enter amount issued',
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildMedicineEntryCard(int index) {
    final entry = medicineEntries[index];
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Medicine ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 10),
            _buildMedicineNameDropdown(entry),
            SizedBox(height: 15),
            _buildMedicineTypeDropdown(entry),
            SizedBox(height: 15),
            _buildAmountField(entry),
            SizedBox(height: 10),
            if (medicineEntries.length > 1)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _removeMedicineEntry(index),
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text('Remove', style: TextStyle(color: Colors.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueDatePicker() {
    return GestureDetector(
      onTap: _selectIssueDate,
      child: AbsorbPointer(
        child: TextFormField(
          controller: TextEditingController(
              text: _selectedIssueDate == null
                  ? ''
                  : "${_selectedIssueDate!.day.toString().padLeft(2, '0')}-${_selectedIssueDate!.month.toString().padLeft(2, '0')}-${_selectedIssueDate!.year}"),
          validator: (value) {
            if (_selectedIssueDate == null) {
              return 'Please select issue date';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Issue Date',
            hintText: 'Select issue date',
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: Icon(Icons.calendar_today),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _issueMedicines,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
          'Issue Medicines',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _studentRollNoController.dispose();
    medicineEntries.forEach((entry) => entry.amountController.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Issue Medicines'),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                controller: _studentRollNoController,
                label: 'Student Roll No',
                hintText: 'Enter student roll number',
              ),
              SizedBox(height: 20),
              ...List.generate(medicineEntries.length, (index) => _buildMedicineEntryCard(index)),
              TextButton.icon(
                onPressed: _addMedicineEntry,
                icon: Icon(Icons.add),
                label: Text('Add Medicine'),
              ),
              SizedBox(height: 20),
              _buildIssueDatePicker(),
              SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
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
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class MedicineEntry {
  String? selectedMedicineName;
  String? selectedMedicineType;
  TextEditingController amountController = TextEditingController();
}
