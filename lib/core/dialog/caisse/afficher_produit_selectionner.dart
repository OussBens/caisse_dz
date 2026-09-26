import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import '../../../Services/Photos.dart';
import '../../utilis/quantite_format.dart';

import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

// Enum pour les types d'emballage
enum TypeEmballage { unit, boite, carton }

Future<void> afficherProduitSelectionneDialog({
  required BuildContext context,
  required String nom,
  required double prix,
  required String? photoName,
  required Function(double qte, {String? colisType, double? prixUnitaire}) onAjouter,
  // ✅ Expose la validation courante (équivalent du bouton "Ajouter") à
  // l'appelant, pour qu'un nouveau scan pendant que ce dialog est ouvert
  // puisse valider le produit affiché avant d'enchaîner sur le suivant.
  void Function(Future<void> Function() confirmerAjout)? onControllerReady,
  double? emballage1,
  double? emballageP1,
  double? emballage2,
  double? emballageP2,
  String? defaultColisType,
  required double quantiteDisponible,
}) async {
  final qteController = TextEditingController(text: "1");
  // Texte pré-sélectionné : avec autofocus, taper un chiffre remplace
  // directement "1" au lieu de le compléter — manipulation rapide de la qtt.
  qteController.selection = TextSelection(baseOffset: 0, extentOffset: qteController.text.length);
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
  String uniteLabel = "";
  String currentColisType = "";

  void updateEmballageInfo() {
    final l10n = AppLocalizations.of(context)!;
    switch (selectedEmballage) {
      case TypeEmballage.boite:
        piecesParUnite = emballage1?.toInt() ?? 1;
        currentPrixUnitaire = emballageP1 ?? prix;
        uniteLabel = l10n.boxesUnit;
        currentColisType = "${l10n.perBoxOption} (${emballage1?.toInt()} ${l10n.piecesUnit})";
        break;
      case TypeEmballage.carton:
        piecesParUnite = emballage2?.toInt() ?? 1;
        currentPrixUnitaire = emballageP2 ?? prix;
        uniteLabel = l10n.cartonsUnit;
        currentColisType = "${l10n.perCartonOption} (${emballage2?.toInt()} ${l10n.piecesUnit})";
        break;
      case TypeEmballage.unit:
        piecesParUnite = 1;
        currentPrixUnitaire = prix;
        uniteLabel = l10n.piecesUnit;
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
        message: l10n.insufficientStockDetail(
          quantiteReelle.toInt(),
          quantiteDisponible.toInt(),
        ),
      );
      return false;
    }
    return true;
  }

  // ✅ Valide le produit affiché avec la quantité/l'emballage courants
  // (même logique que le bouton "Ajouter"), utilisée à la fois par le
  // minuteur d'ajout auto et par le bouton, et exposée via
  // [onControllerReady] pour être déclenchée depuis l'extérieur (nouveau
  // scan pendant que ce dialog est ouvert).
  Future<void> confirmerAjout() async {
    final qte = double.tryParse(qteController.text.replaceAll(',', '.')) ?? 1;
    autoAddTimer?.cancel();
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

  void startAutoAddTimer() {
    autoAddTimer?.cancel();
    autoAddTimer = Timer(const Duration(seconds: 2), () async {
      if (!isEditing || (qteController.text.isEmpty)) {
        await confirmerAjout();
      }
    });
  }

  onControllerReady?.call(confirmerAjout);

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
          final double qteValue = double.tryParse(qteController.text.replaceAll(',', '.')) ?? 1;
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
                      _buildProductImage(photoName, context: context, height: imageHeight),
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
                        "${NumberFormatUtil.formatMontant(currentPrixUnitaire, decimales: 2)} ${l10n.currency} / $uniteLabel",
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
                                l10n.purchaseMode,
                                style: Appstyle.textMB.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 6 : 10),
                              // Dans la section des ChoiceChip, modifiez chaque ChoiceChip comme suit :

                              Wrap(
                                spacing: isSmallScreen ? 4 : 10,
                                runSpacing: isSmallScreen ? 4 : 10,
                                children: [
                                  ChoiceChip(
                                    label: Column(
                                      children: [
                                        Text(
                                          l10n.perUnitOption,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10 : 12,
                                            // ✅ Texte blanc quand sélectionné, noir sinon
                                            color: selectedEmballage == TypeEmballage.unit ? Colors.white : Colors.black,
                                          ),
                                        ),
                                        Text(
                                          "${NumberFormatUtil.formatMontant(prix, decimales: 2)} ${l10n.currency}/${l10n.piecesUnit}",
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 8 : 10,
                                            // ✅ Texte blanc quand sélectionné, noir sinon
                                            color: selectedEmballage == TypeEmballage.unit ? Colors.white : Colors.grey[700],
                                          ),
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
                                            "${l10n.perBoxOption} (${emballage1?.toInt()} ${l10n.piecesUnit})",
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 10 : 12,
                                              // ✅ Texte blanc quand sélectionné, noir sinon
                                              color: selectedEmballage == TypeEmballage.boite ? Colors.white : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            "${NumberFormatUtil.formatMontant((emballageP1!), decimales: 2)} ${l10n.currency}/${l10n.boxesUnit}",
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 8 : 10,
                                              // ✅ Texte blanc quand sélectionné, noir sinon
                                              color: selectedEmballage == TypeEmballage.boite ? Colors.white : Colors.grey[700],
                                            ),
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
                                            "${l10n.perCartonOption} (${emballage2?.toInt()} ${l10n.piecesUnit})",
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 10 : 12,
                                              // ✅ Texte blanc quand sélectionné, noir sinon
                                              color: selectedEmballage == TypeEmballage.carton ? Colors.white : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            "${NumberFormatUtil.formatMontant((emballageP2!), decimales: 2)} ${l10n.currency}/${l10n.cartonsUnit}",
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 8 : 10,
                                              // ✅ Texte blanc quand sélectionné, noir sinon
                                              color: selectedEmballage == TypeEmballage.carton ? Colors.white : Colors.grey[700],
                                            ),
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
                              autofocus: true,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: QuantiteFormat.inputFormatters,
                              textInputAction: TextInputAction.done,
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
                              // ✅ Touche Entrée du clavier = même action que le bouton "Ajouter"
                              onSubmitted: (_) => confirmerAjout(),
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
                                l10n.equalToPieces(totalPieces),
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
                          l10n.availableStockPieces(quantiteDisponible.toInt()),
                          style: Appstyle.textM.copyWith(
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
                       onPressed: confirmerAjout,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    // Garantit l'arrêt du timer d'ajout auto même si le dialog est fermé
    // par un moyen externe (ex: un nouveau scan qui referme celui-ci).
    autoAddTimer?.cancel();
  });
}

/// Widget pour afficher la photo du produit avec hauteur adaptable
Widget _buildProductImage(String? photoName, {required BuildContext context, double height = 280}) {
  return Container(
    height: height,
    width: height*3/2,
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
      child: _buildImageContent(photoName, context),
    ),
  );
}

Widget _buildImageContent(String? photoName, BuildContext context) {
  // Si pas de photo ou photo vide : même placeholder que CardProduct
  // (boîte violette + icône produit) pour une présentation cohérente.
  if (photoName == null || photoName.isEmpty) {
    return _buildNoPhotoPlaceholder();
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
            return _buildErrorPlaceholder(context);
          },
        );
      }

      // Photo non trouvée
      return _buildNotFoundPlaceholder(context);
    },
  );
}

/// Placeholder pour un produit sans photo : reprend le style utilisé dans
/// CardProduct (fond violet translucide + icône de produit).
Widget _buildNoPhotoPlaceholder() {
  return Container(
    color: Appstyle.violet.withOpacity(0.1),
    child: Center(
      child: Icon(
        Icons.inventory_2,
        size: 64,
        color: Appstyle.violet.withOpacity(0.6),
      ),
    ),
  );
}

Widget _buildNotFoundPlaceholder(BuildContext context) {
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
            AppLocalizations.of(context).imageNotFound,
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

Widget _buildErrorPlaceholder(BuildContext context) {
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
            AppLocalizations.of(context).loadingError,
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