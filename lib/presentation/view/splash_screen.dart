import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routes/routes_names.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    _navigate(context);
    super.initState();
  }

  Future<void> _navigate(BuildContext context) async {
    if (!context.mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final loginType = prefs.getString('login_type');
    await Future.delayed(Duration(seconds: 2)); // Simulate loading
    if ((authProvider.user != null && loginType != 'guest')) {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, RoutesNames.homeScreen);
    } else {
      if (!context.mounted) return;
      // Navigator.pushReplacementNamed(context, RoutesNames.loginScreen);
      await authProvider.loginAsGuest();
      Navigator.pushReplacementNamed(context, RoutesNames.homeScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor, // Change as needed
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(Icons.task, size: 100, color: Colors.white), // Example icon
            Image.asset('assets/images/logo.png'),
            SizedBox(height: 20),
            Text(
              "DrillBox",
              style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
