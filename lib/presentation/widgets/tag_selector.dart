import 'package:flutter/material.dart';

class TagSelector extends StatefulWidget {
  final List<String> tags;
  final Function(List<String>) onTagsSelected;
  final List<String>? initialSelected;

  const TagSelector({
    super.key,
    required this.tags,
    required this.onTagsSelected,
    this.initialSelected,
  });

  @override
  _TagSelectorState createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  late Set<String> selectedTags;

  @override
  void initState() {
    super.initState();
    selectedTags = Set<String>.from(widget.initialSelected ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: widget.tags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tag = widget.tags[index];
          final isSelected = selectedTags.contains(tag);

          return ChoiceChip(
            label: Text(tag),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                if (isSelected) {
                  // If tag is already selected, remove it
                  selectedTags.remove(tag);
                } else {
                  if (tag.toLowerCase() == 'all') {
                    // If "all" is selected, remove all others and only select "all"
                    selectedTags.clear();
                    selectedTags.add(tag);
                  } else {
                    // If "all" was selected previously, unselect it
                    selectedTags.removeWhere((t) => t.toLowerCase() == 'all');
                    selectedTags.add(tag);
                  }
                }
              });

              widget.onTagsSelected(selectedTags.toList());
            },
            selectedColor: Theme.of(context).primaryColor,
            backgroundColor: Colors.grey.shade300,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}
