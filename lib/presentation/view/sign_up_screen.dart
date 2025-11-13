
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restart_app/restart_app.dart';

import '../../core/app_strings.dart';
import '../../core/routes/routes_names.dart';
import '../providers/auth_provider.dart';
import '../providers/validation_provider.dart';
import '../widgets/confirm_password_text_field.dart';
import '../widgets/password_text_field.dart';
import '../widgets/primary_button.dart';


class SignUpScreen extends StatefulWidget {

  SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _handleSignUp(BuildContext context, AuthProvider authProvider) async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final error = authProvider.validateUsernameInput(username);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.emailEmptyError)));
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.passwordEmptyError)));
      return;
    }

    try {
      await authProvider.signUpWithEmail(username, email, password);
      if (!context.mounted) return;
      // Restart.restartApp(notificationBody: 'Please wait...');
      Navigator.pushReplacementNamed(context, RoutesNames.homeScreen);
    } catch (e) {
      final errorMsg = authProvider.getErrorMessage(e) ?? AppStrings.somethingWentWrong;
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
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppStrings.signUpTitle,style: TextStyle(color: Theme.of(context).primaryColor,fontSize: 18,fontWeight: FontWeight.bold),),
                    SizedBox(height: 16,),
                    Consumer<ValidationProvider>(
                      builder: (context, validator, child) {
                        return TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: AppStrings.usernameLabel,
                            labelStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.text_fields, color: Theme.of(context).primaryColor),
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
                            errorText: validator.usernameError,
                          ),
                          style: TextStyle(fontSize: 16),
                          keyboardType: TextInputType.text,
                          onChanged: (value) {
                            validator.validateUsername(value); // Pass list of taken usernames
                          },
                        );
                      },
                    ),
                    SizedBox(height: 16,),
                    Consumer<ValidationProvider>(
                      builder: (context, validator, child) {
                        return TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: AppStrings.emailLabel,
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
                    PasswordTextField(controller: _passwordController), // Custom Password Field
                    SizedBox(height: 16),
                    ConfirmPasswordTextField(password:_passwordController.text,controller: _confirmPasswordController), // Custom Confirm Password Field
                    SizedBox(height: 20),
                    Consumer<ValidationProvider>(
                      builder: (context, validator, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: validator.agreeTermsError == null,
                                  onChanged: (value) {
                                    validator.validateAgreeTerms(value ?? false);
                                  },
                                ),
                                const Text(AppStrings.agreeTerms),
                              ],
                            ),
                            if (validator.agreeTermsError != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 12.0),
                                child: Text(
                                  validator.agreeTermsError!,
                                  style: TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    authProvider.isLoading
                        ? CircularProgressIndicator()
                        : PrimaryButton(
                      onPressed: (_usernameController.text.isNotEmpty && validationProvider.usernameError == null)
                          && (_emailController.text.isNotEmpty && validationProvider.emailError == null)
                          && (_passwordController.text.isNotEmpty && validationProvider.passwordError == null)
                          && (_confirmPasswordController.text.isNotEmpty && validationProvider.confirmPasswordError == null)
                          && validationProvider.agreeTermsError == null
                          ? () => _handleSignUp(context,authProvider)
                          : null,
                      text: AppStrings.signUpButton,
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        validationProvider.resetAll();
                        Navigator.pushReplacementNamed(context, RoutesNames.loginScreen); // Navigate to SignupScreen
                      },
                      child: Text(
                        AppStrings.loginRedirect,
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
        ),
      ),
    );
  }
}