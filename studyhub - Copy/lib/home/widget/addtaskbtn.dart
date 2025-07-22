import 'package:flutter/material.dart';
import 'package:studyhub/home/widget/category_selection.dart';

class AddTaskBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const AddTaskBottomSheet({super.key, required this.onSave});

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int? _selectedPriority;

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    setState(() {
      _selectedDate = picked;
    });
    }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _pickPriority() async {
    int? tempSelected = _selectedPriority;

    int? selected = await showDialog<int>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Task Priority'),
              content: Wrap(
                spacing: 10,
                children: List.generate(10, (index) {
                  int priority = index + 1;
                  return ChoiceChip(
                    label: Text('P$priority'),
                    selected: tempSelected == priority,
                    onSelected: (_) {
                      setState(() {
                        tempSelected = priority;
                      });
                    },
                  );
                }),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, tempSelected);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    setState(() {
      _selectedPriority = selected;
    });
    }

  void _saveTask() {
    if (_titleController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    final newTask = {
      'date': DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      ),
      'title': _titleController.text,
      'time': _selectedTime!.format(context),
      'tags': 'New',
      'tagColor': Colors.teal,
      'count': _selectedPriority ?? 1,
      'completed': false,
    };

    widget.onSave(newTask);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Task',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            /// 👉 Wrap instead of Row to fix overflow
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Pick Date'),
                  onPressed: _pickDate,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: const Text('Pick Time'),
                  onPressed: _pickTime,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.flag),
                  label: const Text('Priority'),
                  onPressed: _pickPriority,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.category),
                  label: const Text('Category'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => const CategorySelectionDialog(),
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),
            if (_selectedDate != null)
              Text(
                'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
              ),
            if (_selectedTime != null)
              Text('Time: ${_selectedTime!.format(context)}'),
            if (_selectedPriority != null)
              Text('Priority: P$_selectedPriority'),

            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
