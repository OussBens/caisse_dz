import 'package:flutter/material.dart';


import 'package:caisse_dz/core/theme/app_style.dart';

class StepIndicator extends StatelessWidget {
  final int activeStep; // 1,2,3
  const StepIndicator({super.key, required this.activeStep});

  Color getColor(int step) {
    return step <= activeStep ? Appstyle.violet : Appstyle.gris; // violet / gris
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // --- Step 1 ---
        _buildCircle(1),
        _buildLine(1),

        // --- Step 2 ---
        _buildCircle(2),
        _buildLine(2),

        // --- Step 3 ---
        _buildCircle(3),
      ],
    );
  }

  Widget _buildCircle(int step) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: getColor(step),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        "$step",
        style: Appstyle.textpop_M.copyWith(color: Appstyle.Tblanc),
      ),
    );
  }

  Widget _buildLine(int step) {
    return Expanded(
      child: Container(
        height: 4,
        color: step < activeStep ? const Color(0xFF6A0DAD) : Colors.grey,
      ),
    );
  }
}
