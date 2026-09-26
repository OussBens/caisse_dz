import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../l10n/app_localizations.dart';

class AfficheurProduitsGlobalWidget extends StatefulWidget {
  final int nombreProduits;
  final int nombreCategories;
  final int nombreSousCategories;
  final int nombrePacks;
  final int nombreRemises;

  const AfficheurProduitsGlobalWidget({
    super.key,
    required this.nombreProduits,
    required this.nombreCategories,
    required this.nombreSousCategories,
    required this.nombrePacks,
    required this.nombreRemises,
  });

  @override
  State<AfficheurProduitsGlobalWidget> createState() => _AfficheurProduitsGlobalWidgetState();
}

class _AfficheurProduitsGlobalWidgetState extends State<AfficheurProduitsGlobalWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AfficheurProduitsGlobalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.nombreProduits != widget.nombreProduits ||
        oldWidget.nombreCategories != widget.nombreCategories ||
        oldWidget.nombreSousCategories != widget.nombreSousCategories ||
        oldWidget.nombrePacks != widget.nombrePacks ||
        oldWidget.nombreRemises != widget.nombreRemises) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)),
        child: Row(
          children: [
            /// 🟣 Produits
            _statCard(
              color: Appstyle.blueF,
              icon: Icons.inventory_2_outlined,
              title: l10n.products,
              value: widget.nombreProduits,
              subtitle: l10n.registeredProducts,
              suffix: l10n.products,
              animation: _controller,
            ),

            _space(),

            /// 🔵 Catégories
            _statCard(
              color: Appstyle.maron,
              icon: Icons.category_outlined,
              title: l10n.categories,
              value: widget.nombreCategories,
              subtitle: l10n.productTypes,
              suffix: l10n.categories,
              animation: _controller,
            ),

            _space(),

            /// 🟡 Sous-catégories
            _statCard(
              color: Appstyle.lavande,
              icon: Icons.subdirectory_arrow_right,
              title: l10n.subcategories,
              value: widget.nombreSousCategories,
              subtitle: l10n.secondaryLevels,
              suffix: l10n.subcategories,
              animation: _controller,
            ),

            _space(),

            /// 🟠 Packs
            _statCard(
              color: Appstyle.gris,
              icon: Icons.all_inbox,
              title: l10n.packs,
              value: widget.nombrePacks,
              subtitle: l10n.bundledOffers,
              suffix: l10n.packs,
              animation: _controller,
            ),

            _space(),

            /// 🟢 Remises
            _statCard(
              color: Appstyle.blueC,
              icon: Icons.percent,
              title: l10n.discounts,
              value: widget.nombreRemises,
              subtitle: l10n.activeDiscounts,
              suffix: l10n.discounts,
              animation: _controller,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Espace réduit de 14 à 10 (70%)
  Widget _space() => const SizedBox(width: 10);

  Widget _statCard({
    required Color color,
    required IconData icon,
    required String title,
    required int value,
    required String subtitle,
    required String suffix,
    required Animation<double> animation,
  }) {
    return Expanded(
      child: FadeTransition(
        opacity: animation,
        child: Container(
          // ✅ Padding réduit de 20 à 14 (70%)
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18), // ✅ Réduit de 24 à 18
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Icone padding réduit de 10 à 7
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12), // ✅ Réduit de 16 à 12
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20, // ✅ Réduit de 28 à 20
                ),
              ),
              // ✅ Espace réduit de 16 à 11
              const SizedBox(height: 11),

              // Titre
              Text(
                title,
                style: Appstyle.textSB.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4, // ✅ Réduit de 0.5 à 0.4
                ),
              ),
              // ✅ Espace réduit de 8 à 6
              const SizedBox(height: 6),

              // Valeur avec animation de comptage
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AnimatedCounter(
                    value: value,
                    style: Appstyle.textXXLB.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 26, // ✅ Réduit de 36 à 26
                      height: 1,
                    ),
                    animation: animation,
                  ),
                  // ✅ Espace réduit de 4 à 3
                  const SizedBox(width: 3),
                  Text(
                    " $suffix",
                    style: Appstyle.textSB.copyWith(
                      color: color.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // ✅ Espace réduit de 8 à 6
              const SizedBox(height: 6),

              // Sous-titre
              Text(
                subtitle,
                style: Appstyle.textXS.copyWith(
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                  fontSize: 10, // ✅ Taille réduite
                ),
              ),

              // ✅ Espace réduit de 12 à 8
              const SizedBox(height: 8),

              // Barre de progression décorative colorée
              Container(
                height: 2, // ✅ Réduit de 3 à 2
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.6),
                      color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle style;
  final Animation<double> animation;

  const _AnimatedCounter({
    required this.value,
    required this.style,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        int displayValue = (value * animation.value).round();
        if (animation.isCompleted) {
          displayValue = value;
        }
        return Text(
          displayValue.toString(),
          style: style,
        );
      },
    );
  }
}