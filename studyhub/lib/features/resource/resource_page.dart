import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:studyhub/features/resource/institution/institution_screen.dart';

class ResourcePage extends StatelessWidget {
  const ResourcePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Study Resources',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('resources').orderBy('name').snapshots(),
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
                  const Icon(Icons.school, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No institutions found',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _addInstitution(context),
                    child: const Text('Add your first institution'),
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
              final institution = snapshot.data!.docs[index];
              return _buildInstitutionCard(context, institution);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addInstitution(context),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildInstitutionCard(BuildContext context, QueryDocumentSnapshot institution) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.school, color: Colors.deepPurple),
        ),
        title: Text(
          institution['name'],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleInstitutionAction(value, institution, context),
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
                title: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InstitutionPage(
                institutionId: institution.id,
                institutionName: institution['name'],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleInstitutionAction(String action, QueryDocumentSnapshot institution, BuildContext context) {
    switch (action) {
      case 'rename':
        _renameInstitution(institution, context);
        break;
      case 'delete':
        _deleteInstitution(institution.id, context);
        break;
    }
  }

  Future<void> _renameInstitution(QueryDocumentSnapshot institution, BuildContext context) async {
    final controller = TextEditingController(text: institution['name']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Institution'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Institution Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('resources')
                    .doc(institution.id)
                    .update({
                  'name': newName,
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteInstitution(String institutionId, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Institution'),
        content: const Text('Are you sure you want to delete this institution?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('resources').doc(institutionId).delete();
    }
  }

  Future<void> _addInstitution(BuildContext context) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Institution'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Institution Name',
            hintText: 'e.g., Texas College',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await FirebaseFirestore.instance.collection('resources').add({
                  'name': name,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}