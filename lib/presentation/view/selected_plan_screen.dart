import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_strings.dart';
import '../../domain/entities/plan.dart';
import '../providers/plan_provider.dart';

class SelectPlanScreen extends StatefulWidget {
  final String? planId;
  final bool? isParent;

  const SelectPlanScreen({super.key, this.planId, this.isParent});

  @override
  State<SelectPlanScreen> createState() => _SelectPlanScreenState();
}

class _SelectPlanScreenState extends State<SelectPlanScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedPlanIds = {}; // Track selected plans

  @override
  Widget build(BuildContext context) {
    final planProvider = Provider.of<PlanProvider>(context, listen: true);
    List<Plan> allPlans = planProvider.plans;
    List<Plan> filteredPlans = allPlans
        .where((plan) => plan.id != widget.planId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(AppStrings.selectPlansTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.close), // ❌ Close
            onPressed: () {
              Navigator.pop(context); // just go back
            },
          ),
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final String userId = prefs.getString("user_name") ?? '';
              for (String id in _selectedPlanIds) {
                if (widget.isParent!) {
                  await planProvider.updateConnections(
                    userId,
                    id,
                    widget.planId!,
                  );
                } else {
                  await planProvider.updateConnections(
                      userId, widget.planId!, id);
                }
              }
              Navigator.pop(context); // back to parent

              // // Return selected plans
              // final selectedPlans = allPlans
              //     .where((plan) => _selectedPlanIds.contains(plan.id))
              //     .toList();
              // Navigator.pop(context, selectedPlans); // You can use this result
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                planProvider.filterPlans(value, null);
              },
            ),
          ),
          Expanded(
            child: planProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPlans.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            AppStrings.emptyPlanList,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView(
                        children: filteredPlans.map((plan) {
                          final isSelected = _selectedPlanIds.contains(plan.id);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedPlanIds.remove(plan.id);
                                } else {
                                  _selectedPlanIds.add(plan.id);
                                }
                              });
                            },
                            child:
                            Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              elevation: 3,
                              color: Colors.white,
                              child: ListTile(
                                title: Text(
                                  plan.title,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                trailing: isSelected
                                    ?  Icon(Icons.check_circle,
                                        color: Theme.of(context).primaryColor)
                                    : const Icon(Icons.radio_button_unchecked),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }
}
