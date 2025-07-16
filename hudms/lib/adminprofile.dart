import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String? imageUrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchProfileImage();
  }

  Future<void> fetchProfileImage() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    setState(() {
      imageUrl = doc['imageUrl'];
    });
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;

    setState(() => isLoading = true);

    try {
      if (imageUrl != null) {
        await FirebaseStorage.instance.refFromURL(imageUrl!).delete();
      }

      final file = File(pickedImage.path);
      final fileName = '${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('profile_images/$fileName');
      await ref.putFile(file);

      final newUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set(
        {'imageUrl': newUrl},
        SetOptions(merge: true),
      );

      setState(() => imageUrl = newUrl);
    } catch (e) {
      print('Upload failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image upload failed.')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$title – Coming Soon")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Settings"),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isLoading) const Center(child: CircularProgressIndicator()),
          Center(
            child: GestureDetector(
              onTap: pickAndUploadImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                child: imageUrl == null
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text("Tap image to update from gallery", style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 30),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Change Password"),
            onTap: () => showComingSoon("Change Password"),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text("Notification Settings"),
            onTap: () => showComingSoon("Notification Settings"),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text("Theme Mode"),
            onTap: () => showComingSoon("Theme Mode"),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About App"),
            onTap: () => showComingSoon("About App"),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Help & Support"),
            onTap: () => showComingSoon("Help & Support"),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
