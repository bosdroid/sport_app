import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/validation_provider.dart';

class TitleInputField extends StatelessWidget {
  final TextEditingController controller;

  const TitleInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Row with Icon and Title*
        Row(
          children: [
            Icon(Icons.person_outline, size: 16, color: Theme.of(context).primaryColor),
            const SizedBox(width: 4),
            const Text(
              'Title',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 2),
            const Text(
              '*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Text Field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade300,
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Consumer<ValidationProvider>(
            builder: (context, validationProvider, child) {
              return TextFormField(
                controller: controller,
                onChanged: (value) {
                  validationProvider.validateTitle(value);
                },
                decoration: InputDecoration(
                  hintText: 'e.g., Armbar from Closed Guard',
                  border: InputBorder.none,
                  // filled: true,
                  // fillColor: Colors.grey[200],
                  // border: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(30),
                  //   borderSide: BorderSide.none,
                  // ),
                  // focusedBorder: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(30),
                  //   borderSide: BorderSide(color: Colors.blue, width: 2),
                  // ),
                  errorText: validationProvider.titleError,
                  errorBorder: OutlineInputBorder(
                    // borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    // borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              );
            },
          ),
          // TextFormField(
          //   controller: controller,
          //   decoration: InputDecoration(
          //     hintText: 'e.g., Armbar from Closed Guard',
          //     border: InputBorder.none,
          //     errorBorder: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(30),
          //       borderSide: BorderSide(color: Colors.red),
          //     ),
          //     focusedErrorBorder: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(30),
          //       borderSide: BorderSide(color: Colors.red, width: 2),
          //     ),
          //   ),
          // ),
        ),
      ],
    );
  }
}
