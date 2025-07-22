import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:studyhub/features/subject_screen.dart';

class SemesterPage extends StatefulWidget {
  final String userId; // NEW: userId passed from InstitutionPage
  final String institutionId;
  final String institutionName;
  final bool isSchoolLevel;

  const SemesterPage({
    super.key,
    required this.userId,
    required this.institutionId,
    required this.institutionName,
    this.isSchoolLevel = false,
  });

  @override
  State<SemesterPage> createState() => _SemesterPageState();
}

class _SemesterPageState extends State<SemesterPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    if (widget.institutionId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Invalid institution ID')),
      );
    }

    final collectionName = widget.isSchoolLevel ? 'classes' : 'semesters';

    return Scaffold(
      appBar: AppBar(title: Text(widget.institutionName), elevation: 0),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(widget.userId) // user-specific
            .collection('institutions')
            .doc(widget.institutionId)
            .collection(collectionName)
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
                  Icon(
                    widget.isSchoolLevel ? Icons.class_ : Icons.school,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isSchoolLevel
                        ? 'No classes found'
                        : 'No semesters found',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _addSemesterOrClass(context),
                    child: Text(
                      widget.isSchoolLevel ? 'Add Class' : 'Add Semester',
                    ),
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
              final semesterOrClass = snapshot.data!.docs[index];
              if (semesterOrClass.id.isEmpty) {
                return const ListTile(title: Text('Invalid semester/class ID'));
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
                    child: Icon(
                      widget.isSchoolLevel ? Icons.class_ : Icons.school,
                      color: Colors.deepPurple,
                    ),
                  ),
                  title: Text(
                    semesterOrClass['name'] ?? 'Unnamed',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) =>
                        _handleSemesterAction(value, semesterOrClass, context),
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubjectPage(
                          institutionId: widget.institutionId,
                          semesterOrClassId: semesterOrClass.id,
                          semesterOrClassName:
                              semesterOrClass['name'] ?? 'Unnamed',
                          collectionName: collectionName,
                          semesterId: '',
                          semesterName: '',
                          subjectName: '',
                          institutionName: '',
                          userId: 'widget.userId', // ⚠️ THIS IS EMPTY
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSemesterOrClass(context),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _addSemesterOrClass(BuildContext context) async {
    final controller = TextEditingController();
    final collectionName = widget.isSchoolLevel ? 'classes' : 'semesters';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isSchoolLevel ? 'Add Class' : 'Add Semester'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: widget.isSchoolLevel ? 'Class Name' : 'Semester Name',
            hintText: widget.isSchoolLevel
                ? 'e.g., Class 7, Grade 10'
                : 'e.g., Semester 1, Fall 2023',
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
                  await _firestore
                      .collection('users')
                      .doc(widget.userId)
                      .collection('institutions')
                      .doc(widget.institutionId)
                      .collection(collectionName)
                      .add({
                        'name': name,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add: $e')),
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

  void _handleSemesterAction(
    String action,
    QueryDocumentSnapshot semesterOrClass,
    BuildContext context,
  ) {
    switch (action) {
      case 'rename':
        _renameSemesterOrClass(semesterOrClass, context);
        break;
      case 'delete':
        _deleteSemesterOrClass(semesterOrClass.id, context);
        break;
    }
  }

  Future<void> _renameSemesterOrClass(
    QueryDocumentSnapshot semesterOrClass,
    BuildContext context,
  ) async {
    final controller = TextEditingController(
      text: semesterOrClass['name'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isSchoolLevel ? 'Rename Class' : 'Rename Semester'),
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
                  await _firestore
                      .collection('users')
                      .doc(widget.userId)
                      .collection('institutions')
                      .doc(widget.institutionId)
                      .collection(
                        widget.isSchoolLevel ? 'classes' : 'semesters',
                      )
                      .doc(semesterOrClass.id)
                      .update({'name': newName});
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to rename: $e')),
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

  Future<void> _deleteSemesterOrClass(String id, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isSchoolLevel ? 'Delete Class' : 'Delete Semester'),
        content: Text(
          widget.isSchoolLevel
              ? 'Are you sure you want to delete this class?'
              : 'Are you sure you want to delete this semester?',
        ),
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
        await _firestore
            .collection('users')
            .doc(widget.userId)
            .collection('institutions')
            .doc(widget.institutionId)
            .collection(widget.isSchoolLevel ? 'classes' : 'semesters')
            .doc(id)
            .delete();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }
}
