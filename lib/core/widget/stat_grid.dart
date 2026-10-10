// core/widget/stats_grid.dart
import 'package:flutter/material.dart';
import '../theme/app_style.dart';

class StatsGrid extends StatelessWidget {
  final List<StatsGridItem> items;
  final int crossAxisCount;
  final double spacing;
  final double runSpacing;

  const StatsGrid({
    Key? key,
    required this.items,
    this.crossAxisCount = 4,
    this.spacing = 8,
    this.runSpacing = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: runSpacing,
      childAspectRatio: 2.2,
      children: items.map((item) => _buildItem(item)).toList(),
    );
  }

  Widget _buildItem(StatsGridItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: item.backgroundColor ?? Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(Appstyle.radiusSM),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (item.icon != null) ...[
            Icon(
              item.icon,
              color: item.iconColor ?? Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.value.toString(),
                style: Appstyle.textSB.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                item.label,
                style: Appstyle.textXSB.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatsGridItem {
  final String label;
  final dynamic value;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;

  StatsGridItem({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.backgroundColor,
  });
}