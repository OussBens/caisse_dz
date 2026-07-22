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

  Widget _space() => const SizedBox(width: 14);

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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, // ✅ Fond blanc
            borderRadius: BorderRadius.circular(24),
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
              // Icône avec fond coloré
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12), // ✅ Fond coloré léger
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color, // ✅ Icône prend la couleur de la stat
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),

              // Titre
              Text(
                title,
                style: Appstyle.textSB.copyWith(
                  color: color, // ✅ Texte prend la couleur de la stat
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Valeur avec animation de comptage
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AnimatedCounter(
                    value: value,
                    style: Appstyle.textXXLB.copyWith(
                      color: color, // ✅ Chiffre prend la couleur de la stat
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                      height: 1,
                    ),
                    animation: animation,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    " $suffix",
                    style: Appstyle.textSB.copyWith(
                      color: color.withOpacity(0.7), // ✅ Suffixe prend la couleur de la stat
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Sous-titre
              Text(
                subtitle,
                style: Appstyle.textXS.copyWith(
                  color: color.withOpacity(0.8), // ✅ Sous-titre prend la couleur de la stat
                  fontWeight: FontWeight.w400,
                ),
              ),

              // Barre de progression décorative colorée
              const SizedBox(height: 12),
              Container(
                height: 3,
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