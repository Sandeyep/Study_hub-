import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CalenderPage extends StatefulWidget {
  final List<Map<String, dynamic>> allTasks;

  const CalenderPage({super.key, required this.allTasks});

  @override
  State<CalenderPage> createState() => CalenderPageState();
}

class CalenderPageState extends State<CalenderPage> {
  DateTime selectedDate = DateTime.now();
  bool showCompleted = false;

  late List<Map<String, dynamic>> _tasks;
  String? profileImageUrl; // <-- add state for profile image URL

  @override
  void initState() {
    super.initState();
    _tasks = List<Map<String, dynamic>>.from(widget.allTasks);
    _fetchUserProfileImage();
  }

  Future<void> _fetchUserProfileImage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          profileImageUrl = data?['profileImage'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile image: $e');
    }
  }

  void _toggleTaskComplete(Map<String, dynamic> task) {
    setState(() {
      task['completed'] = !(task['completed'] ?? false);
    });
  }

  void addNewTask(Map<String, dynamic> newTask) {
    setState(() {
      if (!newTask.containsKey('completed')) {
        newTask['completed'] = false;
      }
      _tasks.add(newTask);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksForView = _tasks.where((task) {
      final taskDate = task['date'] as DateTime?;
      if (taskDate == null) return false;

      final sameDate =
          taskDate.year == selectedDate.year &&
          taskDate.month == selectedDate.month &&
          taskDate.day == selectedDate.day;

      final isCompleted = task['completed'] ?? false;
      return sameDate && (showCompleted ? isCompleted : !isCompleted);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SvgPicture.asset(
            'assets/nav/mk.svg',
            width: 24.w,
            height: 24.h,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 24.r,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  profileImageUrl != null && profileImageUrl!.isNotEmpty
                  ? NetworkImage(profileImageUrl!)
                  : null,
              child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                  ? Image.asset('images/anu.jpg', height: 44.h, width: 44.w)
                  : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: EasyDateTimeLine(
              initialDate: selectedDate,
              onDateChange: (date) {
                setState(() {
                  selectedDate = date;
                });
              },
              activeColor: Colors.teal,
              dayProps: const EasyDayProps(
                height: 70,
                width: 60,
                dayStructure: DayStructure.dayStrDayNum,
              ),
              headerProps: const EasyHeaderProps(showHeader: false),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showCompleted = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: showCompleted
                          ? Colors.grey
                          : const Color.fromARGB(255, 174, 147, 221),
                    ),
                    child: const Text('Today'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showCompleted = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: showCompleted
                          ? const Color.fromARGB(255, 174, 147, 221)
                          : Colors.grey,
                    ),
                    child: const Text('Completed'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasksForView.isEmpty
                ? const Center(
                    child: Text(
                      'No tasks for this day.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: tasksForView.length,
                    itemBuilder: (context, index) {
                      final task = tasksForView[index];

                      return Card(
                        color: Colors.teal[900],
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: IconButton(
                            icon: Icon(
                              task['completed'] ?? false
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: Colors.teal,
                            ),
                            onPressed: () => _toggleTaskComplete(task),
                          ),
                          title: Text(
                            task['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task['time'] ?? '',
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              if (task['tags'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        task['tagColor'] ?? Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    task['tags'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
