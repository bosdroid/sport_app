import 'log_history.dart';

class DailyLogDisplayItem {
  final DateTime date;
  final LogHistory? history;

  DailyLogDisplayItem({required this.date, this.history});
}
