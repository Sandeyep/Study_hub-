import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studyhub/features/resource/semester/semester_screen.dart';

class InstitutionPage extends StatelessWidget {
  final String institutionId;
  final String institutionName;
  final bool isSchoolLevel;

  const InstitutionPage({
    super.key,
    required this.institutionId,
    required this.institutionName,
    this.isSchoolLevel = false,
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return SemesterPage(
      userId: userId,
      institutionId: institutionId,
      institutionName: institutionName,
      isSchoolLevel: isSchoolLevel,
    );
  }
}
