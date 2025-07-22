import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SubjectDetailPage extends StatefulWidget {
  final String userId;
  final String institutionId;
  final String subjectId;
  final String subjectName;

  const SubjectDetailPage({
    super.key,
    required this.userId,
    required this.institutionId,
    required this.subjectId,
    required this.subjectName,
    required fileCount,
  });

  @override
  State<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<SubjectDetailPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  List<DocumentSnapshot> allFiles = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('institutions')
        .doc(widget.institutionId)
        .collection('subjects')
        .doc(widget.subjectId)
        .collection('files')
        .orderBy('uploadedAt', descending: true)
        .get();

    setState(() {
      allFiles = snapshot.docs;
    });
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
      if (fileBytes == null) throw Exception("File bytes are null");

      const cloudName = 'drjnvn0mb';
      const uploadPreset = 'flutter_unsigned_preset';

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['resource_type'] = 'auto'
        ..files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final downloadUrl = data['secure_url'];
        final fileExt = fileName.split('.').last.toLowerCase();
        String fileType = _mapFileType(fileExt);

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
              'type': fileType,
              'uploadedAt': FieldValue.serverTimestamp(),
              'isFavorite': false,
            });

        await _loadFiles();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$fileName uploaded!')));
      } else {
        print('Cloudinary error: ${response.body}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _mapFileType(String ext) {
    switch (ext) {
      case 'pdf':
        return 'pdf';
      case 'docx':
        return 'docx';
      case 'pptx':
        return 'pptx';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'photo';
      default:
        return 'file';
    }
  }

  void _showFileOptions(DocumentSnapshot file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download'),
            onTap: () => _launchURL(file['url']),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () async {
              Navigator.pop(context);
              final name = await _promptRename(file['name']);
              if (name != null) {
                await file.reference.update({'name': name});
                _loadFiles();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () async {
              await file.reference.delete();
              Navigator.pop(context);
              _loadFiles();
            },
          ),
        ],
      ),
    );
  }

  Future<String?> _promptRename(String current) async {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
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

  void _toggleFavorite(DocumentSnapshot file) async {
    await file.reference.update({'isFavorite': !(file['isFavorite'] ?? false)});
    _loadFiles();
  }

  Widget _buildTabContent(String type) {
    final filtered = allFiles.where((doc) {
      if (type == 'additional') {
        return doc['isFavorite'] || doc['type'] == 'link';
      }
      return doc['type'] == type;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No files'));
    }

    filtered.sort((a, b) {
      final aTime = (a['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      final bTime = (b['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    final now = DateTime.now();
    final Map<String, List<DocumentSnapshot>> grouped = {};

    for (var doc in filtered) {
      final date =
          (doc['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      String groupKey;
      if (now.difference(date).inDays == 0) {
        groupKey = 'Today';
      } else if (now.difference(date).inDays == 1) {
        groupKey = 'Yesterday';
      } else {
        groupKey = DateFormat('d MMM yyyy').format(date);
      }
      grouped.putIfAbsent(groupKey, () => []).add(doc);
    }

    return ListView(
      children: grouped.entries.expand((entry) {
        final header = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            entry.key,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );

        final files = entry.value.map((file) {
          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                file['type'] == 'photo'
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          file['url'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(_getFileIcon(file['type']), size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file['name'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'options') _showFileOptions(file);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'options',
                      child: Text('Options'),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _launchURL(file['url']),
                  child: const Text('Open'),
                ),
                IconButton(
                  icon: Icon(
                    (file['isFavorite'] ?? false)
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.orange,
                  ),
                  onPressed: () => _toggleFavorite(file),
                ),
              ],
            ),
          );
        }).toList();

        return [header, ...files];
      }).toList(),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type) {
      case 'photo':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
        return Icons.description;
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastUpdated = allFiles.isNotEmpty
        ? (allFiles.first['uploadedAt'] as Timestamp?)?.toDate()
        : null;

    String lastUpdatedText = 'Last updated: Unknown';
    if (lastUpdated != null) {
      final now = DateTime.now();
      if (now.difference(lastUpdated).inDays == 0) {
        lastUpdatedText = 'Last updated today';
      } else {
        lastUpdatedText =
            'Last updated on ${lastUpdated.day}/${lastUpdated.month}/${lastUpdated.year}';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ✅ Teal Gradient matching login theme
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Color(0xFF00695C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.subjectName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${allFiles.length} files',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastUpdatedText,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.black54,
            tabs: const [
              Tab(text: 'Photos'),
              Tab(text: 'PDFs'),
              Tab(text: 'DOCX'),
              Tab(text: 'PPTX'),
              Tab(text: 'Additional'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent('photo'),
                _buildTabContent('pdf'),
                _buildTabContent('docx'),
                _buildTabContent('pptx'),
                _buildTabContent('additional'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: isLoading ? null : _uploadFile,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.upload),
      ),
    );
  }
}
