import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/log_repository.dart';
import '../../domain/repositories/note_repository.dart';

class AiAnalyzerProvider with ChangeNotifier {
  final AiRepository aiRepository;
  final GoalRepository goalRepository;
  final LogRepository logRepository;
  final NoteRepository noteRepository;

  AiAnalyzerProvider({
    required this.aiRepository,
    required this.goalRepository,
    required this.logRepository,
    required this.noteRepository,
  });

  bool _isLoading = false;
  String _aiResponse = "";

  bool get isLoading => _isLoading;
  String get aiResponse => _aiResponse;

  Map<String, String?> logs = {};
  Map<String, String?> goals = {};
  List<String> notes = [];

  void resetResponse() {
    _aiResponse = "";
    notifyListeners();
  }

  Future<void> analyzeText(String audioText) async {
    _isLoading = true;
    notifyListeners();
    final now = DateTime.now();
    final prompt = await aiRepository.fetchPrompt();
    final userGoals = (await goalRepository.fetchGoals()).map((g) => g.title).toList();
    final userLogs = (await logRepository.fetchLogs()).map((l) => l.title).toList();
    final userNotes = await noteRepository.fetchNote(now);

    final finalPrompt = "$prompt\n"
        "Here is my list of goals: ${userGoals.join(', ')}\n"
        "Here is my list of logs: ${userLogs.join(', ')}\n"
        "Audio Text: $audioText\n"
        "Notes: $userNotes\n"
        "I need just json result for getting values for update in logs, goals and notes.";

    final response = await aiRepository.sendToAI(finalPrompt);
    final result = response["choices"][0]["message"]["content"];

    _aiResponse = await parseAiResult(result);
    _isLoading = false;
    notifyListeners();
  }

  Future<String> parseAiResult(String result) async {
    final jsonMap = jsonDecode(result);

    if (jsonMap.containsKey("Logs")) {
      jsonMap["Logs"].forEach((key, value) {
        logs[key] = value?.toString();
        if (value != null && value.toString().isNotEmpty) {
          logRepository.updateLogDataWithAi(key, value.toString());
        }
      });
    }

    if (jsonMap.containsKey("Goals")) {
      jsonMap["Goals"].forEach((key, value) {
        goals[key] = value?.toString();
        if (value != null && value.toString().isNotEmpty) {
          goalRepository.updateGoalStatusWithAi(key, value.toString());
        }
      });
    }

    if (jsonMap.containsKey("Notes")) {
      notes = List<String>.from(jsonMap["Notes"]);
      if (notes.isNotEmpty) {
        await noteRepository.addNote(notes.join(","));
      }
    }

    if (kDebugMode) {
      print("AI processed response: $jsonMap");
    }

    return "";
  }
}
