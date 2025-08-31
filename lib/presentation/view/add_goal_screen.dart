import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/goal_provider.dart';
import '../widgets/primary_button.dart';


class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final goalProvider = Provider.of<GoalProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Goal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Goal Title',
                  hintText: 'Enter goal title',
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.text_fields, color: Theme.of(context).primaryColor),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30), // Rounded edges
                    borderSide: BorderSide.none, // Removes default border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.blue, width: 2), // Blue border when focused
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
                style: TextStyle(fontSize: 16),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Goal Description',
                  hintText: 'Enter goal details',
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.description, color: Theme.of(context).primaryColor),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30), // Rounded edges
                    borderSide: BorderSide.none, // Removes default border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.blue, width: 2), // Blue border when focused
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
                maxLines: 4,
                style: TextStyle(fontSize: 16),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 24),
              goalProvider.isLoading
                  ? CircularProgressIndicator()
                  : PrimaryButton(
                text: 'Add Goal',
                onPressed: () async {
                  if (_titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Title field is required!')),
                    );
                    return;
                  }

                  await goalProvider.addGoal(
                     _titleController.text.trim(),
                    _descriptionController.text.trim(),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
