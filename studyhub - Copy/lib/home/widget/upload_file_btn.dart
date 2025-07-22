import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class UploadFileBtn extends StatefulWidget {
  final Function(File) onImageSelected;
  final Function(File) onPdfSelected;

  const UploadFileBtn({
    super.key,
    required this.onImageSelected,
    required this.onPdfSelected,
  });

  @override
  State<UploadFileBtn> createState() => _UploadFileBtnState();
}

class _UploadFileBtnState extends State<UploadFileBtn> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        widget.onImageSelected(File(photo.path));
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Camera permission denied")));
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      widget.onImageSelected(File(image.path));
      Navigator.pop(context);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      widget.onPdfSelected(File(result.files.single.path!));
      Navigator.pop(context);
    }
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: MediaQuery.of(
          context,
        ).viewInsets.add(const EdgeInsets.all(20)),
        child: Wrap(
          children: [
            const Center(
              child: Text(
                'Upload File',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildOption(
                  icon: Icons.camera_alt,
                  label: 'Take Photo',
                  color: Colors.teal,
                  onTap: _takePhoto,
                ),
                const SizedBox(width: 12),
                _buildOption(
                  icon: Icons.image,
                  label: 'From Gallery',
                  color: Colors.blue,
                  onTap: _pickFromGallery,
                ),
                const SizedBox(width: 12),
                _buildOption(
                  icon: Icons.upload_file,
                  label: 'Upload File',
                  color: Colors.deepPurple,
                  onTap: _pickFile,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
