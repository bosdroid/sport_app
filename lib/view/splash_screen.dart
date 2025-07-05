import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/routes/routes_names.dart';

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
    await Future.delayed(Duration(seconds: 2)); // Simulate loading
    if (authProvider.user != null) {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, RoutesNames.homeScreen);
    } else {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, RoutesNames.loginScreen);
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
