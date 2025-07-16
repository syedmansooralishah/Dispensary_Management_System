import 'package:flutter/material.dart';
import 'package:hudms/screens/ambulancebutton/Addambulance.dart';
import 'package:hudms/screens/ambulancebutton/ambulancedelete.dart';
import 'package:hudms/screens/ambulancebutton/trackambulance.dart';

class AmbulanceManagementScreen extends StatelessWidget {
  const AmbulanceManagementScreen({Key? key}) : super(key: key);

  // Show loading indicator and navigate after delay
  void navigate(BuildContext context, Widget screen) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    });
  }

  // Gradient Button
  Widget buildModernButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Widget screen,
    required Color color1,
    required Color color2,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color1, color2]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => navigate(context, screen),
          icon: Icon(icon, size: 24),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Text(text, style: const TextStyle(fontSize: 16)),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ambulance Management')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildModernButton(
              context: context,
              text: 'Add Ambulance',
              icon: Icons.add_box,
              screen: AmbulanceRegistrationScreen(),
              color1: Colors.lightGreenAccent,
              color2: Colors.green,
            ),
            buildModernButton(
              context: context,
              text: 'Track Ambulance',
              icon: Icons.local_taxi,
              screen: AmbulanceLocationScreen(),
              color1: Colors.lightBlue,
              color2: Colors.blue,
            ),
            buildModernButton(
              context: context,
              text: 'Delete Ambulance',
              icon: Icons.delete,
              screen: DeleteAmbulanceScreen(),
              color1: Colors.orangeAccent,
              color2: Colors.red,
            ),

          ],
        ),
      ),
    );
  }
}
