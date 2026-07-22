import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import '../../../Services/Photos.dart';

import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../information_dialog.dart';

// Enum pour les types d'emballage
enum TypeEmballage { unit, boite, carton }

Future<void> afficherProduitSelectionneDialog({
  required BuildContext context,
  required String nom,
  required double prix,
  required String? photoName,
  required Function(double qte, {String? colisType, double? prixUnitaire}) onAjouter,
  double? emballage1,
  double? emballageP1,
  double? emballage2,
  double? emballageP2,
  String? defaultColisType,
  required double quantiteDisponible,
}) async {
  final qteController = TextEditingController(text: "1");
  Timer? autoAddTimer;
  bool isEditing = false;

  final bool hasBoite = (emballage1 != null && emballage1 > 0 && emballageP1 != null && emballageP1 > 0);
  final bool hasCarton = (emballage2 != null && emballage2 > 0 && emballageP2 != null && emballageP2 > 0);

  TypeEmballage determineDefaultEmballage() {
    if (hasBoite && defaultColisType == 'small') {
      return TypeEmballage.boite;
    }
    if (hasCarton && defaultColisType == 'large') {
      return TypeEmballage.carton;
    }
    return TypeEmballage.unit;
  }

  TypeEmballage selectedEmballage = determineDefaultEmballage();
  double currentPrixUnitaire = prix;
  int piecesParUnite = 1;
  String uniteLabel = "pièce(s)";
  String currentColisType = "";

  void updateEmballageInfo() {
    switch (selectedEmballage) {
      case TypeEmballage.boite:
        piecesParUnite = emballage1?.toInt() ?? 1;
        currentPrixUnitaire = emballageP1 ?? prix;
        uniteLabel = "boîte(s)";
        currentColisType = "Boîte (${emballage1?.toInt()} pièces)";
        break;
      case TypeEmballage.carton:
        piecesParUnite = emballage2?.toInt() ?? 1;
        currentPrixUnitaire = emballageP2 ?? prix;
        uniteLabel = "carton(s)";
        currentColisType = "Carton (${emballage2?.toInt()} pièces)";
        break;
      case TypeEmballage.unit:
        piecesParUnite = 1;
        currentPrixUnitaire = prix;
        uniteLabel = "pièce(s)";
        currentColisType = "";
        break;
    }
  }

  // ✅ Fonction de vérification de quantité avec dialogue
  Future<bool> verifierQuantiteAvecDialogue(double qteSaisie) async {
    final double quantiteReelle = qteSaisie * piecesParUnite;
    if (quantiteReelle > quantiteDisponible) {
      final l10n = AppLocalizations.of(context)!;
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        titre_concerne: l10n.product,
        message: "Stock insuffisant !\nDisponible: ${quantiteDisponible.toInt()} pièce(s)\nDemandé: ${quantiteReelle.toInt()} pièce(s)",
      );
      return false;
    }
    return true;
  }

  void startAutoAddTimer() {
    autoAddTimer?.cancel();
    autoAddTimer = Timer(const Duration(seconds: 2), () async {
      if (!isEditing || (qteController.text.isEmpty)) {
        final qte = double.tryParse(qteController.text) ?? 1;
        updateEmballageInfo();

        if (await verifierQuantiteAvecDialogue(qte)) {
          if (selectedEmballage != TypeEmballage.unit) {
            onAjouter(qte, colisType: currentColisType, prixUnitaire: currentPrixUnitaire);
          } else {
            onAjouter(qte);
          }
          if (Navigator.canPop(context)) Navigator.pop(context);
        }
      }
    });
  }

  qteController.addListener(() {
    final text = qteController.text;
    if (text.isNotEmpty) {
      if (!isEditing) {
        isEditing = true;
        autoAddTimer?.cancel();
      }
    }
  });

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      final l10n = AppLocalizations.of(context);

      startAutoAddTimer();

      return StatefulBuilder(
        builder: (context, setState) {
          updateEmballageInfo();
          final double qteValue = double.tryParse(qteController.text) ?? 1;
          final int totalPieces = (qteValue * piecesParUnite).toInt();

          // ✅ Récupérer les dimensions de l'écran
          final screenHeight = MediaQuery.of(context).size.height;
          final screenWidth = MediaQuery.of(context).size.width;
          final bool isSmallScreen = screenWidth < 600;
          final bool isMediumScreen = screenWidth >= 600 && screenWidth < 900;
          final bool isLargeScreen = screenWidth >= 900;

          // ✅ Définir les hauteurs et dimensions en fonction de l'écran
          double dialogHeight;
          double imageHeight;
          double fontSizeTitle;
          double fontSizePrice;
          double spacing;

          if (isSmallScreen) {
            dialogHeight = hasBoite || hasCarton ? 620 : 550;
            imageHeight = 120;
            fontSizeTitle = 16;
            fontSizePrice = 14;
            spacing = 8;
          } else if (isMediumScreen) {
            dialogHeight = hasBoite || hasCarton ? 720 : 620;
            imageHeight = 180;
            fontSizeTitle = 20;
            fontSizePrice = 16;
            spacing = 12;
          } else {
            dialogHeight = hasBoite || hasCarton ? 820 : 700;
            imageHeight = 280;
            fontSizeTitle = 22;
            fontSizePrice = 18;
            spacing = 15;
          }

          // ✅ Ajuster la hauteur si l'écran est trop petit
          if (screenHeight < 700) {
            dialogHeight = hasBoite || hasCarton ? 520 : 480;
            imageHeight = 80;
            fontSizeTitle = 14;
            fontSizePrice = 12;
            spacing = 4;
          }

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: isSmallScreen ? screenWidth * 0.95 : (isMediumScreen ? 700 : 780),
                height: dialogHeight,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/produit_icon.png',
                  text: l10n.addProduct,
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildProductImage(photoName, height: imageHeight),
                      SizedBox(height: spacing),
                      Text(
                        nom,
                        style: Appstyle.textMB.copyWith(fontSize: fontSizeTitle),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: spacing / 2),
                      Text(
                        "${currentPrixUnitaire.toStringAsFixed(2)} DA / $uniteLabel",
                        style: Appstyle.textMB.copyWith(
                          fontSize: fontSizePrice,
                          color: Appstyle.violet,
                        ),
                      ),
                      SizedBox(height: spacing),

                      if (hasBoite || hasCarton) ...[
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                          decoration: BoxDecoration(
                            color: Appstyle.grisC.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Mode d'achat",
                                style: Appstyle.textMB.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 6 : 10),
                              Wrap(
                                spacing: isSmallScreen ? 4 : 10,
                                runSpacing: isSmallScreen ? 4 : 10,
                                children: [
                                  ChoiceChip(
                                    label: Column(
                                      children: [
                                        Text("À l'unité", style: TextStyle(fontSize: isSmallScreen ? 10 : 12)),
                                        Text(
                                          "${prix.toStringAsFixed(2)} DA/pièce",
                                          style: TextStyle(fontSize: isSmallScreen ? 8 : 10),
                                        ),
                                      ],
                                    ),
                                    selected: selectedEmballage == TypeEmballage.unit,
                                    onSelected: (_) {
                                      setState(() {
                                        selectedEmballage = TypeEmballage.unit;
                                        qteController.text = "1";
                                      });
                                    },
                                    selectedColor: Appstyle.violet,
                                    backgroundColor: Colors.grey[200],
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 4 : 8,
                                      vertical: isSmallScreen ? 4 : 8,
                                    ),
                                  ),
                                  if (hasBoite)
                                    ChoiceChip(
                                      label: Column(
                                        children: [
                                          Text(
                                            "Par boîte (${emballage1?.toInt()} pièces)",
                                            style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                                          ),
                                          Text(
                                            "${(emballageP1!).toStringAsFixed(2)} DA/boîte",
                                            style: TextStyle(fontSize: isSmallScreen ? 8 : 10),
                                          ),
                                        ],
                                      ),
                                      selected: selectedEmballage == TypeEmballage.boite,
                                      onSelected: (_) {
                                        setState(() {
                                          selectedEmballage = TypeEmballage.boite;
                                          qteController.text = "1";
                                        });
                                      },
                                      selectedColor: Appstyle.violet,
                                      backgroundColor: Colors.grey[200],
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 4 : 8,
                                        vertical: isSmallScreen ? 4 : 8,
                                      ),
                                    ),
                                  if (hasCarton)
                                    ChoiceChip(
                                      label: Column(
                                        children: [
                                          Text(
                                            "Par carton (${emballage2?.toInt()} pièces)",
                                            style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                                          ),
                                          Text(
                                            "${(emballageP2!).toStringAsFixed(2)} DA/carton",
                                            style: TextStyle(fontSize: isSmallScreen ? 8 : 10),
                                          ),
                                        ],
                                      ),
                                      selected: selectedEmballage == TypeEmballage.carton,
                                      onSelected: (_) {
                                        setState(() {
                                          selectedEmballage = TypeEmballage.carton;
                                          qteController.text = "1";
                                        });
                                      },
                                      selectedColor: Appstyle.violet,
                                      backgroundColor: Colors.grey[200],
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 4 : 8,
                                        vertical: isSmallScreen ? 4 : 8,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacing),
                      ],

                      // ✅ Champs de quantité avec responsive
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: isSmallScreen ? 80 : (isMediumScreen ? 100 : 120),
                            child: TextField(
                              controller: qteController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: isSmallScreen ? 16 : 20),
                              decoration: InputDecoration(
                                labelText: uniteLabel,
                                labelStyle: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 4 : 8,
                                  vertical: isSmallScreen ? 4 : 8,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                          if (selectedEmballage != TypeEmballage.unit) ...[
                            SizedBox(width: isSmallScreen ? 8 : 20),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 16,
                                vertical: isSmallScreen ? 6 : 12,
                              ),
                              decoration: BoxDecoration(
                                color: Appstyle.indigo.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Soit $totalPieces pièce(s)",
                                style: Appstyle.textMB.copyWith(
                                  color: Appstyle.indigo,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 10 : 14,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      SizedBox(height: spacing / 2),

                      // ✅ Affichage du stock disponible
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 12,
                          vertical: isSmallScreen ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: quantiteDisponible <= 0 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Stock disponible: ${quantiteDisponible.toInt()} pièce(s)",
                          style: Appstyle.textS.copyWith(
                            color: quantiteDisponible <= 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 10 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MainButton(
                      text: l10n.cancel,
                      color: Appstyle.gris,
                      icon: Icons.cancel,
                      width: isSmallScreen ? 110 : 140,
                      height: isSmallScreen ? 38 : 45,
                      onPressed: () {
                        autoAddTimer?.cancel();
                        Navigator.pop(context);
                      },
                    ),
                    MainButton(
                      text: l10n.add,
                      icon: Icons.add_shopping_cart,
                      color: Appstyle.violet,
                      width: isSmallScreen ? 110 : 140,
                      height: isSmallScreen ? 38 : 45,
                       onPressed: () async {
                        final qte = double.tryParse(qteController.text) ?? 1;
                        autoAddTimer?.cancel();
                        updateEmballageInfo();
                        if (await verifierQuantiteAvecDialogue(qte)) {
                          if (selectedEmballage != TypeEmballage.unit) {
                            onAjouter(qte, colisType: currentColisType, prixUnitaire: currentPrixUnitaire);
                          } else {
                            onAjouter(qte);
                          }
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Widget pour afficher la photo du produit avec hauteur adaptable
Widget _buildProductImage(String? photoName, {double height = 280}) {
  return Container(
    height: height,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Colors.grey[50],
      border: Border.all(
        color: Colors.grey[200]!,
        width: 1,
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _buildImageContent(photoName),
    ),
  );
}

Widget _buildImageContent(String? photoName) {
  // Si pas de photo ou photo vide
  if (photoName == null || photoName.isEmpty) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune photo',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Charger la photo depuis le service
  return FutureBuilder<File?>(
    future: PhotoService.getPhotoFile(photoName),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Container(
          color: Colors.grey[100],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (snapshot.hasData && snapshot.data != null && snapshot.data!.existsSync()) {
        return Image.file(
          snapshot.data!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorPlaceholder();
          },
        );
      }

      // Photo non trouvée
      return _buildNotFoundPlaceholder();
    },
  );
}

Widget _buildNotFoundPlaceholder() {
  return Container(
    color: Colors.grey[100],
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Image non trouvée',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildErrorPlaceholder() {
  return Container(
    color: Colors.grey[100],
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.orange[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}