import 'package:flutter/material.dart';
import 'package:hudms/screens/buttonscreens/deletestudent.dart';
import 'package:hudms/screens/buttonscreens/studentregistration.dart';
import 'package:hudms/screens/buttonscreens/updatestudent.dart';
import 'package:hudms/screens/buttonscreens/viewstudent.dart';

class StudentManagementScreen extends StatelessWidget {
  const StudentManagementScreen({Key? key}) : super(key: key);

  void navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget buildModernButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Widget screen,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => navigate(context, screen),
        icon: Icon(icon, size: 24),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Text(text, style: const TextStyle(fontSize: 16)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.black45,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Management')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildModernButton(
                context: context,
                text: 'Register Student',
                icon: Icons.person_add,
                screen: StudentRegistrationScreen(),
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              buildModernButton(
                context: context,
                text: 'View Students',
                icon: Icons.list_alt,
                screen: ViewStudentsScreen(),
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 20),
              buildModernButton(
                context: context,
                text: 'Update Registration',
                icon: Icons.update,
                screen: UpdateStudentsScreen(),
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              buildModernButton(
                context: context,
                text: 'Delete Registration',
                icon: Icons.delete,
                screen: DeleteStudentsScreen(),
                color: Colors.redAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
