import 'package:flutter/material.dart';

class DaysPickerDialog extends StatefulWidget {
  final List<int> initialSelectedDays;
  final Function(List<int>) onSelectionChanged;

  const DaysPickerDialog({
    super.key,
    required this.initialSelectedDays,
    required this.onSelectionChanged,
  });

  @override
  State<DaysPickerDialog> createState() => _DaysPickerDialogState();
}

class _DaysPickerDialogState extends State<DaysPickerDialog> {
  late List<int> selectedDays;
  final List<String> dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    selectedDays = List.from(widget.initialSelectedDays);
  }

  bool areAllDaysSelected() => selectedDays.length == dayNames.length;

  void toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        selectedDays = List.generate(7, (index) => index + 1);
      } else {
        selectedDays.clear();
      }
      widget.onSelectionChanged(selectedDays);
    });
  }

  void toggleDay(int dayNumber, bool? value) {
    setState(() {
      if (value == true) {
        selectedDays.add(dayNumber);
      } else {
        selectedDays.remove(dayNumber);
      }
      widget.onSelectionChanged(selectedDays);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: const Text('Select All'),
            value: areAllDaysSelected(),
            onChanged: toggleSelectAll,
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: dayNames.length,
              itemBuilder: (context, index) {
                final dayNumber = index + 1;
                return CheckboxListTile(
                  title: Text(dayNames[index]),
                  value: selectedDays.contains(dayNumber),
                  onChanged: (value) => toggleDay(dayNumber, value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
