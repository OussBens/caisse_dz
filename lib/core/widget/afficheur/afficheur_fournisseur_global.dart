import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class AfficheurFournisseurGlobalWidget extends StatefulWidget {
  final String type;
  final int nombreClients;
  final int nombreInactifs;

  // Statistiques globales optionnelles (achats / crédit tous fournisseurs confondus)
  final double? totalAchat;
  final String? nomFournisseurTopAchat;
  final double? montantTopAchat;
  final double? totalCredit;
  final String? nomFournisseurTopCredit;
  final double? montantTopCredit;

  const AfficheurFournisseurGlobalWidget({
    super.key,
    required this.nombreClients,
    required this.nombreInactifs,
    required this.type,
    this.totalAchat,
    this.nomFournisseurTopAchat,
    this.montantTopAchat,
    this.totalCredit,
    this.nomFournisseurTopCredit,
    this.montantTopCredit,
  });

  @override
  State<AfficheurFournisseurGlobalWidget> createState() => _AfficheurFournisseurGlobalWidgetState();
}

class _AfficheurFournisseurGlobalWidgetState extends State<AfficheurFournisseurGlobalWidget>
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
  void didUpdateWidget(AfficheurFournisseurGlobalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nombreClients != widget.nombreClients ||
        oldWidget.nombreInactifs != widget.nombreInactifs ||
        oldWidget.type != widget.type ||
        oldWidget.totalAchat != widget.totalAchat ||
        oldWidget.totalCredit != widget.totalCredit) {
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
    final bool afficherStatsGlobales = widget.totalAchat != null && widget.totalCredit != null;

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
              color: Appstyle.violet,
              icon: Icons.business_outlined,
              title: widget.type,
              value: widget.nombreClients.toDouble(),
              subtitle: "${widget.nombreInactifs} ${l10n.inactive}",
              suffix: l10n.supplier,
              animation: _controller,
            ),
            if (afficherStatsGlobales) ...[
              _space(),
              _AnimatedStatCard(
                color: Appstyle.indigo,
                icon: Icons.shopping_cart_outlined,
                title: l10n.totalAchat,
                value: widget.totalAchat!,
                subtitle: widget.nomFournisseurTopAchat != null
                    ? "${l10n.bestSuppliers} : ${widget.nomFournisseurTopAchat}"
                    : "-",
                suffix: l10n.currency,
                isMoney: true,
                animation: _controller,
              ),
              _space(),
              _AnimatedStatCard(
                color: Appstyle.crevete,
                icon: Icons.emoji_events_outlined,
                title: l10n.bestSuppliers,
                value: widget.montantTopAchat ?? 0,
                subtitle: widget.nomFournisseurTopAchat ?? "-",
                suffix: l10n.currency,
                isMoney: true,
                animation: _controller,
              ),
              _space(),
              _AnimatedStatCard(
                color: Appstyle.warning,
                icon: Icons.arrow_downward,
                title: l10n.totalCredit,
                value: widget.totalCredit!,
                subtitle: widget.nomFournisseurTopCredit != null
                    ? "${l10n.topCredits} : ${widget.nomFournisseurTopCredit}"
                    : "-",
                suffix: l10n.currency,
                isMoney: true,
                animation: _controller,
              ),
              _space(),
              _AnimatedStatCard(
                color: Appstyle.danger,
                icon: Icons.warning_amber_outlined,
                title: l10n.topCredits,
                value: widget.montantTopCredit ?? 0,
                subtitle: widget.nomFournisseurTopCredit ?? "-",
                suffix: l10n.currency,
                isMoney: true,
                animation: _controller,
              ),
            ],
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
  final bool showValueAsText;
  final String? textValue;

  const _AnimatedStatCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.suffix,
    required this.animation,
    this.isMoney = false,
    this.showValueAsText = false,
    this.textValue,
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
            borderRadius: BorderRadius.circular(Appstyle.radiusCard), // ✅ Réduit de 24 à 18
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
                  borderRadius: BorderRadius.circular(Appstyle.radiusMD), // ✅ Réduit de 16 à 12
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
              if (showValueAsText && textValue != null)
                Text(
                  textValue!,
                  style: Appstyle.textLB.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // ✅ Réduit de 24 à 18
                    height: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              else
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
        String formattedValue;
        if (displayValue == displayValue.toInt()) {
          formattedValue = displayValue.toInt().toString();
        } else {
          formattedValue = isMoney
              ? NumberFormatUtil.formatMontant(displayValue, decimales: 0)
              : NumberFormatUtil.formatMontant(displayValue, decimales: 1);
        }
        return Text(
          formattedValue,
          style: style,
        );
      },
    );
  }
}