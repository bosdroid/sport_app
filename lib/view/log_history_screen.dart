import 'package:bjj_dairy/model/log_history.dart';
import 'package:bjj_dairy/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/daily_log_display_item.dart';
import '../model/log.dart';
import '../providers/log_provider.dart';

class LogHistoryScreen extends StatefulWidget {
  final Log log;
  const LogHistoryScreen({super.key,required this.log});

  @override
  State<LogHistoryScreen> createState() => _LogHistoryScreenState();
}

class _LogHistoryScreenState extends State<LogHistoryScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LogProvider>(context, listen: false).fetchLogHistory(widget.log);
    });
  }

  @override
  Widget build(BuildContext context) {
    final logProvider = Provider.of<LogProvider>(context,listen: true);
    return Scaffold(
      appBar: AppBar(
          iconTheme: IconThemeData().copyWith(color: Colors.white),
          backgroundColor:Theme.of(context).primaryColor ,title: Text('Log History',style: TextStyle(
        color: Colors.white
      ),)),
      body: Column(children: [
        Expanded(child:
      logProvider.isLoading
      ? const Center(child: CircularProgressIndicator())
        :
        Consumer<LogProvider>(
          builder: (context, logProvider, child) {
            if (logProvider.logsHistory.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('No logs history available.'),
              );
            }
            return
              ListView.builder(
                itemCount: logProvider.logsHistory.length,
                itemBuilder: (context, index) {
                  final LogHistory logHistory = logProvider.logsHistory[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8),
                        title: () {
                          if (widget.log.type == 'Text Input') {
                            return Text(
                              logHistory.value.toString().isEmpty ? 'N/A' : logHistory.value.toString(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            );
                          } else if (widget.log.type == 'Number Input') {
                            return Text(
                              logHistory.value.toString().isEmpty ? '0' : logHistory.value.toString(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            );
                          } else if (widget.log.type == 'Toggle Yes/No') {
                            return Text(
                              logHistory.value.toString().isEmpty ? 'No' : logHistory.value ? 'Yes' : 'No',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: (logHistory.value.toString().isNotEmpty && logHistory.value)
                                  ? Colors.green
                                  : Colors.red,),
                            );
                          } else {
                            return const SizedBox.shrink(); // Fallback for unsupported types
                          }
                        }(),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Util.formatDate(logHistory.timestamp),
                            maxLines: 1,
                          ),
                        ],
                      ),
                      trailing: Builder(
                        builder: (context) {
                          switch (logHistory.type.isEmpty ? widget.log.type : logHistory.type) {
                            case 'Number Input':
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {

                                      logProvider.updateHistoryNumberLog(
                                         widget.log,
                                          logHistory.historyId,
                                          logHistory.timestamp,
                                          logHistory.value.toString().isNotEmpty && logHistory.value.toString() != '0' ? int.parse(logHistory.value.toString()) -
                                              1:0); // Example function to decrease the number.
                                    },
                                  ),
                                  Text(
                                    '${logHistory.value.toString().isNotEmpty
                                        ? logHistory.value
                                        : 0}',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      logProvider.updateHistoryNumberLog(
                                          widget.log,
                                          logHistory.historyId,
                                          logHistory.timestamp,
                                          logHistory.value.toString().isNotEmpty ? int.parse(logHistory.value.toString()) +
                                              1:1); // Example function to increase the number.
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
                                          text: logHistory.value);
                                      return AlertDialog(
                                        title: const Text('Edit Log History'),
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
                                              logProvider.updateHistoryTextLog(
                                                  widget.log,
                                                  logHistory.historyId,
                                                  logHistory.timestamp,
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
                                          value: logHistory.value.toString().isEmpty ? 'No': logHistory.value ? 'Yes' : 'No',
                                          onChanged: (String? newValue) {
                                            if (newValue != null) {
                                              bool toggle = newValue == 'Yes';
                                              logProvider.updateHistoryToggleLog(widget.log,logHistory.historyId,logHistory.timestamp,toggle);
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
                                  // logProvider.navigateToTimeTracker(
                                  //     context, logHistory);
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
              );
          },
        ))
      ],),
    );
  }
}