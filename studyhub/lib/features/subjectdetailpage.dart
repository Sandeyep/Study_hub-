import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubjectPage extends StatelessWidget {
  final String institutionId;
  final String semesterOrClassId;
  final String semesterOrClassName;
  final String collectionName;

  const SubjectPage({
    super.key,
    required this.institutionId,
    required this.semesterOrClassId,
    required this.semesterOrClassName,
    required this.collectionName, required String subjectName, required String semesterId, required String semesterName,
  });

  @override
  Widget build(BuildContext context) {
    // Add validation for institutionId and semesterOrClassId
    if (institutionId.isEmpty || semesterOrClassId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Invalid institution or semester/class ID')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(semesterOrClassName), elevation: 0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('resources')
            .doc(institutionId)
            .collection(collectionName)
            .doc(semesterOrClassId)
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

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final subject = snapshot.data!.docs[index];
              // Add validation for subject.id
              if (subject.id.isEmpty) {
                return const ListTile(
                  title: Text('Invalid subject ID'),
                );
              }

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
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
                    child: const Icon(
                      Icons.menu_book,
                      color: Colors.deepPurple,
                    ),
                  ),
                  title: Text(
                    subject['name'] ?? 'Unnamed Subject',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('${subject['fileCount'] ?? 0} files'),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) =>
                        _handleSubjectAction(value, subject, context),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Rename'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSubject(context),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
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
                  await FirebaseFirestore.instance
                      .collection('resources')
                      .doc(institutionId)
                      .collection(collectionName)
                      .doc(semesterOrClassId)
                      .collection('subjects')
                      .add({
                    'name': name,
                    'fileCount': 0,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add subject: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleSubjectAction(
    String action,
    QueryDocumentSnapshot subject,
    BuildContext context,
  ) {
    switch (action) {
      case 'rename':
        _renameSubject(subject, context);
        break;
      case 'delete':
        _deleteSubject(subject.id, context);
        break;
    }
  }

  Future<void> _renameSubject(
    QueryDocumentSnapshot subject,
    BuildContext context,
  ) async {
    final controller = TextEditingController(text: subject['name'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Subject'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
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
                try {
                  await subject.reference.update({'name': newName});
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to rename subject: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubject(String subjectId, BuildContext context) async {
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
      try {
        await FirebaseFirestore.instance
            .collection('resources')
            .doc(institutionId)
            .collection(collectionName)
            .doc(semesterOrClassId)
            .collection('subjects')
            .doc(subjectId)
            .delete();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete subject: $e')),
          );
        }
      }
    }
  }
}