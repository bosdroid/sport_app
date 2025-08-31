
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/goal.dart';
import '../providers/goal_provider.dart';
import '../widgets/primary_button.dart';


class EditGoalScreen extends StatefulWidget {
  final Goal goal;
  const EditGoalScreen({super.key,required this.goal});

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Goal? goal;

  @override
  void initState() {
    super.initState();
    goal = widget.goal;
    _titleController.text = goal!.title;
    _descriptionController.text = goal!.description;
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = Provider.of<GoalProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Update Goal')),
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
                text: 'Update Goal',
                onPressed: () async {
                  if (_titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Title field is required!')),
                    );
                    return;
                  }
                  Goal updateGaol = Goal(id: goal!.id, title: _titleController.text, description: _descriptionController.text,
                      timestamp: goal!.timestamp,isActive: goal!.isActive);
                  await goalProvider.updateGoal(
                      updateGaol
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
