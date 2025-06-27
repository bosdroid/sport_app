import 'package:bjj_dairy/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/log.dart';
import '../providers/log_provider.dart';

class EditLogScreen extends StatefulWidget {
  final Log log;
  const EditLogScreen({super.key,required this.log});

  @override
  State<EditLogScreen> createState() => _EditLogScreenState();
}

class _EditLogScreenState extends State<EditLogScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedType = 'Number Input';
  final List<String> _logTypes = ['Number Input', 'Text Input', 'Toggle Yes/No', 'Time Tracker'];
  Log? log;
  @override
  void initState() {
    super.initState();
    log = widget.log;
    _titleController.text = log!.title;
    _descriptionController.text = log!.description;
    _selectedType = log!.type;
  }

  @override
  Widget build(BuildContext context) {
    final logProvider = Provider.of<LogProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Update Log')),
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
                text: 'Update Log',
                onPressed: () async {
                  if (_titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Title field is required!')),
                    );
                    return;
                  }
                  Log updateLog = Log(id: log!.id, title: _titleController.text, description: _descriptionController.text,
                      type: _selectedType, timestamp: log!.timestamp,isActive: log!.isActive,resetTimestamp: log!.resetTimestamp);
                  await logProvider.updateLog(
                      updateLog
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
