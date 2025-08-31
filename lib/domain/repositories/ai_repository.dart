/// Contract for AI analysis and prompts
abstract class AiRepository {
  Future<String> fetchPrompt();
  Future<Map<String, dynamic>> sendToAI(String finalPrompt);
  Future<List<String>> fetchUserNotes(String userId);
}
