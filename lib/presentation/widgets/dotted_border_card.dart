import 'package:flutter/material.dart';
class DottedBorderCard extends StatelessWidget {
  final Widget child;

  const DottedBorderCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey,
          style: BorderStyle.solid, // Use a dashed border package if needed
        ),
      ),
      child: Center(child: child),
    );
  }
}