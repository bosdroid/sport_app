import 'package:flutter/material.dart';

class CollectionCard extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const CollectionCard({
    super.key,
    required this.title,
    required this.count,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 140,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.folder, size: 32, color: Colors.black),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    title[0].toUpperCase() + title.substring(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                ),
                Expanded(
                  child: Text(
                    '$count techniques',
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 4,
            child: InkWell(
              onTap: onMore,
              borderRadius: BorderRadius.circular(16),
              child: const Icon(Icons.more_vert),
            ),
          ),
        ],
      ),
    );
  }
}
