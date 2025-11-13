import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Widget that measures its child's size and reports it via a callback.
class _MeasureSize extends SingleChildRenderObjectWidget {
  final void Function(Size size) onChange;
  const _MeasureSize({Key? key, required Widget child, required this.onChange})
      : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureSize(onChange);
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderMeasureSize renderObject) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  void Function(Size size) onChange;
  Size? _oldSize;
  _RenderMeasureSize(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_oldSize == null || _oldSize != newSize) {
      _oldSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChange(newSize);
      });
    }
  }
}

/// ExpandableDescription using offstage measurement for reliable overflow detection.
class ExpandableDescription extends StatefulWidget {
  final String description;
  final int trimLines;
  final TextStyle? style;
  final String showMoreLabel;
  final String showLessLabel;

  const ExpandableDescription({
    super.key,
    required this.description,
    this.trimLines = 3,
    this.style,
    this.showMoreLabel = 'Show More',
    this.showLessLabel = 'Show Less',
  });

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _isExpanded = false;
  bool _isOverflowing = false;

  // Heights measured after layout
  double _trimmedHeight = 0;
  double _fullHeight = 0;

  TextStyle get _effectiveStyle =>
      widget.style ?? const TextStyle(fontSize: 14, color: Colors.black87);

  void _onTrimmedSize(Size s) {
    if ((_trimmedHeight - s.height).abs() > 0.5) {
      setState(() => _trimmedHeight = s.height);
      _updateOverflowFlag();
    }
  }

  void _onFullSize(Size s) {
    if ((_fullHeight - s.height).abs() > 0.5) {
      setState(() => _fullHeight = s.height);
      _updateOverflowFlag();
    }
  }

  void _updateOverflowFlag() {
    final overflow = _fullHeight > 0 && _trimmedHeight > 0 && _fullHeight - _trimmedHeight > 0.5;
    if (overflow != _isOverflowing) {
      setState(() => _isOverflowing = overflow);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in Column; if parent provides infinite width (rare for normal UIs),
    // you should place this inside a ConstrainedBox / Expanded to bound width.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The visible text
        AnimatedCrossFade(
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          firstChild: Text(
            widget.description,
            maxLines: widget.trimLines,
            overflow: TextOverflow.ellipsis,
            style: _effectiveStyle,
          ),
          secondChild: Text(
            widget.description,
            style: _effectiveStyle,
          ),
        ),

        // Spacing + control
        if (_isOverflowing) const SizedBox(height: 6),
        if (_isOverflowing)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Text(
              _isExpanded ? widget.showLessLabel : widget.showMoreLabel,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: _effectiveStyle.fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // --- Invisible measuring widgets below ---
        // They must be provided the same width constraints as the visible Text.
        // We place them offstage so they don't paint, but they still layout and report size.
        Offstage(
          child: _MeasureSize(
            onChange: _onTrimmedSize,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: Text(
                widget.description,
                maxLines: widget.trimLines,
                overflow: TextOverflow.ellipsis,
                style: _effectiveStyle,
              ),
            ),
          ),
        ),
        Offstage(
          child: _MeasureSize(
            onChange: _onFullSize,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: Text(
                widget.description,
                style: _effectiveStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
