import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

Widget detailbadge(String label, dynamic value) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(
      "$label : ${value ?? 0}",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
Widget detailsection(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Appstyle.gris.withOpacity(0.2), // violet clair
        borderRadius: BorderRadius.circular(12), // arrondi
      ),
      child: Text(
        title,
        style: Appstyle.textMB,
      ),
    ),
  );
}
Widget detailwrap(List<Widget> children) {
  return Wrap(
    spacing: 5,
    runSpacing: 16,
    children: children,
  );
}
Widget detailinfo(String label, dynamic value) {
  return SizedBox(
    width: 260,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir),

        ),
        const SizedBox(height: 4),
        Text(value?.toString() ?? "-",    style: Appstyle.textS.copyWith(color: Appstyle.violet),),
      ],
    ),
  );
}
