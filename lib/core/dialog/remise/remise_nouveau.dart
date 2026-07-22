import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Remise.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/insertion_produit.dart';
import 'package:caisse_dz/core/widget/title/title_small.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/remise.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart'; // ✅ Ajout de l'import
import '../../../../data/constant.dart';
import '../../widget/button/ajouter_manuel.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/affichage_champ.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/date_champ.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';

// Modifiez la fonction RemiseNouveau
Future<void> RemiseNouveau(BuildContext context, {VoidCallback? onSuccess}) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredCreate,
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) => RemiseDialog(
      userName: auth.username!,
      userCode: auth.userCode!,
      onSuccess: onSuccess, // ✅ Passer le callback
    ),
  );
}

class RemiseDialog extends StatefulWidget {
  final String userName;
  final String userCode;
  final VoidCallback? onSuccess; // ✅ Ajouter le callback
  const RemiseDialog({
    Key? key,
    required this.userName,
    required this.userCode,
    this.onSuccess, // ✅ Ajouter le callback
  }) : super(key: key);

  @override
  State<RemiseDialog> createState() => _RemiseDialogState();
}

class _RemiseDialogState extends State<RemiseDialog> {
  // Controllers
  final TextEditingController nomController = TextEditingController();
  final TextEditingController tauxcontroller = TextEditingController();
  final TextEditingController dateDController = TextEditingController();
  final TextEditingController dateFController = TextEditingController();
  final TextEditingController observcontroller = TextEditingController();
  final TextEditingController montantController = TextEditingController();

  // Form key
  final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

  // State variables
  List<Produit> produitsRemise = [];
  List<Produit> produitsTest = [];
  String? remisetype;
  String? selectedRemiseType;
  String cd = '';
  String type = 'Par Produit';
  int id = 0;
  bool isRapide = true;
  bool isLoading = false;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    montantController.text = "0";
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _LoadAllData();
    final nextId = await _GetNextId();

    if (!mounted) return;

    // Initialize after build context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final translator = ListsConstTranslator(l10n);
      final displayList = translator.typeCalculDisplayList;

      setState(() {
        id = nextId;

        // ✅ Utilisation du générateur de code pour la remise
        cd = CodeGenerator.generateCode(
          prefix: CodePrefix.remise,
          id: id,
          digitCount: 6, // "REM000001"
        );

        remisetype = displayList.isNotEmpty ? displayList.first : 'Pourcentage';
        selectedRemiseType = remisetype;
        isInitialized = true;
      });
    });
  }

  Future<void> _LoadAllData() async {
    final result = await ProduitServices.getAllProduits();
    if (mounted) {
      setState(() => produitsTest = result);
    }
  }

  Future<int> _GetNextId() async {
    final db = await DbCreator.openDb();
    int newId = 0;
    await db.transaction((txn) async {
      newId = await RemiseServices.getNextremiseId(txn);
    });
    return newId;
  }

  Future<int> _GetNextHistoriqueId() async {
    final db = await DbCreator.openDb();
    int newId = 0;
    await db.transaction((txn) async {
      newId = await HistoriqueServices.getNextHistoriqueId(txn);
    });
    return newId;
  }

  Future<void> pickDate(
      BuildContext context,
      TextEditingController controller, {
        DateTime? minDate,
      }) async {
    DateTime initialDate = DateTime.now();

    if (controller.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(controller.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(minDate ?? initialDate)
          ? (minDate ?? initialDate)
          : initialDate,
      firstDate: minDate ?? DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Appstyle.violet,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        controller.text =
        "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void resetRemiseForm() {
    nomController.clear();
    tauxcontroller.clear();
    dateDController.clear();
    dateFController.clear();
    observcontroller.clear();
    montantController.clear();
    produitsRemise.clear();
  }

  Future<void> _SaveData({
    required Remise remise,
    required List<Produit> produits,
  }) async {
    final db = await DbCreator.openDb();
    final services = RemiseServices(db);
    final service = ProduitServices(db);

    await services.addRemise(remise);

    final int idH = await _GetNextHistoriqueId();
    final serviceh = await HistoriqueServices(db);
    final Historique histo = Historique(
      id: idH,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idH,
      ), // ✅ Utilisation du générateur
      desc: "l'utilisateur ${widget.userName} cree la Remise ${remise.nom}",
      type: "Remise",
      oper: ListsConst.typeHisto[0],
      creePar: widget.userName,
      dateCree: DateTime.now(),
      creeParCode: widget.userCode,
    );
    await serviceh.addHistorique(histo);

    for (var produit in produits) {
      produit.remise = remise.nom;
      produit.remiseId = remise.id;
      produit.modifPar = widget.userName;
      produit.dateModif = DateTime.now();

      await service.updateProduit(produit);

      final int idN = await _GetNextHistoriqueId();
      final Historique prodHisto = Historique(
        id: idN,
        code: CodeGenerator.generateCodeWithTimestamp(
          prefix: CodePrefix.historique,
          id: idN,
        ), // ✅ Utilisation du générateur
        desc: "l'utilisateur ${widget.userName} Ajoutee la Remise ${remise.nom} en Produit ${produit.nom}",
        type: "Produit",
        oper: ListsConst.typeHisto[1],
        creePar: widget.userName,
        dateCree: DateTime.now(),
        creeParCode: widget.userCode,
      );
      await serviceh.addHistorique(prodHisto);
    }
  }

  void _handleSave() async {
    final l10n = AppLocalizations.of(context)!;

    if (!produitFormKey.currentState!.validate()) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        titre_concerne: l10n.discount,
        message: l10n.fillRequiredFields,
      );
      return;
    }

    if (nomController.text.isEmpty ||
        dateDController.text.isEmpty ||
        dateFController.text.isEmpty ||
        tauxcontroller.text.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        titre_concerne: l10n.discount,
        message: l10n.fillRequiredFields,
      );
      return;
    }

    if (isRapide && produitsRemise.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        titre_concerne: l10n.discount,
        message: "Veuillez ajouter au moins un produit",
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final l10n = AppLocalizations.of(context)!;
      final translator = ListsConstTranslator(l10n);

      final remise = Remise(
        id: id,
        code: cd,
        nom: nomController.text,
        observation: observcontroller.text,
        debut: DateTime.parse(dateDController.text),
        fin: DateTime.tryParse(dateFController.text),
        type: type,
        taux: double.parse(tauxcontroller.text),
        tauxType: selectedRemiseType ?? 'Pourcentage',
        montant: double.tryParse(montantController.text),
        creeLe: DateTime.now(),
        creePar: widget.userName,
        etat: true,
        creeParCode: widget.userCode,
      );

      await _SaveData(
        remise: remise,
        produits: produitsRemise,
      );

      if (mounted) {
        setState(() => isLoading = false);
        await InformationDialog(
          context: context,
          titre_type_message: l10n.success,
          titre_concerne: l10n.discount,
          message: l10n.discountSavedSuccess,
          onTerminer: () {
            resetRemiseForm();
            Navigator.pop(context);
            // ✅ Appeler le callback après la fermeture
            if (widget.onSuccess != null) {
              widget.onSuccess!();
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        final l10n = AppLocalizations.of(context)!;
        await InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          titre_concerne: l10n.discount,
          message: "${l10n.errorOccurred}: $e",
        );
      }
    }
  }

  @override
  void dispose() {
    nomController.dispose();
    tauxcontroller.dispose();
    dateDController.dispose();
    dateFController.dispose();
    observcontroller.dispose();
    montantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);

    if (!isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: BaseDialog(
          width: 900,
          header: TitreAvecLigne(
            imagePath: 'assets/icons/cardwidget/remise_icon.png',
            text: l10n.newDiscount,
          ),
          content: Form(
            key: produitFormKey,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Toggle buttons
                      Container(
                        decoration: BoxDecoration(
                          color: Appstyle.grisC.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildToggleButton(
                              text: l10n.byProduct,
                              isActive: isRapide,
                              onTap: () {
                                if (!isRapide) {
                                  setState(() {
                                    isRapide = true;
                                    type = "Par Produit";
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildToggleButton(
                              text: l10n.byAmount,
                              isActive: !isRapide,
                              onTap: () {
                                if (isRapide) {
                                  setState(() {
                                    isRapide = false;
                                    type = "Par Montant";
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Content based on selection
                      if (isRapide)
                        _buildRemiseParProduit(l10n, translator)
                      else
                        _buildRemiseParMontant(l10n, translator),
                    ],
                  ),
                ),
              ),
            ),
          ),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              MainButton(
                text: l10n.cancel,
                color: Appstyle.gris,
                icon: Icons.cancel,
                onPressed: () {
                  resetRemiseForm();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 10),
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                MainButton(
                  text: l10n.save,
                  color: Appstyle.violet,
                  icon: Icons.save,
                  onPressed: _handleSave,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String text,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Appstyle.crevete : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRemiseParProduit(
      AppLocalizations l10n,
      ListsConstTranslator translator,
      ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ChampAvecLabel(
                          label: l10n.reference,
                          child: AffichageChamp(text: cd),
                        ),
                        const SizedBox(height: 20),
                        ChampAvecLabel(
                          obligatoire: true,
                          label: l10n.name,
                          child: TextChampL(
                            obligatoire: true,
                            controller: nomController,
                            hint: l10n.discountNameHint,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ChampAvecLabel(
                          obligatoire: true,
                          label: l10n.start,
                          child: TextDate(
                            obligatoire: true,
                            hint: "15 nov 2025",
                            controller: dateDController,
                            onTap: () => pickDate(context, dateDController),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ChampAvecLabel(
                          obligatoire: true,
                          label: l10n.end,
                          child: TextDate(
                            obligatoire: true,
                            controller: dateFController,
                            hint: '15 Nov 2025',
                            onTap: () {
                              if (dateDController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.pleaseSelectStartDateFirst)),
                                );
                                return;
                              }
                              final debutDate = DateTime.parse(dateDController.text);
                              pickDate(context, dateFController, minDate: debutDate);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ChampAvecLabel(
                          obligatoire: true,
                          label: l10n.rateType,
                          child: TextListe(
                            clearable: false,
                            value: remisetype,
                            items: translator.typeCalculDisplayList,
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  remisetype = v;
                                  selectedRemiseType = translator.typeCalculToFrench(v);
                                  tauxcontroller.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ChampAvecLabel(
                                obligatoire: true,
                                label: l10n.discountRate,
                                child: TextChampL(
                                  maxValue: _isPercentage() ? 100 : null,
                                  numeric: true,
                                  obligatoire: true,
                                  controller: tauxcontroller,
                                  hint: _isPercentage() ? '20%' : '1000 DA',
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.requiredField;
                                    }
                                    final double? taux = double.tryParse(value);
                                    if (taux == null) {
                                      return l10n.invalidNumber;
                                    }
                                    if (_isPercentage() && taux > 100) {
                                      return l10n.percentageExceeds100;
                                    }
                                    if (taux < 0) {
                                      return l10n.valueMustBePositive;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isPercentage() ? "%" : l10n.currency,
                              style: Appstyle.textMB.copyWith(
                                color: Appstyle.violet,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ChampAvecLabel(
                          label: l10n.observation,
                          child: TextChampL(
                            controller: observcontroller,
                            hint: l10n.observationHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // Products section
        TitleSmall(
          imagePath: 'assets/icons/sidebar/produit_icon.png',
          text: l10n.productsConcerned,
          couleur: Appstyle.violet,
        ),
        const SizedBox(height: 10),
        _headerTableProduitsRemise(l10n),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: _tableProduitsRemise(l10n),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _ouvrirInsertionProduitRemise(context, l10n),
          child: const AddManualWidget(),
        ),
      ],
    );
  }

  Widget _buildRemiseParMontant(
      AppLocalizations l10n,
      ListsConstTranslator translator,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChampAvecLabel(
                      label: l10n.reference,
                      child: AffichageChamp(text: cd),
                    ),
                    const SizedBox(height: 20),
                    ChampAvecLabel(
                      obligatoire: true,
                      label: l10n.name,
                      child: TextChampL(
                        obligatoire: true,
                        controller: nomController,
                        hint: l10n.discountNameHint,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ChampAvecLabel(
                      obligatoire: true,
                      label: l10n.start,
                      child: TextDate(
                        obligatoire: true,
                        hint: "15 nov 2025",
                        controller: dateDController,
                        onTap: () => pickDate(context, dateDController),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ChampAvecLabel(
                      obligatoire: true,
                      label: l10n.end,
                      child: TextDate(
                        obligatoire: true,
                        controller: dateFController,
                        hint: '15 Nov 2025',
                        onTap: () {
                          if (dateDController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.pleaseSelectStartDateFirst)),
                            );
                            return;
                          }
                          final debutDate = DateTime.parse(dateDController.text);
                          pickDate(context, dateFController, minDate: debutDate);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChampAvecLabel(
                      obligatoire: true,
                      label: l10n.greaterThan,
                      child: TextChampL(
                        obligatoire: true,
                        controller: montantController,
                        hint: l10n.discountApplicationAmount,
                        numeric: true,
                        validator: (value) {
                          // ✅ Validation : champ non vide
                          if (value == null || value.trim().isEmpty) {
                            return l10n.requiredField;
                          }

                          // ✅ Nettoyer la valeur (remplacer les virgules par des points)
                          final String cleanValue = value.trim().replaceAll(',', '.');
                          final double? montant = double.tryParse(cleanValue);

                          // ✅ Validation : nombre valide
                          if (montant == null) {
                            return l10n.invalidNumber;
                          }

                          // ✅ Validation : doit être strictement supérieur à 0
                          if (montant <= 0) {
                            return l10n.valueMustBeGreaterThanZero; // "La valeur doit être supérieure à 0"
                          }

                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    ChampAvecLabel(
                      obligatoire: true,
                      label: l10n.rateType,
                      child: TextListe(
                        obligatoire: true,
                        value: remisetype,
                        clearable: false,
                        items: translator.typeCalculDisplayList,
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              remisetype = v;
                              selectedRemiseType = translator.typeCalculToFrench(v);
                              tauxcontroller.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChampAvecLabel(
                            obligatoire: true,
                            label: l10n.discountRate,
                            child: TextChampL(
                              obligatoire: true,
                              controller: tauxcontroller,
                              hint: _isPercentage() ? '0 - 100%' : '1500 Da',
                              numeric: true,
                              maxValue: _isPercentage() ? 100 : null,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.requiredField;
                                }
                                final double? taux = double.tryParse(value);
                                if (taux == null) {
                                  return l10n.invalidNumber;
                                }
                                if (_isPercentage() && taux > 100) {
                                  return l10n.percentageExceeds100;
                                }
                                if (taux < 0) {
                                  return l10n.valueMustBePositive;
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isPercentage() ? "%" : l10n.currency,
                          style: Appstyle.textMB.copyWith(
                            color: Appstyle.violet,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ChampAvecLabel(
                      label: l10n.observation,
                      child: TextChampL(
                        controller: observcontroller,
                        hint: l10n.observationHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isPercentage() {
    if (selectedRemiseType == null) return true;
    return selectedRemiseType!.toLowerCase().contains('pourcentage') ||
        selectedRemiseType!.toLowerCase().contains('percentage');
  }

  Widget _tableProduitsRemise(AppLocalizations l10n) {
    if (produitsRemise.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          l10n.noProductsAdded,
          style: Appstyle.textSB.copyWith(color: Appstyle.gris),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: produitsRemise.length,
      itemBuilder: (context, index) {
        final produit = produitsRemise[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  produit.code,
                  style: Appstyle.textSB,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  produit.nom,
                  style: Appstyle.textSB,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  produit.remise ?? "-",
                  style: Appstyle.textSB,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 40,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      produitsRemise.removeAt(index);
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerTableProduitsRemise(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Appstyle.gris.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              l10n.code,
              style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              l10n.product,
              style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              l10n.currentDiscount,
              style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  void _ouvrirInsertionProduitRemise(
      BuildContext context,
      AppLocalizations l10n,
      ) {
    showDialog(
      context: context,
      builder: (_) => InsertionProduitDialog(
        multiselection: true,
        produits: produitsTest,
        onProduitSelected: (Produit produit) {
          setState(() {
            if (!produitsRemise.any((p) => p.id == produit.id)) {
              produitsRemise.add(produit);
            }
          });
        },
      ),
    );
  }
}