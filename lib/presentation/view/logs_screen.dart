
import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/routes/routes_names.dart';
import '../../core/utils.dart';
import '../../domain/entities/log.dart';
import '../providers/log_provider.dart';
import '../widgets/days_picker_dialog.dart';
import 'edit_log_screen.dart';

class LogsScreen extends StatefulWidget {

  const LogsScreen({super.key});
  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final bool hasGoals = false;
  DatePickerController controller = DatePickerController();
  DateTime? selectedCalendarDateTime;

  String formatTimestamp(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM d, y • h:mm a').format(dateTime);
  }

  @override
  void initState() {
    super.initState();
  }

  Future<List<int>> showDayPickerDialog(BuildContext context, List<int> selectedDays) async {
    List<int> tempSelectedDays = List.from(selectedDays);

    return await showDialog<List<int>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Active Days'),
          content: DaysPickerDialog(
            initialSelectedDays: selectedDays,
            onSelectionChanged: (newDays) {
              tempSelectedDays = newDays; // Update list based on selections
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, tempSelectedDays),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedDays),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    ) ?? selectedDays;
  }


  @override
  Widget build(BuildContext context) {
    final logProvider = Provider.of<LogProvider>(context, listen: true);

    final List<Log> activeLogs = logProvider.logs.where((log) => log.isActive).toList();
    final List<Log> inactiveLogs = logProvider.logs.where((log) => !log.isActive).toList();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: logProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : logProvider.logs.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Logs list is empty, Tap on plus icon to \n Get Started!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey
                  ),
                ),
              ),
            )
                : ListView(
              children: [
                if (activeLogs.isNotEmpty) ...[
                   Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Active Logs',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).primaryColor,fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...activeLogs.map((log) => logCard(logProvider, context, log)).toList(),
                ],
                if (inactiveLogs.isNotEmpty) ...[
                   Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Inactive Logs',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).primaryColor,fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...inactiveLogs.map((log) => logCard(logProvider, context, log)).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.pushNamed(context, RoutesNames.addLogScreen);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget logCard(LogProvider logProvider, BuildContext context, Log log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, RoutesNames.logHistoryScreen, arguments: {
              'log': log,
            });
          },
          child: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.star, color: Colors.white),
          ),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, RoutesNames.logHistoryScreen, arguments: {
              'log': log,
            });
          },
          child: Text(
            log.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        subtitle: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, RoutesNames.logHistoryScreen, arguments: {
              'log': log,
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                log.description,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                formatTimestamp(log.timestamp),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Switch(
                value: log.isActive,
                onChanged: (value) {
                  logProvider.updateLogStatus(log.id, value);
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    child: const Icon(Icons.edit, color: Colors.blue, size: 28),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditLogScreen(log: log),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    child: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor, size: 28),
                    onTap: () async {
                      final newDays = await showDayPickerDialog(context, log.days);
                      logProvider.updateLogDays(log.id, newDays);
                    },
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    child: const Icon(Icons.delete, color: Colors.red, size: 28),
                    onTap: () async {
                      bool confirm = await Util.showDeleteConfirmationDialog(context, "Log");
                      if (confirm) {
                        logProvider.deleteLog(log.id);
                      } else {
                        print("Deletion canceled");
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
