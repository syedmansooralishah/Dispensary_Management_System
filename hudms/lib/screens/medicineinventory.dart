import 'package:flutter/material.dart';
import 'package:hudms/screens/medicinebuttons/AddMedicine.dart';
import 'package:hudms/screens/medicinebuttons/Issuedmedcine.dart';
import 'package:hudms/screens/medicinebuttons/checklist.dart';
import 'package:hudms/screens/medicinebuttons/deletemedicine.dart';


class MedicineInventoryScreen extends StatelessWidget {
  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Medicine Inventory")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModernButton(
                context,
                "Add Medicine",
                Colors.greenAccent,
                Colors.green,
                AddMedicineScreen()
            ),
            SizedBox(height: 16),
            _buildModernButton(
                context,
                "Check List",
                Colors.lightBlueAccent,
                Colors.blue,
                MedicineListScreen()
            ),
            SizedBox(height: 16),
            _buildModernButton(
                context,
                "Remove Medicine",
                Colors.redAccent,
                Colors.red,
                DeleteMedicineScreen()
            ),
            SizedBox(height: 16),
            _buildModernButton(
                context,
                "Issued Medicine",
                Colors.orangeAccent,
                Colors.deepOrange,
                IssueMedicineScreen()
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernButton(BuildContext context, String label, Color color1, Color color2, Widget screen) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color2.withOpacity(0.3),
            offset: Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _navigateToScreen(context, screen),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
