import 'package:bjj_dairy/presentation/widgets/tap_hint_animation.dart';
import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../core/utils.dart';
import '../../domain/entities/folder.dart';
import 'point_animation.dart'; // ✅ import this
// import '../providers/plan_provider.dart'; // keep if you need it later

class CollectionCard extends StatelessWidget {
  final Folder folder;
  final int count;
  final String userId;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const CollectionCard({
    super.key,
    required this.folder,
    required this.count,
    required this.userId,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    bool shouldShowPointer =
        Util.ownerUserName == folder.userId && !Util.isUserLogged;

    Widget cardContent = Stack(
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
              if (userId != folder.userId) ...[
                Row(
                  children: [
                    const Text(
                      'owner: ',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      folder.userId!,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  const Icon(Icons.folder, size: 32, color: Colors.black),
                  const SizedBox(width: 2),
                  Icon(
                    folder.access == 'public'
                        ? Icons.public
                        : folder.access == 'private'
                        ? Icons.lock
                        : folder.access == 'specific'
                        ? Icons.group
                        : Icons.help_outline,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  folder.name![0].toUpperCase() + folder.name!.substring(1),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                ),
              ),
              Expanded(
                child: Text(
                  '$count ${AppStrings.techniqueLabel}',
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        if (Util.ownerUserName != folder.userId && !Util.isUserLogged)
          Positioned(
            top: 16,
            right: 4,
            child: InkWell(
              onTap: onMore,
              borderRadius: BorderRadius.circular(16),
              child: const Icon(Icons.more_vert),
            ),
          ),
        if (Util.ownerUserName == folder.userId && !Util.isUserLogged)
          Positioned(
            top: 16,
            right: 4,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: const Icon(Icons.visibility),
            ),
          ),
      ],
    );

    // 👇 Wrap cardContent with the PointAnimation widget

    return GestureDetector(
      onTap: onTap,
      child: cardContent,
    );
  }
}
