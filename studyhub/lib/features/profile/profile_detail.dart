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
      print('Error fetching user profile: $e');
      setState(() {
        selectedEducation = 'High School';
        isLoading = false;
      });
    }
  }

  Future<void> updateUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

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
        title: const Text('Profile'),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_imageFile != null) {
                      _showFullImage();
                    } else {
                      _pickImage();
                    }
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : null,
                    child: _imageFile == null
                        ? const Text(
                            'Upload\nImage',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField('Name', controller: nameController),
            _buildTextField('Email', value: email, enabled: false),
            _buildTextField('Date of birth', controller: dobController),
            _buildTextField('Phone Number', controller: phoneController),
            _buildTextField('Student ID', controller: studentIdController),
            _buildTextField('Institution', controller: institutionController),
            buildEducationDropdown(),
            _buildGenderSelector(),
            _buildTextField('Address', controller: addressController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateUserProfile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Update Profile',
                style: TextStyle(color: Colors.white),
              ),
            ),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        enabled: enabled,
        controller: controller,
        initialValue: controller == null ? value : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget buildEducationDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: selectedEducation,
        decoration: InputDecoration(
          labelText: 'Education',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          const Text('Gender:'),
          const SizedBox(width: 10),
          Row(
            children: [
              Radio<String>(
                value: 'Male',
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
              const Text('Male'),
            ],
          ),
          Row(
            children: [
              Radio<String>(
                value: 'Female',
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
              const Text('Female'),
            ],
          ),
          Row(
            children: [
              Radio<String>(
                value: 'Other',
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
              const Text('Other'),
            ],
          ),
        ],
      ),
    );
  }
}
