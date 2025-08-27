import 'package:bjj_dairy/utils/app_strings.dart';
import 'package:flutter/material.dart';

import '../model/plan.dart';
import '../providers/plan_provider.dart';
import '../view/plan_detail_screen.dart';
class TechniqueCard extends StatelessWidget {
  final Plan plan;
  final PlanProvider planProvider;
  final bool isParent;
  final bool isStatus;
  final bool isCollectionSelectionEnable;
  final VoidCallback? onMore;
  final String folderId;
  final bool isShared;

  const TechniqueCard({
    super.key,
    required this.plan,
    required this.planProvider,
    this.isParent = false,
    this.isStatus = false,
    this.isCollectionSelectionEnable = false,
    this.onMore,
    required this.folderId,
    this.isShared = false
  });

  @override
  Widget build(BuildContext context) {
    return
      Container(
      decoration: BoxDecoration(
        border: Border.all(width: 0.5,color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: (){
                planProvider.enterSelectionMode(plan.id);
              },
              onTap: folderId.isNotEmpty && plan.folderId != folderId && !plan.isShared ? null : (){
                if (planProvider.isSelectionMode) {
                  planProvider.toggleSelection(plan.id);
                }
                else {
                  // normal tap behavior
                  // AppAnalytics.logCardLinkClicked(isParent ? 'child':'parent', plan.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: plan,isShared: isShared,)),
                  );
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if(isStatus) ...[
                    GestureDetector(
                      onTap: (){

                      },
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: plan.status == 'neutral' ? Colors.yellow : plan.status == 'success' ? Colors.green: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4,),
                  ],
                  if (planProvider.isSelectionMode)
                    Checkbox(
                      value: planProvider.selectedPlanIds.contains(plan.id),
                      onChanged: (bool? selected) {
                        planProvider.toggleSelection(plan.id);
                      },
                    ),
                  Expanded(
                    child: Text(plan.title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  if(folderId.isNotEmpty && plan.folderId != folderId && !plan.isShared)
                  IconButton(
                    icon: Icon(Icons.lock_outline),
                    onPressed: null,
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: folderId.isNotEmpty && plan.folderId != folderId && !plan.isShared ? null : onMore,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),

            /// Tags
            if (plan.tags.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 8,
                  runSpacing: -8,
                  children: plan.tags.map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Colors.grey.shade300,
                    shape: StadiumBorder(),
                    labelStyle: TextStyle(fontSize: 13),
                  )).toList(),
                ),
              ),
            if(folderId.isNotEmpty && plan.folderId != folderId && !plan.isShared)
            ...[
             const SizedBox(height: 2,),
            Text(AppStrings.outOfFolderWarning,style: TextStyle(color: Colors.red,fontStyle: FontStyle.italic),)
            ]
          ],
        ),
      ),
    );
  }
}
