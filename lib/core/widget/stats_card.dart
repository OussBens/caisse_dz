// core/widget/stats_card.dart
import 'package:flutter/material.dart';
import '../theme/app_style.dart';

class StatsCard extends StatelessWidget {
  final List<StatsItem> items;
  final Color? backgroundColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isCompact;

  const StatsCard({
    Key? key,
    required this.items,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor ?? Appstyle.violet.withOpacity(0.7),
            (backgroundColor ?? Appstyle.violet).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? Appstyle.violet).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(12),
      child: isCompact
          ? Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceEvenly,
        children: items.map((item) => _buildCompactStatItem(item)).toList(),
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) => _buildStatItem(item)).toList(),
      ),
    );
  }

  Widget _buildStatItem(StatsItem item) {
    return Column(
      children: [
        Text(
          item.value.toString(),
          style: Appstyle.textLB.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          style: Appstyle.textXSB.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatItem(StatsItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.value.toString(),
            style: Appstyle.textSB.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            item.label,
            style: Appstyle.textXSB.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class StatsItem {
  final String label;
  final dynamic value;
  final IconData? icon;

  StatsItem({
    required this.label,
    required this.value,
    this.icon,
  });
}