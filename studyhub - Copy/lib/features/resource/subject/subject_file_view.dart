import 'dart:html' as html;
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class SubjectFileView extends StatefulWidget {
  final String userId;
  final String institutionId;
  final String subjectId;
  final String fileType;

  const SubjectFileView({
    super.key,
    required this.userId,
    required this.institutionId,
    required this.subjectId,
    required this.fileType,
  });

  @override
  State<SubjectFileView> createState() => _SubjectFileViewState();
}

class _SubjectFileViewState extends State<SubjectFileView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool isLoading = false;
  List<Map<String, dynamic>> files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('institutions')
          .doc(widget.institutionId)
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('files')
          .where('type', isEqualTo: widget.fileType)
          .orderBy('uploadedAt', descending: true)
          .get();

      setState(() {
        files = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      debugPrint('Error loading files: $e');
    }
  }

  Future<void> _uploadFile() async {
    setState(() => isLoading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'docx', 'pptx'],
        withData: true,
      );

      if (result == null) return;

      final file = result.files.first;
      final Uint8List? fileBytes = file.bytes;
      final String fileName = file.name;

      String fileExt = path.extension(fileName);
      String storagePath =
          '${widget.userId}/${widget.institutionId}/${widget.subjectId}/${DateTime.now().millisecondsSinceEpoch}$fileExt';

      Reference ref = _storage.ref().child(storagePath);

      if (fileBytes != null) {
        await ref.putData(fileBytes);
      } else if (!kIsWeb && file.path != null) {
        final fileOnDisk = File(file.path!);
        await ref.putFile(fileOnDisk);
      } else {
        throw Exception("Could not get file bytes or path");
      }

      String downloadUrl = await ref.getDownloadURL();

      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('institutions')
          .doc(widget.institutionId)
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('files')
          .add({
            'name': fileName,
            'url': downloadUrl,
            'type': widget.fileType,
            'uploadedAt': FieldValue.serverTimestamp(),
          });

      _loadFiles();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fileName uploaded successfully!')),
      );
    } catch (e) {
      debugPrint('Upload error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _launchURL(String url) async {
    if (kIsWeb) {
      html.window.open(url, '_blank');
    } else {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Widget _buildFileIcon(String type) {
    switch (type) {
      case 'photos':
        return const Icon(Icons.photo, color: Colors.green);
      case 'pdfs':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'docs':
        return const Icon(Icons.description, color: Colors.blue);
      case 'ppts':
        return const Icon(Icons.slideshow, color: Colors.orange);
      case 'videos':
        return const Icon(Icons.video_library, color: Colors.purple);
      case 'starred':
        return const Icon(Icons.star, color: Colors.amber);
      default:
        return const Icon(Icons.insert_drive_file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        files.isEmpty
            ? const Center(child: Text('No files yet'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: files.length,
                itemBuilder: (_, i) {
                  final file = files[i];
                  return ListTile(
                    leading: _buildFileIcon(widget.fileType),
                    title: Text(file['name'] ?? 'Unnamed'),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _launchURL(file['url']),
                    ),
                  );
                },
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: isLoading ? null : _uploadFile,
            backgroundColor: const Color(0xFF6366F1),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.upload),
          ),
        ),
      ],
    );
  }
}
