import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:studyhub/features/resource/subject/subject_selection_dialog.dart';

class UploadFileBtn extends StatelessWidget {
  final String userId;
  final String institutionId;
  final String semesterId;
  final Function(File, String) onFileSelectedWithSubject;
  final void Function(File file) onImageSelected;
  final void Function(File file) onPdfSelected;

  UploadFileBtn({
    super.key,
    required this.userId,
    required this.institutionId,
    required this.semesterId,
    required this.onFileSelectedWithSubject,
    required this.onImageSelected,
    required this.onPdfSelected,
  });

  final ImagePicker _picker = ImagePicker();

  Future<File?> _takePhoto(BuildContext context) async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) return File(photo.path);
    }
    return null;
  }

  Future<File?> _pickFromGallery(BuildContext context) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) return File(image.path);
    return null;
  }

  Future<File?> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  Future<void> _handleFileSelection(BuildContext context, File file) async {
    final subjectId = await showDialog<String>(
      context: context,
      builder: (context) => SubjectSelectionDialog(
        userId: userId,
        institutionId: institutionId,
        semesterId: semesterId,
        onSubjectSelected: (subjectId) => Navigator.pop(context, subjectId),
      ),
    );

    if (subjectId != null && context.mounted) {
      onFileSelectedWithSubject(file, subjectId);
      Navigator.pop(context);
    }
  }

  Widget _buildOption(
    BuildContext context, {
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
                  context,
                  icon: Icons.camera_alt,
                  label: 'Take Photo',
                  color: Colors.teal,
                  onTap: () async {
                    final file = await _takePhoto(context);
                    if (file != null) {
                      onImageSelected(file);
                      await _handleFileSelection(context, file);
                    }
                  },
                ),
                const SizedBox(width: 12),
                _buildOption(
                  context,
                  icon: Icons.image,
                  label: 'From Gallery',
                  color: Colors.blue,
                  onTap: () async {
                    final file = await _pickFromGallery(context);
                    if (file != null) {
                      onImageSelected(file);
                      await _handleFileSelection(context, file);
                    }
                  },
                ),
                const SizedBox(width: 12),
                _buildOption(
                  context,
                  icon: Icons.upload_file,
                  label: 'Upload File',
                  color: Colors.deepPurple,
                  onTap: () async {
                    final file = await _pickFile(context);
                    if (file != null) {
                      onPdfSelected(file);
                      await _handleFileSelection(context, file);
                    }
                  },
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
