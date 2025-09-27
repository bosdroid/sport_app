import 'package:firebase_analytics/firebase_analytics.dart';

class AppAnalytics {
  static FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // allow override in tests
  static void setAnalytics(FirebaseAnalytics analytics) {
    _analytics = analytics;
  }

  static Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  static Future<void> logTabSwitched(String tabName) async {
    await _analytics.logEvent(
      name: 'tab_switched',
      parameters: {'tab_name': tabName},
    );
  }

  static Future<void> logSearchPerformed(String query) async {
    await _analytics.logEvent(
      name: 'search_performed',
      parameters: {'query': query},
    );
  }

  static Future<void> logFilterTagSelected(String tagName) async {
    await _analytics.logEvent(
      name: 'filter_tag_selected',
      parameters: {'tag_name': tagName},
    );
  }

  static Future<void> logEmptyStateShown(String context) async {
    await _analytics.logEvent(
      name: 'empty_state_shown',
      parameters: {'context': context},
    );
  }

  static Future<void> logErrorStateShown(String errorCode) async {
    await _analytics.logEvent(
      name: 'error_state_shown',
      parameters: {'error_code': errorCode},
    );
  }

  static Future<void> logFeedbackPopupShown() async {
    await _analytics.logEvent(name: 'feedback_popup_shown');
  }

  static Future<void> logFeedbackSubmitted(String feedbackText) async {
    await _analytics.logEvent(
      name: 'feedback_submitted',
      parameters: {'feedback_text': feedbackText},
    );
  }

  static Future<void> logCardViewed(String cardId, String title) async {
    await _analytics.logEvent(
      name: 'card_viewed',
      parameters: {'card_id': cardId, 'title': title},
    );
  }

  static Future<void> logCardVideoPlayed(String videoTitle, String url) async {
    await _analytics.logEvent(
      name: 'card_video_played',
      parameters: {'video_title': videoTitle, 'url': url},
    );
  }

  static Future<void> logCardLinkClicked(String direction, String targetId) async {
    await _analytics.logEvent(
      name: 'card_link_clicked',
      parameters: {'direction': direction, 'target_id': targetId},
    );
  }

  static Future<void> logCardFavorited(String cardId) async {
    await _analytics.logEvent(
      name: 'card_favorited',
      parameters: {'card_id': cardId},
    );
  }

  static Future<void> logCardCreated(String cardId) async {
    await _analytics.logEvent(
      name: 'card_created',
      parameters: {'card_id': cardId},
    );
  }

  static Future<void> logCardEdited(String cardId) async {
    await _analytics.logEvent(
      name: 'card_edited',
      parameters: {'card_id': cardId},
    );
  }

  static Future<void> logDaySelected(String date) async {
    await _analytics.logEvent(
      name: 'day_selected',
      parameters: {'date': date},
    );
  }

  static Future<void> logLogUpdated({String? logId}) async {
    await _analytics.logEvent(
      name: 'log_updated',
      parameters: logId != null ? {'log_id': logId} : null,
    );
  }

  static Future<void> logEntryDeleted(String entryType) async {
    await _analytics.logEvent(
      name: 'entry_deleted',
      parameters: {'entry_type': entryType},
    );
  }
}
