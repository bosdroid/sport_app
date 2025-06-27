import 'package:bjj_dairy/providers/goal_provider.dart';
import 'package:bjj_dairy/providers/note_provider.dart';
import 'package:bjj_dairy/widgets/primary_button.dart';
import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../model/goal.dart';
import '../model/log.dart';
import '../model/meeting.dart';
import '../providers/log_provider.dart';
import '../widgets/note_dailog.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  bool _isLogsExpanded = true; // Initially expanded
  bool _isGoalsExpanded = true; // Initially expanded
  CalendarController? calendarController;
  List<Meeting> meetings = <Meeting>[];
  DatePickerController controller = DatePickerController();
  DateTime? selectedCalendarDateTime;
  bool achieved = false;
  Goal? changeGaolItem;

  @override
  void initState() {
    super.initState();
    selectedCalendarDateTime = DateTime.now();
    Future.delayed(const Duration(milliseconds: 500), () {
      controller.animateToSelection();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<GoalProvider>(context, listen: false).fetchGoals();
      await Provider.of<LogProvider>(context, listen: false).fetchLogs();
      Provider.of<NoteProvider>(context, listen: false).fetchTodayNote(null);
      Provider.of<LogProvider>(context, listen: false).getActiveLogsForDate(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    GoalProvider goalProvider = Provider.of<GoalProvider>(context, listen: true);
    LogProvider logProvider = Provider.of<LogProvider>(context, listen: true);
    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child:
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              // padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.only(bottom: 8),
              child: DatePicker(
                DateTime.now().subtract(const Duration(days: 60)),
                controller: controller,
                initialSelectedDate: DateTime.now(),
                selectionColor: Theme.of(context).primaryColor,
                selectedTextColor: Colors.white,
                onDateChange: (DateTime date) {
                  setState(() {
                    selectedCalendarDateTime = date;
                  });
                  Provider.of<NoteProvider>(context, listen: false).fetchTodayNote(selectedCalendarDateTime);
                  Provider.of<LogProvider>(context, listen: false).getActiveLogsForDate(selectedCalendarDateTime);
                },
              ),
            ),
            // Logs Section in BoardScreen
            SizedBox(
              height: _isLogsExpanded && logProvider.totalActiveLogs >= 2 ? 300 : _isLogsExpanded && logProvider.totalActiveLogs == 1  ? 190 : null,
              child:
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context)
                                .primaryColor, // Set the border color
                            width: 1.0, // Thickness of the border
                          ),
                        ),
                      ),
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Goals Heading
                          Text(
                            'LOGS',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).primaryColor,fontWeight: FontWeight.bold),
                          ),

                          // Save and Cancel Buttons
                          if (logProvider.anyLogChanges)
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    logProvider.resetChanges();
                                  },
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                                logProvider.isLoading ? CircularProgressIndicator() :
                                PrimaryButton(
                                  width: 80,
                                  height: 40,
                                  onPressed: () {
                                    logProvider.updateAllLogChanges();
                                  },
                                  text: 'Save',
                                ),
                              ],
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              _isLogsExpanded ? Icons.expand_less : Icons.expand_more,
                              size: 36,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _isLogsExpanded = !_isLogsExpanded;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isLogsExpanded)
                  Consumer<LogProvider>(
                    builder: (context, logProvider, child) {
                      if (logProvider.activeLogs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('No logs available.'),
                        );
                      }
                      return
                        Expanded(child:
                          ListView.builder(
                        itemCount: logProvider.activeLogs.length,
                        itemBuilder: (context, index) {
                          final Log log = logProvider.activeLogs[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8),
                              title: Text(
                                log.title,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.description,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    log.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                        color: log.isActive
                                            ? Colors.green
                                            : Colors.red),
                                  ),
                                ],
                              ),
                              trailing: Builder(
                                builder: (context) {
                                  switch (log.type) {
                                    case 'Number Input':
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: () {
                                              log.changes = true;
                                              logProvider.updateNumberLog(
                                                  log.id,
                                                  log.number -
                                                      1); // Example function to decrease the number.
                                            },
                                          ),
                                          Text(
                                            log.number != null
                                                ? log.number.toString()
                                                : '0',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () {
                                              log.changes = true;
                                              logProvider.updateNumberLog(
                                                  log.id,
                                                  log.number +
                                                      1); // Example function to increase the number.
                                            },
                                          ),
                                        ],
                                      );

                                    case 'Text Input':
                                      return IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              TextEditingController
                                                  textController =
                                                  TextEditingController(
                                                      text: log.text);
                                              return AlertDialog(
                                                title: const Text('Edit Log'),
                                                content: TextField(
                                                  controller: textController,
                                                  decoration:
                                                      const InputDecoration(
                                                          labelText:
                                                              'Enter text'),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      log.changes = true;
                                                      logProvider.updateTextLog(
                                                          log.id,
                                                          textController
                                                              .text); // Example function to update text.
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text('Save'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text('Cancel'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );

                                    case 'Toggle Yes/No':
                                      return Column(
                                        mainAxisAlignment:MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              decoration: BoxDecoration(
                                                  border:
                                                  Border.all(width: 1, color: Colors.black)),
                                              child: DropdownButton<String>(
                                                value: log.toggle ? 'Yes' : 'No',
                                                onChanged: (String? newValue) {
                                                  if (newValue != null) {
                                                   bool toggle = newValue == 'Yes';
                                                    log.toggle = toggle;
                                                    log.changes = true;
                                                    logProvider.updateLogData(log);
                                                    // logProvider.updateToggleLog(log.id,toggle);
                                                  }
                                                },
                                                items: [
                                                  'Yes',
                                                  'No'
                                                ].map<DropdownMenuItem<String>>((String value) {
                                                  return DropdownMenuItem<String>(
                                                    value: value,
                                                    child: Text(
                                                      value,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: value == 'Yes'
                                                            ? Colors.green
                                                            : Colors.red,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            )
                                          ),
                                        ],
                                      );

                                    case 'Time Tracker':
                                      return IconButton(
                                        icon: const Icon(Icons.timer),
                                        onPressed: () {
                                          logProvider.navigateToTimeTracker(
                                              context, log);
                                        },
                                      );

                                    default:
                                      return const SizedBox
                                          .shrink(); // Fallback for unknown types.
                                  }
                                },
                              ),
                            ),
                          );
                        },
                          )
                      );
                    },
                  ),
                ],
              ),
            ),
            // Goals Section in BoardScreen
            SizedBox(
                height: _isGoalsExpanded && goalProvider.totalActiveGoals >= 2 ? 300 : _isGoalsExpanded && goalProvider.totalActiveGoals == 1  ? 190 : null,
                child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 1.0,
                        ),
                      ),
                    ),
                    child:
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Goals Heading
                        Text(
                          'GOALS',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).primaryColor,fontWeight: FontWeight.bold),
                        ),
                        // Save and Cancel Buttons
                        if (goalProvider.anyGoalChanges)
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  goalProvider.resetChanges();
                                },
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              goalProvider.isLoading ? CircularProgressIndicator() :
                              PrimaryButton(
                                width: 80,
                                height: 40,
                                onPressed: () {
                                  goalProvider.updateAllGoalChanges();
                                },
                                text: 'Save',
                              ),
                            ],
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            _isGoalsExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 36,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _isGoalsExpanded = !_isGoalsExpanded;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isGoalsExpanded)
                Consumer<GoalProvider>(
                  builder: (context, goalProvider, child) {
                    if (goalProvider.activeGoals.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('No goals available.'),
                      );
                    }
                    return Expanded(
                      child: ListView.builder(
                        itemCount: goalProvider.activeGoals.length,
                        itemBuilder: (context, index) {
                          final Goal goal = goalProvider.activeGoals[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8),
                              title: Text(
                                goal.title,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(goal.description),
                                  const SizedBox(height: 4),
                                  Text(
                                    goal.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                        color: goal.isActive
                                            ? Colors.green
                                            : Colors.red),
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                    border:
                                        Border.all(width: 1, color: Colors.black)),
                                child: DropdownButton<String>(
                                  value: goal.achieved ? 'Yes' : 'No',
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                           achieved = newValue == 'Yes';
                                           goal.achieved = achieved;
                                           goal.changes = true;
                                      goalProvider.updateGoalData(goal);
                                    }
                                  },
                                  items: [
                                    'Yes',
                                    'No'
                                  ].map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: value == 'Yes'
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            )),
            // Notes Section in BoardScreen
            Container(
              margin: const EdgeInsets.only(bottom: 60),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).primaryColor, // Set the border color
                            width: 1.0, // Thickness of the border
                          ),
                        ),
                      ),
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Goals Heading
                          Text(
                            'TODAY NOTE',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Consumer<NoteProvider>(
                    builder: (context, noteProvider, child) {
                      if (noteProvider.todayNote.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('No note available for today.'),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SizedBox(
                            height: 200, // Fixed height
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(noteProvider.todayNote,textAlign: TextAlign.start,
                                    style: TextStyle(
                                      height: 1.6,
                                      letterSpacing: 0.5,
                                    )),
                                  ),
                                ),

                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context) => NoteDialog(
                                      initialNote: noteProvider.todayNote,
                                      onSave: (newNote) {
                                        noteProvider.addNote(newNote); // Save the note
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        floatingActionButton: FloatingActionButton.small(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          onPressed: () => showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) => NoteDialog(
              initialNote: Provider.of<NoteProvider>(context, listen: false).todayNote,
              onSave: (newNote) {
                Provider.of<NoteProvider>(context, listen: false).addNote(newNote); // Save the note
              },
            ),
          ),
          child: const Icon(Icons.add),)
    );
  }
}
