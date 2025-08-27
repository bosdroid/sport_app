import 'package:flutter/material.dart';

import '../model/folder.dart';
import '../providers/plan_provider.dart';
import '../utils/app_strings.dart';

class ChangeAccessBottomSheet extends StatefulWidget {
  final Folder collection;
  final PlanProvider planProvider;

  const ChangeAccessBottomSheet({
    super.key,
    required this.collection,
    required this.planProvider,
  });

  @override
  State<ChangeAccessBottomSheet> createState() => _ChangeAccessBottomSheetState();
}

class _ChangeAccessBottomSheetState extends State<ChangeAccessBottomSheet> {
  late String selectedAccess;
  late List<String> allowedUsers;
  final TextEditingController _userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedAccess = widget.collection.access;
    allowedUsers = List.from(widget.collection.allowedUsers);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(
        const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: const Text(
                  AppStrings.changeAccess,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
           Divider(height: 1,color: Colors.grey.shade300,),
          const SizedBox(height: 12),
          RadioListTile(
            title: const Text(AppStrings.private),
            value: 'private',
            groupValue: selectedAccess,
            onChanged: (value) {
              setState(() => selectedAccess = value!);
            },
          ),
          RadioListTile(
            title: const Text(AppStrings.public),
            value: 'public',
            groupValue: selectedAccess,
            onChanged: (value) {
              setState(() => selectedAccess = value!);
            },
          ),
          // RadioListTile(
          //   title: const Text('Specific Users'),
          //   value: 'specific',
          //   groupValue: selectedAccess,
          //   onChanged: (value) {
          //     setState(() => selectedAccess = value!);
          //   },
          // ),
          // if (selectedAccess == 'specific') ...[
          //   const SizedBox(height: 8),
          //   Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 12),
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(8),
          //       color: Colors.grey.shade300,
          //       border: Border.all(color: Colors.grey.shade100),
          //     ),
          //     child: TextField(
          //       controller: _userIdController,
          //       decoration: InputDecoration(
          //         labelText: 'Add user ID',
          //         border: InputBorder.none,
          //       ),
          //       onSubmitted: (userId) {
          //         if (userId.isNotEmpty && !allowedUsers.contains(userId)) {
          //           setState(() {
          //             allowedUsers.add(userId);
          //             _userIdController.clear();
          //           });
          //         }
          //       },
          //     ),
          //   ),
          //   const SizedBox(height: 8),
          //   SingleChildScrollView(
          //     scrollDirection: Axis.horizontal,
          //     child: Wrap(
          //       spacing: 8,
          //       children: allowedUsers.map((user) {
          //         return Chip(
          //           label: Text(user),
          //           onDeleted: () {
          //             setState(() => allowedUsers.remove(user));
          //           },
          //         );
          //       }).toList(),
          //     ),
          //   ),
          // ],
          // const SizedBox(height: 16),
          Divider(height: 1,color: Colors.grey.shade300,),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  child: const Text(AppStrings.cancel),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white
                  ),
                  child: const Text(AppStrings.update),
                  onPressed: () async {
                    await widget.planProvider.updateFolderAccess(
                      widget.collection.id!,
                      selectedAccess,
                      allowedUsers: selectedAccess == 'specific' ? allowedUsers : [],
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
