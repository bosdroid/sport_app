import 'package:flutter/material.dart';

class ExpandableDescription extends StatefulWidget {
  final String description;
  final int trimLines;

  const ExpandableDescription({
    super.key,
    required this.description,
    this.trimLines = 3,
  });

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _isExpanded = false;
  bool _isOverflowing = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure if text exceeds trimLines using TextPainter
        final textPainter = TextPainter(
          text: TextSpan(
            text: widget.description,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          maxLines: widget.trimLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        _isOverflowing = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.description,
              maxLines: _isExpanded ? null : widget.trimLines,
              overflow:
              _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            if (_isOverflowing) const SizedBox(height: 4),
            if (_isOverflowing)
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Text(
                  _isExpanded ? 'Show Less' : 'Show More',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
