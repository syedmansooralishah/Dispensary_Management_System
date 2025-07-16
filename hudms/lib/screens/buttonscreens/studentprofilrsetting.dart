import 'package:flutter/material.dart';

class StudentProfileSettingsScreen extends StatelessWidget {
  const StudentProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Settings"),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          _buildSettingItem(
            icon: Icons.email,
            title: "Update Email",
            onTap: () {
              // Navigate or show update email logic
            },
          ),

          _buildSettingItem(
            icon: Icons.lock_outline,
            title: "Change Password",
            onTap: () {
              // Navigate or show password change dialog
            },
          ),

          _buildSettingItem(
            icon: Icons.notifications_active_outlined,
            title: "Notification Preferences",
            onTap: () {
              // Notification settings logic
            },
          ),

          _buildSettingItem(
            icon: Icons.language,
            title: "Change Language",
            onTap: () {
              // Language settings logic
            },
          ),

          _buildSettingItem(
            icon: Icons.help_outline,
            title: "Help & Support",
            onTap: () {
              // Open help or support page
            },
          ),

          _buildSettingItem(
            icon: Icons.info_outline,
            title: "About App",
            onTap: () {
              // Show app version or details
            },
          ),

          const Divider(height: 32),

          _buildSettingItem(
            icon: Icons.logout,
            title: "Logout",
            onTap: () {
              // Handle logout
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logged out")),
              );
              Future.delayed(const Duration(milliseconds: 300), () {
                Navigator.pushReplacementNamed(context, '/');
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
