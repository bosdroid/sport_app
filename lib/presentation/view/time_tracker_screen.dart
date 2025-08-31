import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/log.dart';
import '../providers/log_provider.dart';



class TimeTrackerScreen extends StatefulWidget {
  final Log log;

  const TimeTrackerScreen({super.key, required this.log});

  @override
  State<TimeTrackerScreen> createState() => _TimeTrackerScreenState();
}

class _TimeTrackerScreenState extends State<TimeTrackerScreen> {
  bool _isTracking = false;
  Duration _elapsedTime = Duration.zero;
  late DateTime _startTime;
  late DateTime _endTime;

  void _startTimer() {
    setState(() {
      _isTracking = true;
      _startTime = DateTime.now();
    });
  }

  void _stopTimer(BuildContext context) {
    setState(() {
      _isTracking = false;
      _endTime = DateTime.now();
      _elapsedTime = _endTime.difference(_startTime);
    });

    // Save the time in Firebase using LogProvider
    final logProvider = Provider.of<LogProvider>(context, listen: false);
    logProvider.saveTimeLog(
      startTime: _startTime,
      endTime: _endTime,
      elapsedTime: _elapsedTime.inSeconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Time Tracker"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isTracking) ...[
              const Text("Timer Running..."),
              const SizedBox(height: 16),
              Text(
                "${_elapsedTime.inHours.toString().padLeft(2, '0')}:${(_elapsedTime.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}",
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _stopTimer(context),
                child: const Text("Stop Timer"),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _startTimer,
                child: const Text("Start Timer"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
