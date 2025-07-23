import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubjectSelectionDialog extends StatelessWidget {
  final String userId;
  final String institutionId;
  final String semesterId;
  final Function(String) onSubjectSelected;

  const SubjectSelectionDialog({
    super.key,
    required this.userId,
    required this.institutionId,
    required this.semesterId,
    required this.onSubjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Subject'),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('institutions')
              .doc(institutionId)
              .collection('semesters')
              .doc(semesterId)
              .collection('subjects')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final subjects = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return ListTile(
                  title: Text(subject['name']),
                  onTap: () {
                    onSubjectSelected(subject.id);
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
