import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class AfficheurUtilisateurGlobalWidget extends StatefulWidget {
  final int nombreUtilisateurs;
  final int nombreInactifs;
  final int nombreRoles;

  // Meilleur/plus faible vendeur, calculés depuis les paniers (montant total par caissier).
  final String? nomTopVendeur;
  final double? montantTopVendeur;
  final String? nomFaibleVendeur;
  final double? montantFaibleVendeur;

  const AfficheurUtilisateurGlobalWidget({
    super.key,
    required this.nombreUtilisateurs,
    required this.nombreInactifs,
    required this.nombreRoles,
    this.nomTopVendeur,
    this.montantTopVendeur,
    this.nomFaibleVendeur,
    this.montantFaibleVendeur,
  });

  @override
  State<AfficheurUtilisateurGlobalWidget> createState() =>
      _AfficheurUtilisateurGlobalWidgetState();
}

class _AfficheurUtilisateurGlobalWidgetState extends State<AfficheurUtilisateurGlobalWidget>
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
  void didUpdateWidget(AfficheurUtilisateurGlobalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nombreUtilisateurs != widget.nombreUtilisateurs ||
        oldWidget.nombreInactifs != widget.nombreInactifs ||
        oldWidget.nombreRoles != widget.nombreRoles ||
        oldWidget.nomTopVendeur != widget.nomTopVendeur ||
        oldWidget.montantTopVendeur != widget.montantTopVendeur ||
        oldWidget.nomFaibleVendeur != widget.nomFaibleVendeur ||
        oldWidget.montantFaibleVendeur != widget.montantFaibleVendeur) {
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
            _AnimatedStatCard(
              color: Appstyle.indigo,
              icon: Icons.people_outline,
              title: l10n.utilisateur,
              value: widget.nombreUtilisateurs.toDouble(),
              subtitle: "${widget.nombreInactifs} ${l10n.inactive}",
              suffix: "",
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.violet,
              icon: Icons.admin_panel_settings_outlined,
              title: l10n.role,
              value: widget.nombreRoles.toDouble(),
              subtitle: "",
              suffix: "",
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Colors.green,
              icon: Icons.emoji_events_outlined,
              title: "Top Vendeur",
              value: widget.montantTopVendeur ?? 0,
              subtitle: widget.nomTopVendeur ?? "-",
              suffix: l10n.currency,
              isMoney: true,
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Colors.redAccent,
              icon: Icons.trending_down,
              title: "Vente Faible",
              value: widget.montantFaibleVendeur ?? 0,
              subtitle: widget.nomFaibleVendeur ?? "-",
              suffix: l10n.currency,
              isMoney: true,
              animation: _controller,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Espace réduit de 14 à 10 (70%)
  Widget _space() => const SizedBox(width: 10);
}

class _AnimatedStatCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final double value;
  final String subtitle;
  final String suffix;
  final Animation<double> animation;
  final bool isMoney;

  const _AnimatedStatCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.suffix,
    required this.animation,
    this.isMoney = false,
  });

  @override
  Widget build(BuildContext context) {
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
                    isMoney: isMoney,
                  ),
                  if (suffix.isNotEmpty) ...[
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
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                // ✅ Espace réduit de 8 à 6
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Appstyle.textXS.copyWith(
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                    fontSize: 10, // ✅ Taille réduite
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
              // ✅ Espace réduit de 12 à 8
              const SizedBox(height: 8),
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
  final double value;
  final TextStyle style;
  final Animation<double> animation;
  final bool isMoney;

  const _AnimatedCounter({
    required this.value,
    required this.style,
    required this.animation,
    this.isMoney = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        double displayValue = value * animation.value;
        if (animation.isCompleted) {
          displayValue = value;
        }
        final formattedValue = isMoney
            ? NumberFormatUtil.formatMontant(displayValue, decimales: 0)
            : displayValue.toInt().toString();
        return Text(
          formattedValue,
          style: style,
        );
      },
    );
  }
}