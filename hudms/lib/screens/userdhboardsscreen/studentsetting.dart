import 'package:flutter/material.dart';

class StudentSettingsScreen extends StatelessWidget {
  const StudentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _settingsCard(
            icon: Icons.person,
            label: 'Profile Settings',
            onTap: () {
              debugPrint('Profile Settings tapped');
              // TODO: Navigate to profile settings screen
            },
          ),
          _settingsCard(
            icon: Icons.lock,
            label: 'Change Password',
            onTap: () {
              debugPrint('Change Password tapped');
              // TODO: Navigate to password change screen
            },
          ),
          _settingsCard(
            icon: Icons.notifications,
            label: 'Notification Preferences',
            onTap: () {
              debugPrint('Notification Preferences tapped');
              // TODO: Navigate to notification settings
            },
          ),
          _settingsCard(
            icon: Icons.language,
            label: 'Language',
            onTap: () {
              debugPrint('Language tapped');
              // TODO: Show language selection
            },
          ),
          _settingsCard(
            icon: Icons.logout,
            label: 'Logout',
            onTap: () {
              debugPrint('Logout tapped');
              // TODO: Handle logout
            },
          ),
        ],
      ),
    );
  }

  Widget _settingsCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(label, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
