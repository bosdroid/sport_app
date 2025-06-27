import 'package:bjj_dairy/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../model/goal.dart';
import '../providers/goal_provider.dart';
import '../utils/routes/routes_names.dart';
import 'edit_goal_screen.dart';

class GoalsScreen extends StatefulWidget {

  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final bool hasGoals = false;

  @override
  void initState() {
    super.initState();
  }

  String formatTimestamp(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM d, y • h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = Provider.of<GoalProvider>(context,listen: true);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: goalProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : goalProvider.goals.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Goal list is empty, Tap on plus icon to \n Get Started!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                  fontSize: 16,
                    color: Colors.grey
                ),),
              )
            )
                : ListView.builder(
              itemCount: goalProvider.goals.length,
              itemBuilder: (context, index) {
                final Goal goal = goalProvider.goals[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.star, color: Colors.white),
                    ),
                    title: Text(
                      goal.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          goal.description,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatTimestamp(goal.timestamp),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Switch(
                            value: goal.isActive, // Bind this to the actual state of the goal.
                            onChanged: (value) {
                              goalProvider.updateGoalStatus(goal.id, value); // Add this method to update the goal status.
                            },
                          ),
                        ),
                        const SizedBox(height: 20,),
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                child: const Icon(Icons.edit, color: Colors.blue,size: 28,),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditGoalScreen(goal: goal),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16,),
                              GestureDetector(
                                child: const Icon(Icons.delete, color: Colors.red,size: 28,),
                                onTap: () async {
                                  bool confirm = await Util.showDeleteConfirmationDialog(context,"Goal");
                                  if (confirm) {
                                    goalProvider.deleteGoal(goal.id);
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
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, RoutesNames.addGoalScreen);
          },
          child: const Icon(Icons.add),),
    );
  }
}
