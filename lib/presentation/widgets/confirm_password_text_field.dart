
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../providers/validation_provider.dart';

class ConfirmPasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String password;

  const ConfirmPasswordTextField({super.key, required this.controller,required this.password});

  @override
  _ConfirmPasswordTextFieldState createState() => _ConfirmPasswordTextFieldState();
}

class _ConfirmPasswordTextFieldState extends State<ConfirmPasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<ValidationProvider>(
      builder: (context, validator, child) {
        return TextFormField(
          enabled: widget.password.isNotEmpty,
          controller: widget.controller,
          obscureText: _obscureText,
          onChanged: (value) => validator.validateConfirmPassword(widget.password,value),
          decoration: InputDecoration(
            labelText: AppStrings.confirmPasswordLabel,
            labelStyle: TextStyle(color: Colors.grey),
            prefixIcon: Icon(Icons.lock, color: Theme.of(context).primaryColor),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
            errorText: validator.confirmPasswordError,
          ),
          style: TextStyle(fontSize: 16),
        );
      },
    );
  }
}
