import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ProfileDetailPage extends StatefulWidget {
  const ProfileDetailPage({super.key});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  File? _imageFile;
  String? _profileImageUrl;

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
          _profileImageUrl = data['profileImage'] ?? '';

          if (allowedEducations.contains(data['education'])) {
            selectedEducation = data['education'];
          } else {
            selectedEducation = 'High School';
          }

          email = FirebaseAuth.instance.currentUser?.email ?? '';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      String? uploadedUrl;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        uploadedUrl = await _uploadToCloudinaryWeb(bytes);
      } else {
        final file = File(picked.path);
        uploadedUrl = await _uploadToCloudinaryFile(file);
        _imageFile = file;
      }

      if (uploadedUrl != null) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'profileImage': uploadedUrl,
          });
        }

        setState(() {
          _profileImageUrl = uploadedUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Image uploaded to Cloudinary!')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❌ Upload failed')));
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String?> _uploadToCloudinaryWeb(Uint8List bytes) async {
    const cloudName = 'drjnvn0mb';
    const uploadPreset = 'flutter_unsigned_preset';

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: 'profile.jpg'),
      );

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final secureUrl = RegExp(
        r'"secure_url":"(.*?)"',
      ).firstMatch(respStr)?.group(1);
      return secureUrl?.replaceAll(r'\/', '/');
    }
    return null;
  }

  Future<String?> _uploadToCloudinaryFile(File file) async {
    const cloudName = 'YOUR_CLOUD_NAME';
    const uploadPreset = 'YOUR_UNSIGNED_UPLOAD_PRESET';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final secureUrl = RegExp(
        r'"secure_url":"(.*?)"',
      ).firstMatch(respStr)?.group(1);
      return secureUrl?.replaceAll(r'\/', '/');
    }
    return null;
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Profile updated')));
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: FloatingActionButton.small(
                    backgroundColor: primaryColor,
                    onPressed: _pickAndUploadImage,
                    child: const Icon(Icons.camera_alt, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              'Name',
              controller: nameController,
              icon: Icons.person,
            ),
            _buildTextField(
              'Email',
              value: email,
              enabled: false,
              icon: Icons.email,
            ),
            _buildTextField(
              'Date of Birth',
              controller: dobController,
              icon: Icons.calendar_today,
            ),
            _buildTextField(
              'Phone Number',
              controller: phoneController,
              icon: Icons.phone,
            ),
            _buildTextField(
              'Student ID',
              controller: studentIdController,
              icon: Icons.school,
            ),
            _buildTextField(
              'Institution',
              controller: institutionController,
              icon: Icons.account_balance,
            ),
            buildEducationDropdown(),
            _buildGenderSelector(),
            _buildTextField(
              'Address',
              controller: addressController,
              icon: Icons.home,
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateUserProfile,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text(
                'Save Profile',
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
    IconData? icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? value : null,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: primaryColor) : null,
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade200,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget buildEducationDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedEducation,
      decoration: InputDecoration(
        labelText: 'Education',
        prefixIcon: Icon(Icons.menu_book, color: primaryColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: allowedEducations
          .map((edu) => DropdownMenuItem(value: edu, child: Text(edu)))
          .toList(),
      onChanged: (val) {
        setState(() {
          selectedEducation = val;
        });
      },
    );
  }

  Widget _buildGenderSelector() {
    return Row(
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
    );
  }
}
