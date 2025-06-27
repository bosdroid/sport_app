import 'dart:convert';

import 'package:bjj_dairy/providers/goal_provider.dart';
import 'package:bjj_dairy/providers/log_provider.dart';
import 'package:bjj_dairy/providers/note_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AiAnalyzerProvider with ChangeNotifier{
  final DatabaseReference _promptRef = FirebaseDatabase.instance.ref().child('AI_PROMPT/');
  final DatabaseReference _notesRef = FirebaseDatabase.instance.ref().child('NOTES/');
  bool _isLoading = false;
  String _aiResponse = "";

  bool get isLoading => _isLoading;
  String get aiResponse => _aiResponse;

  Map<String, String?> logs = {};
  Map<String, String?> goals = {};
  List<String> notes = [];

  void resetResponse(){
    _aiResponse = "";
    notifyListeners();
  }

  Future<String> fetchPrompt() async {
    final promptSnapshot = await _promptRef.child('prompt').get();
    return promptSnapshot.exists ? promptSnapshot.value.toString() : "";
  }

  Future<void>  analyzeText(String audioText,BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    String prompt = await fetchPrompt();

    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;

    List<String> goalsList = Provider.of<GoalProvider>(context, listen: false).activeGoals.map((g) => g.title).toList();
    List<String> logsList = Provider.of<LogProvider>(context, listen: false).activeLogs.map((l) => l.title).toList();
    // List<String> notesList = await fetchUserNotes(userId);
    String note = Provider.of<NoteProvider>(context,listen: false).todayNote;

    String finalPrompt = "$prompt\n"
        "Here is my list of goals: ${goalsList.join(', ')}\n"
        "Here is my list of logs: ${logsList.join(', ')}\n"
        "Audio Text: $audioText\n"
        "I need just json result for getting values for update in logs, goals and notes. no other text. keep the same pattern always. and don't consider logs as goals if goal list is empty";
    // Send to AI (Mock API call)
    final response = await sendToAI(finalPrompt);
    var result = response["choices"][0]["message"]["content"];
     _aiResponse = parseAiResult(result,context);
     print(_aiResponse);
    _isLoading = false;
    notifyListeners();
  }

  String parseAiResult(String result,BuildContext context){
    Map<String, dynamic> jsonMap = jsonDecode(result);
    String response;
    // Process Logs
    if (jsonMap.containsKey("Logs")) {
      jsonMap["Logs"].forEach((key, value) {
        logs[key] = value?.toString(); // Convert null to nullable String
      });
    }

    // Process Goals
    if (jsonMap.containsKey("Goals")) {
      jsonMap["Goals"].forEach((key, value) {
        goals[key] = value?.toString(); // Convert null to nullable String
      });
    }

    // Process Notes
    if (jsonMap.containsKey("Notes")) {
      notes = List<String>.from(jsonMap["Notes"]);
    }

    // Printing Key-Value Pairs
    if (kDebugMode) {
      print("Logs:");
    }
    logs.forEach((key, value) {
      // if (kDebugMode) {
      //   print("$key: ${value ?? 'Not provided'}");
      // }
      if(value != null && value.toString().isNotEmpty){
        Provider.of<LogProvider>(context, listen: false).updateLogDataWithAi(key, value);
      }
    });

    if (kDebugMode) {
      print("\nGoals:");
    }
    goals.forEach((key, value) {
      // if (kDebugMode) {
      //   print("$key: ${value ?? 'Not provided'}");
      // }
      if(value != null && value.toString().isNotEmpty){
        Provider.of<GoalProvider>(context, listen: false).updateGoalStatusWithAi(key, value);
      }
    });

    if (kDebugMode) {
      print("\nNotes:");
    }
    if(notes.isNotEmpty){
      Provider.of<NoteProvider>(context, listen: false).addNote(notes.join(","));
    }
    // for (var note in notes) {
    //   if (kDebugMode) {
    //     print(note);
    //   }
    // }
    showCustomDialog(result,context);
     // Navigator.of(context).pop();
     return "";
  }

  void showCustomDialog(String response,BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('AI Response'),
          content: Text(response),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> sendToAI(String finalPrompt) async {
    const String apiUrl = "https://api.openai.com/v1/chat/completions"; // Replace with actual AI endpoint
    const String apiKey = ""; // Replace with API Key if needed

    final Map<String, dynamic> requestBody = {
      "model": "gpt-4",
      "messages": [
        {"role": "system", "content": "You are an AI assistant that categorizes audio into goals, logs, and notes."},
        {"role": "user", "content": finalPrompt}
      ],
      "temperature": 0.7,
      "max_tokens": 500,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to fetch AI response: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error sending to AI: $e");
    }
  }

  Future<List<String>> fetchUserNotes(String userId) async {
    final userNotesRef = _notesRef.child(userId);
    final snapshot = await userNotesRef.get();

    List<String> notes = [];

    if (snapshot.exists) {
      for (var dateSnapshot in snapshot.children) {
        for (var noteSnapshot in dateSnapshot.children) {
          if(noteSnapshot.key == 'note'){
            notes.add(noteSnapshot.value.toString());
          }
        }
      }
    }
    return notes;
  }

  void updateValuesFromAI(Map<String, dynamic> aiResponse) {
    Map<String, dynamic> goalsData = aiResponse['goals'];
    Map<String, dynamic> logsData = aiResponse['logs'];
    List<String> notesData = aiResponse['notes'];

    for (var goal in GoalProvider().activeGoals) {
      if (goalsData.containsKey(goal.title)) {
        goal.achieved = goalsData[goal.title] == "achieved";
        goal.changes = true;
      }
    }

    for (var log in LogProvider().activeLogs) {
      if (logsData.containsKey(log.title)) {
        var value = logsData[log.title];
        if (log.type == "number") log.number = int.parse(value);
        if (log.type == "text") log.text = value;
        if (log.type == "toggle") log.toggle = value == "true";
        log.changes = true;
      }
    }

    // Save notes
    _notesRef.set(notesData);
  }
}