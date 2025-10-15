import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  final DatabaseReference promptRef;
  final DatabaseReference notesRef;
  final http.Client httpClient; // ✅ injectable

  AiRepositoryImpl({
    required this.promptRef,
    required this.notesRef,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  @override
  Future<String> fetchPrompt() async {
    final promptSnapshot = await promptRef.child('prompt').get();
    return promptSnapshot.exists ? promptSnapshot.value.toString() : "";
  }

  @override
  Future<Map<String, dynamic>> sendToAI(String finalPrompt) async {
    const String apiUrl = "https://api.openai.com/v1/chat/completions";
    const String apiKey = ""; // inject via config

    final Map<String, dynamic> requestBody = {
      "model": "gpt-4",
      "messages": [
        {"role": "system", "content": "You are an AI assistant that categorizes audio into goals, logs, and notes."},
        {"role": "user", "content": finalPrompt}
      ],
      "temperature": 0.7,
      "max_tokens": 500,
    };

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
  }

  @override
  Future<List<String>> fetchUserNotes(String userId) async {
    final userRef = notesRef.child(userId);
    final snapshot = await userRef.get();

    if (!snapshot.exists) return [];

    final notes = <String>[];
    for (final dateSnap in snapshot.children) {
      for (final noteSnap in dateSnap.children) {
        final value = noteSnap.value;
        if (value != null) notes.add(value.toString());
      }
    }
    return notes;
  }

}
