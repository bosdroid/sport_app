
import 'package:flutter/material.dart';

import '../../core/app_strings.dart';

class CollectionDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final void Function(String name) onConfirm;

  const CollectionDialog({
    super.key,
    required this.title,
    this.initialName,
    required this.onConfirm,
  });

  @override
  State<CollectionDialog> createState() => _CollectionDialogState();
}

class _CollectionDialogState extends State<CollectionDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: AppStrings.collectionNameLabel,
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              widget.onConfirm(name);
              Navigator.pop(context);
            }
          },
          child: const Text(AppStrings.confirm),
        ),
      ],
    );
  }
}
