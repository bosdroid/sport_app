import 'package:bjj_dairy/providers/plan_provider.dart';
import 'package:bjj_dairy/utils/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/validation_provider.dart';

class CollectionBottomSheet extends StatefulWidget {
  final String title;
  final String? initialName;
  final PlanProvider? planProvider;
  final void Function(String name) onConfirm;

  const CollectionBottomSheet({
    super.key,
    required this.title,
    this.initialName,
    this.planProvider,
    required this.onConfirm,
  });

  @override
  State<CollectionBottomSheet> createState() => _CollectionBottomSheetState();
}

class _CollectionBottomSheetState extends State<CollectionBottomSheet> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');

    // Delay focus request until after the widget is built
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose(); // Clean up the focus node
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final validationProvider = Provider.of<ValidationProvider>(context,listen: true);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade300,
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Consumer<ValidationProvider>(
                builder: (context, validator, child) {
                  return TextFormField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: AppStrings.collectionNameLabel,
                      border: InputBorder.none,
                      // border: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(30),
                      //   borderSide: BorderSide.none,
                      // ),
                      errorText: validator.collectionTitleError,
                      errorBorder: OutlineInputBorder(
                        // borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        // borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    onChanged: (value) => validator.validateCollectionTitle(value,widget.planProvider!.folders),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () { Navigator.pop(context);
                    validationProvider.resetAll();
                    },
                    child: const Text(AppStrings.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_controller.text.isNotEmpty && validationProvider.collectionTitleError == null) ? () {
                      final name = _controller.text.trim();
                      if (name.isNotEmpty) {
                        widget.onConfirm(name);
                      }
                      validationProvider.resetAll();
                    }:null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(AppStrings.applyLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

