import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:studyhub/home/dashboard.dart'; // Your dashboard page import

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final institutionController = TextEditingController();

  String? selectedGender;
  String? selectedEducationLevel;
  int step = 0;

  final List<Map<String, dynamic>> steps = [
    {"label": "Name", "icon": Icons.person_outline},
    {"label": "DOB", "icon": Icons.calendar_today_outlined},
    {"label": "Gender", "icon": Icons.wc_outlined},
    {"label": "Education", "icon": Icons.school_outlined},
    {"label": "Institution", "icon": Icons.account_balance_outlined},
  ];

  void nextStep() {
    if (step < steps.length - 1) setState(() => step++);
  }

  void previousStep() {
    if (step > 0) setState(() => step--);
  }

  Future<void> selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      dobController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
    }
  }

  Future<void> saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      Get.snackbar("Error", "User not logged in.");
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': nameController.text.trim(),
      'dob': dobController.text.trim(),
      'gender': selectedGender,
      'education': selectedEducationLevel,
      'institution': institutionController.text.trim(),
      'createdAt': Timestamp.now(),
    });

    Get.offAll(() => const DashBoard());
  }

  Widget buildStepWidget() {
    switch (step) {
      case 0:
        return buildTextField("Your Name", nameController);
      case 1:
        return buildTextField(
          "Date of Birth",
          dobController,
          readOnly: true,
          onTap: selectDate,
          suffixIcon: const Icon(Icons.calendar_today),
        );
      case 2:
        return buildDropdown(
          label: "Gender",
          value: selectedGender,
          items: ['Male', 'Female', 'Other'],
          onChanged: (val) => setState(() => selectedGender = val),
        );
      case 3:
        return buildDropdown(
          label: "Education Level",
          value: selectedEducationLevel,
          items: ['High School', 'Bachelor', 'Master', 'Other'],
          onChanged: (val) => setState(() => selectedEducationLevel = val),
        );
      case 4:
        return buildTextField("Institution Name", institutionController);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  void handleNext() {
    if (step == steps.length - 1) {
      if (nameController.text.isEmpty ||
          dobController.text.isEmpty ||
          selectedGender == null ||
          selectedEducationLevel == null ||
          institutionController.text.isEmpty) {
        Get.snackbar("Incomplete", "Please fill all fields");
        return;
      }
      saveProfile();
    } else {
      nextStep();
    }
  }

  Widget buildProgressHeader() {
    return Column(
      children: [
        Row(
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              return Expanded(
                child: Container(
                  height: 2,
                  color: index ~/ 2 < step ? Colors.teal : Colors.grey.shade300,
                ),
              );
            } else {
              int stepIndex = index ~/ 2;
              final isActive = stepIndex == step;
              final isCompleted = stepIndex < step;

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isActive || isCompleted
                          ? Colors.teal
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      steps[stepIndex]["icon"],
                      size: 18,
                      color: isActive || isCompleted
                          ? Colors.white
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[stepIndex]["label"],
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive || isCompleted
                          ? Colors.black
                          : Colors.grey,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }
          }),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.jpg'), // your background image
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Complete Your Profile",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.teal[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  buildProgressHeader(),
                  buildStepWidget(),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (step > 0)
                        TextButton(
                          onPressed: previousStep,
                          child: const Text("Back"),
                        ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: handleNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          step == steps.length - 1 ? "Finish" : "Next",
                          style: TextStyle(color: Color(0xFFFAFAFA)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
