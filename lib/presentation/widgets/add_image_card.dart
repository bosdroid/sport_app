import 'package:flutter/material.dart';

import 'dotted_border_card.dart';
class AddImageCard extends StatelessWidget {
  final VoidCallback onTap;

  const AddImageCard({super.key, required this.onTap});

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
            Text('Add Image',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}