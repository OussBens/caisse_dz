// core/widget/photo/bon_reception_card.dart
import 'dart:io';

import 'package:caisse_dz/Services/BonReceptionPhotos.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/bon_reception.dart';
import 'package:flutter/material.dart';

/// Vignette d'un bon de réception (photo jointe depuis le disque, ou reçue
/// depuis l'ancienne app mobile pour les bons historiques) affichée dans le `Wrap` de l'onglet "Entrée IA".
///
/// Bordure violette = pas encore scannée, verte = déjà transformée en Smart
/// Scan, rouge = erreur. Un tap ouvre l'assistant IA sur cette photo.
class BonReceptionCard extends StatefulWidget {
  final BonReception bon;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  // ✅ Nom (déjà résolu par l'appelant, qui a la liste des utilisateurs) de
  // la personne ayant scanné/traité cette photo, si applicable.
  final String? traiteParNom;

  const BonReceptionCard({
    super.key,
    required this.bon,
    required this.onTap,
    this.onDelete,
    this.traiteParNom,
  });

  @override
  State<BonReceptionCard> createState() => _BonReceptionCardState();
}

class _BonReceptionCardState extends State<BonReceptionCard> {
  BonReception get bon => widget.bon;

  Color get _borderColor {
    if (bon.estTraite) return Appstyle.green;
    if (bon.estErreur) return Appstyle.red;
    return Appstyle.violet;
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Appstyle.radiusMD),
            border: Border.all(color: _borderColor, width: 3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 154,
                height: 140,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(9),
                        topRight: Radius.circular(9),
                      ),
                      child: SizedBox(
                        width: 148,
                        height: 134,
                        child: FutureBuilder<File?>(
                          future: BonReceptionPhotoService.getPhotoFile(bon.cheminPhoto),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState != ConnectionState.done) {
                              return const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            final file = snapshot.data;
                            if (file == null) {
                              return Container(
                                color: Appstyle.grisSC,
                                child: const Icon(Icons.broken_image, color: Appstyle.gris),
                              );
                            }
                            return Image.file(
                              file,
                              fit: BoxFit.cover,
                              width: 148,
                              height: 134,
                              errorBuilder: (_, __, ___) => Container(
                                color: Appstyle.grisSC,
                                child: const Icon(Icons.image_not_supported, color: Appstyle.gris),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Badge source (téléphone = bon historique reçu du mobile, vs joint depuis le disque)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          bon.deviceId != null ? Icons.smartphone : Icons.attach_file,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Icône statut traité
                    if (bon.estTraite)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_circle, size: 18, color: Appstyle.green),
                        ),
                      ),

                    if (widget.onDelete != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: widget.onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Appstyle.danger,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Reçu: ${_formatDate(bon.dateReception)}",
                      style: Appstyle.textXS.copyWith(fontSize: 9, color: Appstyle.gris),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (bon.estTraite && bon.dateTraitement != null)
                      Text(
                        "Scanné: ${_formatDate(bon.dateTraitement!)}",
                        style: Appstyle.textXS.copyWith(fontSize: 9, color: Appstyle.green),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (bon.estTraite && widget.traiteParNom != null && widget.traiteParNom!.isNotEmpty)
                      Text(
                        "Par: ${widget.traiteParNom}",
                        style: Appstyle.textXS.copyWith(fontSize: 9, color: Appstyle.green),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}
