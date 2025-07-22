import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:studyhub/features/resource/subject/subject_detail.dart';

class SubjectPage extends StatefulWidget {
  final String userId; // NEW: add userId here
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
    required this.userId, // required userId
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
            .collection('users') // user scoped
            .doc(widget.userId)
            .collection('institutions') // user scoped institutions
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
                      .collection('users')
                      .doc(widget.userId) // user scoped
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
                  if (mounted) {
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

  Future<void> _renameSubject(QueryDocumentSnapshot subject) async {
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
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userId)
                      .collection('institutions')
                      .doc(widget.institutionId)
                      .collection(widget.collectionName)
                      .doc(widget.semesterOrClassId)
                      .collection('subjects')
                      .doc(subject.id)
                      .update({'name': newName});
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
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
      try {
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete subject: $e')),
          );
        }
      }
    }
  }
}
