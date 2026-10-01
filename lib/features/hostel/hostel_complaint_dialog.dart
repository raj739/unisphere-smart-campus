import 'package:flutter/material.dart';

class HostelComplaintDialog extends StatefulWidget {
  const HostelComplaintDialog({super.key});

  @override
  State<HostelComplaintDialog> createState() => _HostelComplaintDialogState();
}

class _HostelComplaintDialogState extends State<HostelComplaintDialog> {
  final categoryController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    categoryController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Hostel Complaint'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop([
              categoryController.text.trim(),
              titleController.text.trim(),
              descriptionController.text.trim(),
            ]);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
