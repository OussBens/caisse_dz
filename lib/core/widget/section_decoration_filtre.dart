import 'package:flutter/material.dart';


class SectionDecorationFiltre extends StatelessWidget {

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const SectionDecorationFiltre({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(10),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 0.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

  }

}
