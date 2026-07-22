import 'package:flutter/material.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageSelected;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [];

    if (totalPages <= 7) {
      for (int i = 1; i <= totalPages; i++) {
        pages.add(_buildPage(i));
      }
    } else {
      for (int i = 1; i <= 7; i++) {
        pages.add(_buildPage(i));
      }

      pages.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text("..."),
      ));

      pages.add(_buildPage(totalPages));
    }

    return Align(
      alignment: Alignment.center, // pour centrer le container
      child: IntrinsicWidth( // 👈 largeur = contenu
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // 👈 ne pas prendre toute la largeur
            children: pages,
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int page) {
    bool isSelected = page == currentPage;

    return GestureDetector(
      onTap: () => onPageSelected(page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6A4CE3) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(
          "$page",
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
