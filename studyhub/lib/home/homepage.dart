import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studyhub/features/subjectdetailpage.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    // Example subjects - later replace with Firestore data
    final List<String> subjects = [
      "Mathematics",
      "Science",
      "English",
      "History",
      "Geography",
      "Computer Science",
    ];

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: const Text(
          'My Subjects',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: subjects.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No subjects available',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Add functionality to add subjects
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      child: const Text(
                        'Add Subjects',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                itemCount: subjects.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3 / 2,
                ),
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Get.to(
                          () => SubjectPage(
                            subjectName: subject,
                            institutionId: 'dummy_id', // Replace with actual ID
                            semesterOrClassId:
                                'dummy_id', // Replace with actual ID
                            semesterOrClassName:
                                'General', // Replace with actual name
                            collectionName: 'general',
                            semesterId: '',
                            semesterName: '', // Replace with actual collection
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.teal.shade100, Colors.teal.shade50],
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              subject,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add functionality to add new subjects
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
