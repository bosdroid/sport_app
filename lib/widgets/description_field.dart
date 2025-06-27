import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/validation_provider.dart';

class DescriptionField extends StatefulWidget {
  final String initialDescription;
  final ValueChanged<String> onChanged;

  const DescriptionField({
    super.key,
    required this.initialDescription,
    required this.onChanged,
  });

  @override
  _DescriptionFieldState createState() => _DescriptionFieldState();
}

class _DescriptionFieldState extends State<DescriptionField> {
  late TextEditingController _descriptionController;
  int _maxLines = 3;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _updateMaxLines();
    _descriptionController.addListener(_updateMaxLines);
    _descriptionController.addListener(_onTextChanged);
  }

  void _updateMaxLines() {
    setState(() {
      _maxLines = _descriptionController.text.isEmpty ? 3 : 5;
    });
  }

  void _onTextChanged() {
    widget.onChanged(_descriptionController.text);
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_updateMaxLines);
    _descriptionController.removeListener(_onTextChanged);
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with icon
        Row(
          children:  [
            Icon(Icons.filter_list, size: 16, color: Theme.of(context).primaryColor),
            SizedBox(width: 4),
            Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '(optional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Input field
        Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade300,
            border: Border.all(color: Colors.grey.shade100),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Consumer<ValidationProvider>(
            builder: (context, validator, child) {
              return TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Describe setup, mechanics, or details of this move...',
                  border: InputBorder.none,
                  errorText: validator.descriptionError,
                  errorBorder: OutlineInputBorder(
                    // borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    // borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                maxLines: _maxLines,
                style: const TextStyle(fontSize: 16),
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onChanged: (value) {
                  validator.validateDescription(value); // Update validation
                },
              );
            },
          ),
          // TextFormField(
          //   controller: _descriptionController,
          //   decoration: const InputDecoration(
          //     hintText: 'Describe setup, mechanics, or details of this move...',
          //     border: InputBorder.none,
          //   ),
          //   maxLines: _maxLines,
          //   style: const TextStyle(fontSize: 16),
          //   keyboardType: TextInputType.multiline,
          //   textInputAction: TextInputAction.newline,
          // ),
        ),
      ],
    );
  }
}
