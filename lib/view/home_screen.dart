import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:bjj_dairy/utils/utils.dart';
import 'package:bjj_dairy/view/plans_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rating_dialog/rating_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../utils/app_analytics.dart';
import '../utils/app_usage_tracker.dart';
import '../utils/routes/routes_names.dart';
import 'board_screen.dart';
import 'goals_screen.dart';
import 'logs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final NotificationService _notificationService = NotificationService();
  final List<Widget> _screens = [
    // BoardScreen(),
    // LogsScreen(),
    // GoalsScreen(),
    PlansScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0; // Navigate back to the "BoardScreen"
      });
      return false; // Prevent exiting the app
    }
    return true; // Allow exiting the app if already on the "BoardScreen"
  }


  Future<void> _selectDateTimeAndScheduleReminder(BuildContext context) async {
    // Select Date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    // Select Time
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    // Combine date and time
    final scheduledDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    NotificationService.scheduleNotification(
      scheduledDateTime: scheduledDateTime,
      title: 'Reminder',
      body: 'This is your scheduled reminder!',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder set for $scheduledDateTime')),
    );
  }

  @override
  void initState() {
    super.initState();
    AppAnalytics.logAppOpen();
    checkAppUsage();
  }

  Future<void> checkAppUsage()async {
    int openCount = await AppUsageTracker.incrementAndGetOpenCount();
    if (openCount >= 5) { // Replace 5 with your threshold
      AppAnalytics.logFeedbackPopupShown();
      Future.delayed(Duration.zero, () {
        //_showFeedbackDialog(context);
        Util.showFeedbackDialog(
          context,
          onSubmit: (rating, feedback) async {
            print('Rating: $rating');
            print('Feedback: $feedback');
            if (rating >= 4.0) {
              // Redirect to Play Store
              const url = 'https://play.google.com/store/apps/details?id=com.bjjdairy.app';
              if (await canLaunchUrl(Uri.parse(url))) {
            AppUsageTracker.resetOpenCount();
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            }
            } else {
            // // Send to Firebase
            // await FirebaseFirestore.instance.collection('user_feedbacks').add({
            //   'rating': rating,
            //   'feedback': feedback,
            //   'timestamp': DateTime.now(),
            // });

            // Optional: Send via email (not recommended unless necessary)
            if(feedback.isNotEmpty) {
            AppAnalytics.logFeedbackSubmitted(feedback);
            AppUsageTracker.resetOpenCount();
            // await launchUrl(Uri.parse("mailto:boris.ruzanov@gmail.com?subject=App Feedback&body=$feedback"));
              await FirebaseDatabase.instance.ref().child('USER_FEEDBACKS').set({
                'rating': rating,
                'feedback': feedback,
                'timestamp': DateTime.now(),
              });
            }
            }
          },
          onClose: () {
            print('Dialog closed');
            AppUsageTracker.resetOpenCount();
          },
          onNotNow: () {
            print('Not now clicked');
            AppUsageTracker.resetOpenCount();
          },
        );
      });
    }
  }

  void _showFeedbackDialog(BuildContext context) {
    final dialog = RatingDialog(
      title: Text('Rate Our App',textAlign: TextAlign.center,),
      // message: Text('Tap a star to rate.'),
      image: Icon(Icons.star, size: 40, color: Colors.amber),
      submitButtonText: 'Submit',
      onCancelled: () {
        AppUsageTracker.resetOpenCount();
      },
      onSubmitted: (response) async {
        final rating = response.rating;
        final feedback = response.comment;

        if (rating >= 4.0) {
          // Redirect to Play Store
          const url = 'https://play.google.com/store/apps/details?id=com.bjjdairy.app';
          if (await canLaunchUrl(Uri.parse(url))) {
            AppUsageTracker.resetOpenCount();
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          }
        } else {
          // // Send to Firebase
          // await FirebaseFirestore.instance.collection('user_feedbacks').add({
          //   'rating': rating,
          //   'feedback': feedback,
          //   'timestamp': DateTime.now(),
          // });

          // Optional: Send via email (not recommended unless necessary)
          if(feedback.isNotEmpty) {
            AppAnalytics.logFeedbackSubmitted(feedback);
            AppUsageTracker.resetOpenCount();
            await launchUrl(Uri.parse("mailto:boris.ruzanov@gmail.com?subject=App Feedback&body=$feedback"));
          }
        }
      },
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => dialog,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
          // appBar: AppBar(
          //   backgroundColor: Theme.of(context).primaryColor,
          //   title: Text('BJJ fans club',style: TextStyle(color: Colors.white),),
          //   actions: [
          //     // IconButton(
          //     //   onPressed: () async {
          //     //     if (!context.mounted) return;
          //     //     Navigator.pushNamed(context, RoutesNames.voiceInputScreen);
          //     //   },
          //     //   icon: Icon(Icons.mic,color: Colors.white,),
          //     // ),
          //     // IconButton(
          //     //   onPressed: ()=>_selectDateTimeAndScheduleReminder(context),
          //     //   icon: Icon(Icons.timer,color: Colors.white,),
          //     // ),
          //     IconButton(
          //       onPressed: () async {
          //         await authProvider.logout();
          //         if (!context.mounted) return;
          //         Navigator.pushReplacementNamed(context, RoutesNames.loginScreen);
          //       },
          //       icon: Icon(Icons.logout,color: Colors.white,),
          //     ),
          //   ],
          // ),
          body: _screens[_selectedIndex],
          // bottomNavigationBar: BottomNavigationBar(
          //   currentIndex: _selectedIndex,
          //   onTap: _onItemTapped,
          //   type: BottomNavigationBarType.fixed, // For more than 3 items
          //   backgroundColor: Colors.white, // Change as per your design
          //   selectedItemColor: Theme.of(context).primaryColor, // Active icon color
          //   unselectedItemColor: Colors.grey, // Inactive icon color
          //   showUnselectedLabels: true, // Show text for inactive items
          //   selectedFontSize: 14,
          //   unselectedFontSize: 12,
          //   elevation: 10, // Shadow effect
          //   items: [
          //     BottomNavigationBarItem(
          //       icon: Icon(Icons.dashboard),
          //       label: 'Board',
          //     ),
          //     BottomNavigationBarItem(
          //       icon: Icon(Icons.calendar_today),
          //       label: 'Logs',
          //     ),
          //     BottomNavigationBarItem(
          //       icon: Icon(Icons.flag),
          //       label: 'Goals',
          //     ),
          //     BottomNavigationBarItem(
          //       icon: Icon(Icons.event_note),
          //       label: 'Plan',
          //     ),
          //   ],
          // ),
        ),
      ),
    );
  }
}
