import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/validation_provider.dart';
import '../utils/app_strings.dart';

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final bool isValidate;

  const PasswordTextField({super.key, required this.controller,this.isValidate = true});

  @override
  _PasswordTextFieldState createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<ValidationProvider>(
      builder: (context, validator, child) {
        return TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          onChanged: (value){
            // if(widget.isValidate){
              validator.validatePassword(value,widget.isValidate);
            // }
            // else{
            //   validator.validatePassword(value);
            // }
          },
          decoration: InputDecoration(
            labelText: AppStrings.loginPasswordLabel,
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
            errorText: validator.passwordError,
          ),
          style: TextStyle(fontSize: 16),
        );
      },
    );
  }
}
