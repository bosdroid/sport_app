import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/routes/routes_names.dart';
import '../providers/auth_provider.dart';
import '../providers/validation_provider.dart';
import '../widgets/password_text_field.dart';
import '../widgets/primary_button.dart';


class LoginScreen extends StatefulWidget {

  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin(BuildContext context, AuthProvider authProvider) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.emailEmptyError)));
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.passwordEmptyError)));
      return;
    }

    try {
      await authProvider.loginWithEmail(email, password);
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, RoutesNames.homeScreen);
    } catch (e) {
      final errorMsg = authProvider.getErrorMessage(e) ?? AppStrings.genericError;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final validationProvider = Provider.of<ValidationProvider>(context);

    return WillPopScope(
      onWillPop: () async{
        validationProvider.resetAll();
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppStrings.loginTitle,style: TextStyle(color: Theme.of(context).primaryColor,fontSize: 18,fontWeight: FontWeight.bold),),
                SizedBox(height: 16,),
                Consumer<ValidationProvider>(
                  builder: (context, validator, child) {
                    return TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: AppStrings.loginEmailLabel,
                        labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.email, color: Theme.of(context).primaryColor),
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
                        errorText: validator.emailError,
                      ),
                      style: TextStyle(fontSize: 16),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        validator.validateEmail(value); // optional: pass list for async check
                      },
                    );
                  },
                ),
                SizedBox(height: 16),
                PasswordTextField(controller: _passwordController,isValidate: false,), // Custom Password Field
                SizedBox(height: 20),
                authProvider.isLoading
                    ? CircularProgressIndicator()
                    :
                PrimaryButton(
                  onPressed: (_emailController.text.isNotEmpty && validationProvider.emailError == null)
                      && (_passwordController.text.isNotEmpty && validationProvider.passwordError == null) ? () => _handleLogin(context, authProvider)
                  :null,
                  text: AppStrings.loginWithEmail,
                ),
                SizedBox(height: 16),
                if (Platform.isAndroid)
                PrimaryButton(
                  onPressed: () async {
                    try {
                      await authProvider.loginWithGoogle();
                      if (!context.mounted) return;
                      Navigator.pushReplacementNamed(context,RoutesNames.homeScreen);
                    } catch (e) {
                      String error = authProvider.getErrorMessage(e);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    }
                  },
                  text: AppStrings.loginWithGoogle,
                ),
                if (Platform.isIOS)
                  PrimaryButton(
                    onPressed: () async {
                      try {
                        await authProvider.loginWithApple();

                        if (!context.mounted) return;

                        // Navigate to home if login succeeds
                        Navigator.pushReplacementNamed(context, RoutesNames.homeScreen);
                      } catch (e) {
                        // Use your improved error message handler
                        final error = authProvider.getAppleLoginErrorMessage(e);

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                      }
                    },
                    text: AppStrings.loginWithApple,
                  ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    validationProvider.resetAll();
                    Navigator.pushReplacementNamed(context, RoutesNames.signupScreen); // Navigate to SignupScreen
                  },
                  child: Text(
                    AppStrings.signupRedirect,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
