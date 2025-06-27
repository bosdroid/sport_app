import 'package:bjj_dairy/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/log_provider.dart';

class AddLogScreen extends StatefulWidget {
  const AddLogScreen({super.key});

  @override
  State<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends State<AddLogScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedType = 'Number Input';
  // final List<String> _logTypes = ['Number Input', 'Text Input', 'Toggle Yes/No', 'Time Tracker'];
  final List<String> _logTypes = ['Number Input', 'Text Input', 'Toggle Yes/No'];

  @override
  Widget build(BuildContext context) {
    final logProvider = Provider.of<LogProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Log')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Log Title',
                  hintText: 'Enter log title',
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
                  labelText: 'Log Description',
                  hintText: 'Enter log details',
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
              const SizedBox(height: 16),
              // Log Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: _logTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Log Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              logProvider.isLoading
                  ? CircularProgressIndicator()
                  :PrimaryButton(
                text: 'Add Log',
                onPressed: () async {
                  if (_titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Title field is required!')),
                    );
                    return;
                  }

                  await logProvider.addLog(
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim(),
                    type:_selectedType
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
