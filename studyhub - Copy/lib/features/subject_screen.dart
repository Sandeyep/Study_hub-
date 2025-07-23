import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:studyhub/features/resource/subject/subject_detail.dart';
import 'package:studyhub/home/widget/upload_file_btn.dart';

class SubjectPage extends StatefulWidget {
  final String userId;
  final String institutionId;
  final String semesterOrClassId;
  final String semesterOrClassName;
  final String collectionName;
  final String subjectName;
  final String semesterName;
  final String institutionName;
  final String semesterId;

  const SubjectPage({
    super.key,
    required this.userId,
    required this.institutionId,
    required this.semesterOrClassId,
    required this.semesterOrClassName,
    required this.collectionName,
    required this.subjectName,
    required this.semesterName,
    required this.institutionName,
    required this.semesterId,
  });

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  bool _isGridView = false;

  void _showUploadDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => UploadFileBtn(
        userId: widget.userId,
        institutionId: widget.institutionId,
        semesterId: widget.semesterId,
        onFileSelectedWithSubject: (file, subjectId) {
          return _uploadFileToSubject(file, subjectId);
        },
        onImageSelected: (file) async {
          return;
        },
        onPdfSelected: (file) async {
          return;
        },
      ),
    );
  }

  Future<void> _uploadFileToSubject(File file, String subjectId) async {
    if (!_validateIds(subjectId)) return;

    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(_uploadingSnackbar());

      final storagePath =
          'users/${widget.userId}/files/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      await _saveFileMetadata(subjectId, file, downloadUrl);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('✅ File uploaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Upload failed: ${e.toString()}')),
      );
    }
  }

  bool _validateIds(String subjectId) {
    if (widget.userId.isEmpty ||
        widget.institutionId.isEmpty ||
        widget.semesterOrClassId.isEmpty ||
        subjectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing required IDs for upload')),
      );
      return false;
    }
    return true;
  }

  SnackBar _uploadingSnackbar() {
    return const SnackBar(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Uploading...'),
        ],
      ),
      duration: Duration(minutes: 1),
    );
  }

  Future<void> _saveFileMetadata(
    String subjectId,
    File file,
    String url,
  ) async {
    final fileName = file.path.split('/').last;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('institutions')
        .doc(widget.institutionId)
        .collection(widget.collectionName)
        .doc(widget.semesterOrClassId)
        .collection('subjects')
        .doc(subjectId)
        .collection('files')
        .add({
          'name': fileName,
          'url': url,
          'type': _getFileType(fileName),
          'uploadedAt': FieldValue.serverTimestamp(),
        });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('institutions')
        .doc(widget.institutionId)
        .collection(widget.collectionName)
        .doc(widget.semesterOrClassId)
        .collection('subjects')
        .doc(subjectId)
        .update({'fileCount': FieldValue.increment(1)});
  }

  String _getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'photo';
      case 'pdf':
        return 'pdf';
      case 'docx':
        return 'docx';
      case 'pptx':
        return 'pptx';
      default:
        return 'file';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.semesterOrClassName} > Subjects"),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView
                ? 'Switch to List View'
                : 'Switch to Grid View',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('institutions')
            .doc(widget.institutionId)
            .collection(widget.collectionName)
            .doc(widget.semesterOrClassId)
            .collection('subjects')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No subjects found',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _addSubject(context),
                    child: const Text('Add Subject'),
                  ),
                ],
              ),
            );
          }

          final subjects = snapshot.data!.docs;
          return _isGridView
              ? _buildGridView(subjects)
              : _buildListView(subjects);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSubject(context),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildListView(List<QueryDocumentSnapshot> subjects) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: subjects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildSubjectCard(subjects[index]),
    );
  }

  Widget _buildGridView(List<QueryDocumentSnapshot> subjects) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) => _buildSubjectGridItem(subjects[index]),
    );
  }

  Widget _buildSubjectCard(QueryDocumentSnapshot subject) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubjectDetailPage(
                subjectName: subject['name'] ?? 'Unnamed Subject',
                fileCount: subject['fileCount'] ?? 0,
                userId: widget.userId,
                institutionId: widget.institutionId,
                subjectId: subject.id,
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.menu_book, color: Colors.deepPurple),
        ),
        title: Text(
          subject['name'] ?? 'Unnamed Subject',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('${subject['fileCount'] ?? 0} files'),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleSubjectAction(value, subject),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child: ListTile(leading: Icon(Icons.edit), title: Text('Rename')),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectGridItem(QueryDocumentSnapshot subject) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubjectDetailPage(
                subjectName: subject['name'] ?? 'Unnamed Subject',
                fileCount: subject['fileCount'] ?? 0,
                userId: widget.userId,
                institutionId: widget.institutionId,
                subjectId: subject.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: Colors.deepPurple,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subject['name'] ?? 'Unnamed',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${subject['fileCount'] ?? 0} files',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubjectAction(String action, QueryDocumentSnapshot subject) {
    switch (action) {
      case 'rename':
        _renameSubject(subject);
        break;
      case 'delete':
        _deleteSubject(subject.id);
        break;
    }
  }

  Future<void> _addSubject(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subject'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Subject Name',
            hintText: 'e.g., Mathematics, Physics',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                try {
                  print('Adding subject: $name');
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userId)
                      .collection('institutions')
                      .doc(widget.institutionId)
                      .collection(widget.collectionName)
                      .doc(widget.semesterOrClassId)
                      .collection('subjects')
                      .add({
                        'name': name,
                        'fileCount': 0,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  print('Error adding subject: $e');
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _renameSubject(QueryDocumentSnapshot subject) async {
    final controller = TextEditingController(text: subject['name'] ?? '');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Subject'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await subject.reference.update({'name': newName});
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubject(String subjectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: const Text('Are you sure you want to delete this subject?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('institutions')
          .doc(widget.institutionId)
          .collection(widget.collectionName)
          .doc(widget.semesterOrClassId)
          .collection('subjects')
          .doc(subjectId)
          .delete();
    }
  }
}
