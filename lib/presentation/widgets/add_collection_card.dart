
import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import 'dotted_border_card.dart';
class AddCollectionCard extends StatelessWidget {
  final VoidCallback onTap;

  const AddCollectionCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorderCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.grey),
            SizedBox(height: 4),
            Text(AppStrings.addCollectionLabel,
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}