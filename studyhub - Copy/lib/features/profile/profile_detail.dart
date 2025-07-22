import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileDetailPage extends StatefulWidget {
  const ProfileDetailPage({super.key});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  File? _imageFile;

  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final phoneController = TextEditingController();
  final studentIdController = TextEditingController();
  final addressController = TextEditingController();
  final institutionController = TextEditingController();

  String email = '';
  String _selectedGender = 'Male';
  String? selectedEducation;

  bool isLoading = true;

  final List<String> allowedEducations = [
    'High School',
    'Bachelor',
    'Master',
    'Other',
  ];

  static const primaryColor = Colors.teal;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    _loadImagePath();
  }

  Future<void> _loadImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_path');
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        setState(() {
          _imageFile = file;
        });
      }
    }
  }

  Future<void> _saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', path);
  }

  Future<void> _pickImage() async {
    final permission = await Permission.storage.request();
    if (permission.isGranted) {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = picked.name;
        final savedImage = await File(
          picked.path,
        ).copy('${appDir.path}/$fileName');

        await _saveImagePath(savedImage.path);
        setState(() {
          _imageFile = savedImage;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied to access gallery')),
      );
    }
  }

  void _showFullImage() {
    if (_imageFile == null) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Image.file(_imageFile!),
        ),
      ),
    );
  }

  Future<void> fetchUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          nameController.text = data['name'] ?? '';
          dobController.text = data['dob'] ?? '';
          _selectedGender = data['gender'] ?? 'Male';
          phoneController.text = data['phone'] ?? '';
          studentIdController.text = data['studentId'] ?? '';
          addressController.text = data['address'] ?? '';
          institutionController.text = data['institution'] ?? '';

          if (allowedEducations.contains(data['education'])) {
            selectedEducation = data['education'];
          } else {
            selectedEducation = 'High School';
          }

          email = FirebaseAuth.instance.currentUser?.email ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          selectedEducation = 'High School';
          email = FirebaseAuth.instance.currentUser?.email ?? '';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      setState(() {
        selectedEducation = 'High School';
        isLoading = false;
      });
    }
  }

  Future<void> updateUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': nameController.text.trim(),
        'dob': dobController.text.trim(),
        'gender': _selectedGender,
        'phone': phoneController.text.trim(),
        'studentId': studentIdController.text.trim(),
        'address': addressController.text.trim(),
        'institution': institutionController.text.trim(),
        'education': selectedEducation ?? 'High School',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      debugPrint('Error updating profile: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    dobController.dispose();
    phoneController.dispose();
    studentIdController.dispose();
    addressController.dispose();
    institutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Edit Profile'),
        centerTitle: true,
        leading: const BackButton(),
      ),
      backgroundColor: Colors.teal.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile image with shadow and edit icon
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.teal.shade200,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : null,
                    child: _imageFile == null
                        ? Text(
                            'Upload\nImage',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Material(
                      color: primaryColor,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _pickImage,
                        tooltip: 'Change Profile Picture',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name field
            _buildTextField(
              'Name',
              controller: nameController,
              icon: Icons.person,
            ),

            // Email field (readonly)
            _buildTextField(
              'Email',
              value: email,
              enabled: false,
              icon: Icons.email,
            ),

            // Date of birth
            _buildTextField(
              'Date of Birth',
              controller: dobController,
              icon: Icons.calendar_today,
            ),

            // Phone number
            _buildTextField(
              'Phone Number',
              controller: phoneController,
              icon: Icons.phone,
            ),

            // Student ID
            _buildTextField(
              'Student ID',
              controller: studentIdController,
              icon: Icons.school,
            ),

            // Institution
            _buildTextField(
              'Institution',
              controller: institutionController,
              icon: Icons.account_balance,
            ),

            // Education dropdown
            buildEducationDropdown(),

            // Gender selector
            _buildGenderSelector(),

            // Address multiline
            _buildTextField(
              'Address',
              controller: addressController,
              icon: Icons.home,
              maxLines: 2,
              keyboardType: TextInputType.multiline,
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: updateUserProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Update Profile',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    String? value,
    TextEditingController? controller,
    bool enabled = true,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? value : null,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: primaryColor) : null,
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade200,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget buildEducationDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: selectedEducation,
        decoration: InputDecoration(
          labelText: 'Education',
          prefixIcon: Icon(Icons.menu_book, color: primaryColor),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: allowedEducations
            .map((edu) => DropdownMenuItem(value: edu, child: Text(edu)))
            .toList(),
        onChanged: (val) {
          setState(() {
            selectedEducation = val;
          });
        },
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Text('Gender:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 20,
              children: ['Male', 'Female', 'Other'].map((gender) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: gender,
                      groupValue: _selectedGender,
                      activeColor: primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                    Text(gender),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
