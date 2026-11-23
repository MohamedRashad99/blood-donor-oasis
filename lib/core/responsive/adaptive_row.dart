import 'package:flutter/material.dart';

/// Keeps form fields usable when a side-by-side layout becomes too narrow.
class AdaptiveRow extends StatelessWidget {
  const AdaptiveRow({super.key, required this.children, this.breakpoint = 640,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max});
  final List<Widget> children;
  final double breakpoint;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    if (!children.any((child) => child is Flexible)) {
      return Wrap(spacing: 8, runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children.where((child) => child is! Spacer &&
          !(child is SizedBox && child.child == null && child.width != null)).toList());
    }
    if (constraints.maxWidth >= breakpoint) {
      return Row(crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment, mainAxisSize: mainAxisSize,
        children: children);
    }
    final stacked = <Widget>[];
    for (final child in children) {
      if (child is Spacer) continue;
      if (child is SizedBox && child.child == null && child.width != null) continue;
      if (stacked.isNotEmpty) stacked.add(const SizedBox(height: 12));
      stacked.add(child is Flexible ? child.child : child);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min, children: stacked);
  });
}
