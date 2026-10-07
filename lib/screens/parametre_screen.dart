import 'dart:io';

import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/BackupParam.dart';
import 'package:caisse_dz/Services/BackupService.dart';
import 'package:caisse_dz/Services/EntrepriseParam.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/ImprimanteParam.dart';
import 'package:caisse_dz/Services/LogoService.dart';
import 'package:caisse_dz/Services/PaiementParam.dart';
import 'package:caisse_dz/Services/ParamZakat.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/Services/printer_manager.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/utilis/quantite_format.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/backupParam.dart';
import 'package:caisse_dz/data/models/entrepriseParam.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/imprimanteParam.dart';
import 'package:caisse_dz/data/models/paiementParam.dart';
import 'package:caisse_dz/data/models/paramZakat.dart';
import 'package:caisse_dz/data/models/paramters.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart' as printing_pkg;
import 'package:provider/provider.dart';
import '../core/theme/app_style.dart';
import '../core/utilis/constant.dart';
import '../l10n/app_localizations.dart';
import '../core/locale/locale_provider.dart';

// 👇 IMPORT SAME WIDGETS AS DIALOG
import '../core/widget/champ/champ_avec_label.dart';
import '../core/widget/champ/text_champ_l.dart';
import '../core/widget/champ/liste_champ.dart';
import '../core/widget/time_date_widget.dart';
import '../core/widget/connection_status_bar.dart';
import '../core/widget/header_module.dart';
import '../core/widget/account.dart';
import '../core/widget/button/main_button.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

class ParametreScreen extends StatefulWidget {
  const ParametreScreen({super.key});

  @override
  State<ParametreScreen> createState() => _ParametreScreenState();
}

class _ParametreScreenState extends State<ParametreScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // ✅ Constantes pour les index des tabs
  static const int TAB_SYSTEME = 0;
  static const int TAB_MAGASIN = 1;
  static const int TAB_AVANCE = 2;

  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController appIdController = TextEditingController();

  String? selectedLanguage = "fr";
  String? selectedCurrency = "DZD";
  String? selectedMagasin = "";
  String? selectedMagasinId = "";

  // Paramètre système global (table parametre) : décimales quantité, marge
  // par défaut, seuils min/max — regroupés ici depuis l'onglet "Paramètre"
  // qui existait auparavant dans l'écran Produit.
  Paramters? _paramGeneral;
  int _decimalesQuantite = 0;
  String? selectedtypecacul;
  // Comportement de la caisse quand une vente passe sous le prix d'achat —
  // voir Paramters.venteSousAchat / ListsConst.typeVenteSousAchat.
  String? selectedVenteSousAchat;
  final TextEditingController tauxController = TextEditingController();
  final TextEditingController minController = TextEditingController();
  final TextEditingController maxController = TextEditingController();

  // Programme de bonus/fidélité — voir Paramters.activeBonus/bonusTaux.
  bool _activeBonus = false;
  final TextEditingController bonusTauxController = TextEditingController();

  // Second stock parallèle "Nombre" — voir Paramters.activeNombreQuantite.

  bool _isSavingAll = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Available options
  final List<String> availableLanguages = const ["fr", "en", "ar"];
  final List<String> availableCurrencies = const ["DZD", "EUR", "USD"];

  // ==========================================================
  // 1. INFORMATIONS GÉNÉRALES (boutique)
  // ==========================================================
  final _nomBoutiqueController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _rcController = TextEditingController();
  final _nifController = TextEditingController();
  final _nisController = TextEditingController();
  final _articleController = TextEditingController();
  final _messageTicketController = TextEditingController();
  EntrepriseParam? _entrepriseParam;
  String? _logoPath;
  File? _pickedLogoFile;

  // ==========================================================
  // 2. MODES DE PAIEMENT
  // ==========================================================
  PaiementParam? _paiementParam;
  bool _especesVisible = true;
  bool _carteVisible = true;
  bool _chequeVisible = true;
  bool _virementVisible = true;

  // ==========================================================
  // 3. PÉRIPHÉRIQUES & IMPRESSION
  // ==========================================================
  ImprimanteParam? _imprimanteParam;
  String _typeImprimante = TypeImprimante.bluetooth;
  String? _selectedPrinterName;
  List<String> _availablePrinterNames = [];
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '9100');
  int _largeurRouleau = 80;
  bool _isLoadingPrinters = false;

  // ==========================================================
  // 4. SAUVEGARDE
  // ==========================================================
  BackupParam? _backupParam;
  String? _dossierBackup;
  // ✅ Dossier de stockage de tous les fichiers générés (Excel, factures/BL
  // PDF...) — voir lib/Services/ExportStorage.dart pour son utilisation.
  String? _dossierDocuments;
  bool _autoBackupActif = false;
  String _frequence = FrequenceBackup.demarrage;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  // ==========================================================
  // 5. ZAKAT (regroupé ici depuis l'onglet "Paramètre" de l'écran Zakat)
  // ==========================================================
  ParamZakat? _paramZakat;
  final TextEditingController _nisabController = TextEditingController();
  final TextEditingController _tauxZakatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserParameters();
    _loadEntrepriseParam();
    _loadPaiementParam();
    _loadImprimanteParam();
    _loadBackupParam();
    _loadParamGeneral();
    _loadParamZakat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    nomController.dispose();
    prenomController.dispose();
    shopNameController.dispose();
    appIdController.dispose();
    _nomBoutiqueController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _rcController.dispose();
    _nifController.dispose();
    _nisController.dispose();
    _articleController.dispose();
    _messageTicketController.dispose();
    _ipController.dispose();
    _portController.dispose();
    tauxController.dispose();
    minController.dispose();
    maxController.dispose();
    bonusTauxController.dispose();
    _nisabController.dispose();
    _tauxZakatController.dispose();
    super.dispose();
  }

  Future<void> _loadUserParameters() async {
    final auth = Provider.of<AuthState>(context, listen: false);

    // Load user info
    if (auth.userCode != null) {
      final utilisateur = await UtilisateurServices.getUtilisateurByCode(auth.userCode!);
      nomController.text = utilisateur?.nom ?? "";
      prenomController.text = utilisateur?.prenom ?? "";
    }

    // Load user parameters from AuthState
    final userParam = auth.userParam;
    if (userParam != null) {
      setState(() {
        selectedLanguage = userParam.language ?? "fr";
        selectedCurrency = userParam.currency ?? "DZD";
        selectedMagasin = userParam.magasin;
        selectedMagasinId = userParam.magasinid;
        shopNameController.text = userParam.magasin ?? "";
        appIdController.text = userParam.magasinid ?? "";
      });
    } else {
      // Set defaults
      setState(() {
        selectedLanguage = auth.currentLanguage ?? "fr";
        selectedCurrency = auth.currentCurrency ?? "DZD";
        selectedMagasin = auth.currentMagasin;
        selectedMagasinId = auth.currentMagasinId;
        shopNameController.text = auth.currentMagasin ?? "";
        appIdController.text = auth.currentMagasinId ?? "";
      });
    }
  }

  /// Sauvegarde les paramètres utilisateur (langue, devise, magasin).
  /// Retourne `null` en cas de succès, sinon le message d'erreur réel —
  /// agrégé et affiché par [_saveAll].
  Future<String?> _saveUserParams() async {
    final auth = Provider.of<AuthState>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    if (auth.userCode != null) {
      final utilisateur = await UtilisateurServices.getUtilisateurByCode(auth.userCode!);
      if (utilisateur != null) {
        utilisateur.nom = nomController.text.trim();
        utilisateur.prenom = prenomController.text.trim();
        utilisateur.dateModif = DateTime.now();
        utilisateur.modifParCode = auth.userCode;
        final db = await DbCreator.openDb();
        final response = await UtilisateurServices(db).updateUtilisateur(utilisateur);
        if (!response.success) {
          return response.message;
        }
      }
    }

    final error = await auth.updateUserParameters(
      language: selectedLanguage!,
      currency: selectedCurrency!,
      magasin: shopNameController.text,
      magasinId: appIdController.text,
      modifiedBy: auth.username!,
      modifiedByCode: auth.userCode!,
      reason: "Parameter update from settings screen",
    );

    if (error != null) {
      debugPrint('_saveUserParams failed: $error');
    } else if (selectedLanguage != auth.currentLanguage) {
      await localeProvider.setLocale(selectedLanguage!);
    }

    return error;
  }

  // ==========================================================
  // PARAMÈTRE SYSTÈME (décimales + marge + seuils) — chargement / sauvegarde
  // ==========================================================

  Future<void> _loadParamGeneral() async {
    final param = await ParamServices.getParam();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);
    setState(() {
      _paramGeneral = param;
      _decimalesQuantite = param.decimalesQuantite;
      selectedtypecacul = translator.translateTypeCalcul(param.typeMarge);
      tauxController.text = param.typeMarge == "Montant"
          ? param.TauxMargeMontant.toString()
          : param.TauxMargePerncetage.toString();
      minController.text = param.Minimum.toString();
      maxController.text = param.Maximum.toString();
      _activeBonus = param.activeBonus;
      bonusTauxController.text = param.bonusTaux.toString();
      selectedVenteSousAchat = translator.translateVenteSousAchat(param.venteSousAchat);
    });
  }

  /// Sauvegarde décimales + type/taux de marge + seuils min/max en une seule
  /// écriture de la ligne `parametre` — même modèle que l'ancien onglet
  /// "Paramètre" de l'écran Produit (`_saveParam`), désormais centralisé ici.
  Future<String?> _saveParamGeneral() async {
    final userCode = _userCode;
    if (userCode == null) return 'not logged in';

    final param = _paramGeneral;
    if (param == null) return null;

    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);
    final frenchTypeCalcul = translator.typeCalculToFrench(
      selectedtypecacul ?? translator.translateTypeCalcul(param.typeMarge),
    );

    final double? tauxInput = tauxController.text.trim().isEmpty
        ? null
        : double.tryParse(tauxController.text);
    final double? minInput = minController.text.trim().isEmpty
        ? null
        : double.tryParse(minController.text);
    final double? maxInput = maxController.text.trim().isEmpty
        ? null
        : double.tryParse(maxController.text);
    final double? bonusTauxInput = bonusTauxController.text.trim().isEmpty
        ? null
        : double.tryParse(bonusTauxController.text);

    param
      ..typeMarge = frenchTypeCalcul
      ..TauxMargePerncetage = frenchTypeCalcul == "Pourcentage"
          ? (tauxInput ?? param.TauxMargePerncetage)
          : param.TauxMargePerncetage
      ..TauxMargeMontant = frenchTypeCalcul == "Montant"
          ? (tauxInput ?? param.TauxMargeMontant)
          : param.TauxMargeMontant
      ..Minimum = minInput ?? param.Minimum
      ..Maximum = maxInput ?? param.Maximum
      ..decimalesQuantite = _decimalesQuantite
      ..activeBonus = _activeBonus
      ..bonusTaux = bonusTauxInput ?? param.bonusTaux
      ..venteSousAchat = translator.venteSousAchatToFrench(
        selectedVenteSousAchat ?? translator.translateVenteSousAchat(param.venteSousAchat),
      )
      ..modifParCode = userCode
      ..Datemodif = DateTime.now();

    final db = await DbCreator.openDb();
    final result = await ParamServices(db).updateParam(param);

    if (result <= 0) return 'update failed';

    QuantiteFormat.decimales = _decimalesQuantite;

    final auth = Provider.of<AuthState>(context, listen: false);
    final int idH = await _GetNextHistoriqueId();
    final serviceh = await HistoriqueServices(db);
    await serviceh.addHistorique(Historique(
      id: idH,
      code: "HS $idH ${DateTime.now().microsecondsSinceEpoch}",
      desc: "${l10n.modification} ${l10n.systemSettings} ${l10n.by} ${auth.username}",
      oper: 'modification',
      type: 'paramter',
      dateCree: DateTime.now(),
      creeParCode: userCode,
    ));

    if (mounted) setState(() => _paramGeneral = param);
    return null;
  }

  // ==========================================================
  // ZAKAT — chargement / sauvegarde
  // ==========================================================

  Future<void> _loadParamZakat() async {
    final param = await ParamZAKATServices.getParamZakat();
    if (!mounted) return;
    setState(() {
      _paramZakat = param;
      _nisabController.text = param.Nissab.toString();
      _tauxZakatController.text = param.Taux.toString();
    });
  }

  Future<String?> _saveParamZakat() async {
    final userCode = _userCode;
    if (userCode == null) return 'not logged in';

    final current = _paramZakat;
    if (current == null) return null;

    final nisabInput = double.tryParse(_nisabController.text.trim());
    final tauxInput = double.tryParse(_tauxZakatController.text.trim());
    if (nisabInput == null || tauxInput == null) return 'invalid value';

    final updated = ParamZakat(
      id: current.id,
      Nissab: nisabInput,
      Taux: tauxInput,
      creeParCode: current.creeParCode,
      dateCree: current.dateCree,
      modifParCode: userCode,
      dateModif: DateTime.now(),
    );

    final db = await DbCreator.openDb();
    final response = await ParamZAKATServices(db).updateZakat(updated);

    if (!response.success) {
      debugPrint('_saveParamZakat failed: ${response.message}');
      return response.message;
    }

    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthState>(context, listen: false);
    final int idH = await _GetNextHistoriqueId();
    final serviceh = await HistoriqueServices(db);
    await serviceh.addHistorique(Historique(
      id: idH,
      code: "HS $idH ${DateTime.now().microsecondsSinceEpoch}",
      desc: "${l10n.modificationOf} ${l10n.zakatParameter} ${l10n.by} ${auth.username}",
      oper: ListsConst.typeHisto[2],
      type: 'paramter',
      dateCree: DateTime.now(),
      creeParCode: userCode,
    ));

    if (mounted) setState(() => _paramZakat = updated);
    return null;
  }

  /// Point d'entrée unique du bouton "Sauvegarder" : valide le formulaire puis
  /// enregistre toutes les sections de paramètres (des 3 onglets) et affiche
  /// un seul message.
  Future<void> _saveAll() async {
    if (!formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthState>(context, listen: false);

    if (!auth.isLoggedIn) {
      _snack(l10n.pleaseLoginFirst, error: true);
      return;
    }

    setState(() => _isSavingAll = true);
    try {
      final results = <String, String?>{
        'Utilisateur': await _saveUserParams(),
        'Boutique': await _saveEntrepriseParam(),
        'Paiement': await _savePaiementParam(),
        'Imprimante': await _saveImprimanteParam(),
        'Sauvegarde': await _saveBackupParam(),
        'Système': await _saveParamGeneral(),
        'Zakat': await _saveParamZakat(),
      };

      final failed = results.entries.where((e) => e.value != null).toList();
      final allOk = failed.isEmpty;

      _snack(
        allOk
            ? l10n.settingsSaved
            : '${l10n.errorSavingSettings} : '
                '${failed.map((e) => '${e.key} (${e.value})').join(", ")}',
        error: !allOk,
      );
    } catch (e, stack) {
      debugPrint('_saveAll exception: $e\n$stack');
      _snack('${l10n.errorSavingSettings}: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSavingAll = false);
    }
  }

  String? get _userCode =>
      Provider.of<AuthState>(context, listen: false).userCode;

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  // ==========================================================
  // 1. INFORMATIONS GÉNÉRALES — chargement / sauvegarde
  // ==========================================================

  Future<void> _loadEntrepriseParam() async {
    final param = await EntrepriseParamServices.getEntrepriseParam();
    if (!mounted) return;
    setState(() {
      _entrepriseParam = param;
      _nomBoutiqueController.text = param.nomBoutique;
      _adresseController.text = param.adresse ?? '';
      _telephoneController.text = param.telephone ?? '';
      _emailController.text = param.email ?? '';
      _rcController.text = param.rc ?? '';
      _nifController.text = param.nif ?? '';
      _nisController.text = param.nis ?? '';
      _articleController.text = param.article ?? '';
      _messageTicketController.text = param.messageTicket ?? '';
      _logoPath = param.logoPath;
    });
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedLogoFile = File(result.files.first.path!);
      });
    }
  }

  Future<String?> _saveEntrepriseParam() async {
    final userCode = _userCode;
    if (userCode == null) return 'not logged in';

    String? logoPath = _logoPath;
    if (_pickedLogoFile != null) {
      logoPath = await LogoService.saveLogo(_pickedLogoFile!) ?? logoPath;
    }

    final param = _entrepriseParam ?? EntrepriseParam(id: 1, nomBoutique: '');
    param
      ..nomBoutique = _nomBoutiqueController.text
      ..adresse = _adresseController.text
      ..telephone = _telephoneController.text
      ..email = _emailController.text
      ..rc = _rcController.text
      ..nif = _nifController.text
      ..nis = _nisController.text
      ..article = _articleController.text
      ..messageTicket = _messageTicketController.text
      ..logoPath = logoPath;

    final db = await DbCreator.openDb();
    final response = await EntrepriseParamServices(
      db,
    ).updateEntrepriseParam(param, userCode);

    if (response.success) {
      if (mounted) {
        setState(() {
          _entrepriseParam = param;
          _logoPath = logoPath;
          _pickedLogoFile = null;
        });
      }
      return null;
    }
    debugPrint('_saveEntrepriseParam failed: ${response.message}');
    return response.message;
  }

  // ==========================================================
  // 2. MODES DE PAIEMENT — chargement / sauvegarde
  // ==========================================================

  Future<void> _loadPaiementParam() async {
    final param = await PaiementParamServices.getPaiementParam();
    if (!mounted) return;
    setState(() {
      _paiementParam = param;
      _especesVisible = param.especesVisible;
      _carteVisible = param.carteVisible;
      _chequeVisible = param.chequeVisible;
      _virementVisible = param.virementVisible;
    });
  }

  // Applique un changement de visibilité d'un mode de paiement en garantissant
  // qu'au moins un mode reste actif : on refuse la désactivation du dernier
  // mode encore visible (message d'information à l'appui).
  void _setModePaiementVisible(void Function(bool) setter, bool value) {
    if (!value) {
      final actifs = [_especesVisible, _carteVisible, _chequeVisible, _virementVisible]
          .where((v) => v)
          .length;
      if (actifs <= 1) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.atLeastOnePaymentRequired)),
        );
        return;
      }
    }
    setState(() => setter(value));
  }

  Future<String?> _savePaiementParam() async {
    final userCode = _userCode;
    if (userCode == null) return 'not logged in';

    final param =
        _paiementParam ??
        PaiementParam(
          id: 1,
          especesVisible: true,
          carteVisible: true,
          chequeVisible: true,
          virementVisible: true,
        );
    param
      ..especesVisible = _especesVisible
      ..carteVisible = _carteVisible
      ..chequeVisible = _chequeVisible
      ..virementVisible = _virementVisible;

    final db = await DbCreator.openDb();
    final response = await PaiementParamServices(
      db,
    ).updatePaiementParam(param, userCode);

    if (response.success) {
      if (mounted) setState(() => _paiementParam = param);
      return null;
    }
    debugPrint('_savePaiementParam failed: ${response.message}');
    return response.message;
  }

  // ==========================================================
  // 3. PÉRIPHÉRIQUES & IMPRESSION — chargement / sauvegarde
  // ==========================================================

  Future<void> _loadImprimanteParam() async {
    final param = await ImprimanteParamServices.getImprimanteParam();
    if (!mounted) return;
    setState(() {
      _imprimanteParam = param;
      _typeImprimante = param.typeImprimante;
      _selectedPrinterName = param.nomImprimante;
      _ipController.text = param.adresseIp ?? '';
      _portController.text = (param.port ?? 9100).toString();
      _largeurRouleau = param.largeurRouleau;
    });
    _refreshPrinterList();
  }

  Future<void> _refreshPrinterList() async {
    if (_typeImprimante == TypeImprimante.bluetooth) return;

    setState(() => _isLoadingPrinters = true);
    try {
      List<String> names;
      if (_typeImprimante == TypeImprimante.normale) {
        final printers = await printing_pkg.Printing.listPrinters();
        names = printers.map((p) => p.name).toList();
      } else {
        names = await PrinterManager().getWindowsPrinters();
      }
      if (!mounted) return;
      setState(() {
        _availablePrinterNames = names;
        if (_selectedPrinterName != null &&
            !names.contains(_selectedPrinterName)) {
          // Garde la valeur enregistrée même si elle n'apparaît pas encore
          // dans l'énumération (ex: imprimante hors tension).
        }
      });
    } finally {
      if (mounted) setState(() => _isLoadingPrinters = false);
    }
  }

  Future<String?> _saveImprimanteParam() async {
    final userCode = _userCode;
    if (userCode == null) return 'not logged in';

    final param =
        _imprimanteParam ??
        ImprimanteParam(
          id: 1,
          typeImprimante: TypeImprimante.bluetooth,
          largeurRouleau: 80,
        );
    param
      ..typeImprimante = _typeImprimante
      ..nomImprimante = _selectedPrinterName
      ..adresseIp = _ipController.text.isEmpty ? null : _ipController.text
      ..port = int.tryParse(_portController.text)
      ..largeurRouleau = _largeurRouleau;

    final db = await DbCreator.openDb();
    final response = await ImprimanteParamServices(
      db,
    ).updateImprimanteParam(param, userCode);

    if (response.success) {
      if (mounted) setState(() => _imprimanteParam = param);
      return null;
    }
    debugPrint('_saveImprimanteParam failed: ${response.message}');
    return response.message;
  }

  // ==========================================================
  // 4. SAUVEGARDE — chargement / sauvegarde
  // ==========================================================

  Future<void> _loadBackupParam() async {
    final param = await BackupParamServices.getBackupParam();
    if (!mounted) return;
    setState(() {
      _backupParam = param;
      _dossierBackup = param.dossierBackup;
      _dossierDocuments = param.dossierDocuments;
      _autoBackupActif = param.autoBackupActif;
      _frequence = param.frequence;
    });
  }

  Future<void> _chooseBackupFolder() async {
    final folder = await FilePicker.platform.getDirectoryPath();
    if (folder != null) {
      setState(() => _dossierBackup = folder);
    }
  }

  Future<void> _chooseDocumentsFolder() async {
    final folder = await FilePicker.platform.getDirectoryPath();
    if (folder != null) {
      setState(() => _dossierDocuments = folder);
    }
  }

  Future<String?> _saveBackupParam() async {
    final userCode = _userCode;
    if (userCode == null) return 'not logged in';

    final param =
        _backupParam ??
        BackupParam(
          id: 1,
          autoBackupActif: false,
          frequence: FrequenceBackup.demarrage,
        );
    param
      ..dossierBackup = _dossierBackup
      ..dossierDocuments = _dossierDocuments
      ..autoBackupActif = _autoBackupActif
      ..frequence = _frequence;

    final db = await DbCreator.openDb();
    final response = await BackupParamServices(
      db,
    ).updateBackupParam(param, userCode);

    if (response.success) {
      if (mounted) setState(() => _backupParam = param);
      return null;
    }
    debugPrint('_saveBackupParam failed: ${response.message}');
    return response.message;
  }

  Future<void> _backupNow() async {
    final l10n = AppLocalizations.of(context)!;
    if (_dossierBackup == null || _dossierBackup!.isEmpty) {
      _snack(l10n.backupFolder, error: true);
      return;
    }

    setState(() => _isBackingUp = true);
    try {
      final response = await BackupService.backupNow(
        _dossierBackup!,
        modifiedByCode: _userCode,
      );
      if (response.success) {
        await _loadBackupParam();
        _snack(l10n.backupSuccess);
      } else {
        _snack('${l10n.backupError}: ${response.message}', error: true);
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreBackup() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['zip', 'db'],
    );
    if (result == null || result.files.isEmpty) return;
    final backupFilePath = result.files.first.path!;

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.restoreConfirmTitle),
        content: Text(l10n.restoreConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.restoreBackup),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isRestoring = true);
    try {
      final response = await BackupService.restore(backupFilePath);
      if (response.success) {
        _snack(l10n.restoreSuccess);
      } else {
        _snack('${l10n.restoreError}: ${response.message}', error: true);
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username ?? '';
    final local = context.watch<LocaleProvider>();
    final isRTL = local.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;
    final currentTab = _tabController.index;

    final tabNames = [l10n.systemSettings, l10n.shopInformation, l10n.advancedConnectionSettings];
    final tabIcons = [
      "assets/icons/sidebar/parametre_icon.png",
      "assets/icons/sidebar/magasin_icon.png",
      "assets/icons/sidebar/imprimer_icon.png",
    ];

    return Scaffold(
      backgroundColor: Appstyle.violetC,
      body: Directionality(
        textDirection: textDirection,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;
            const minHeight = Constant.minHeight;
            const minWidth = Constant.minWidth;

            final adjustedWidth = screenWidth < minWidth
                ? minWidth
                : screenWidth;
            final adjustedHeight = screenHeight < minHeight
                ? minHeight
                : screenHeight;

            final paddingV = adjustedHeight * 0.02;

            final halfScreenWidth = adjustedWidth * 0.425;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: minWidth,
                  minHeight: minHeight,
                ),
                child: SizedBox(
                  width: adjustedWidth,
                    height: adjustedHeight,
                    child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: isRTL
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                /// HEADER
                                HeaderModule(
                                  gradientColors: [
                                    Appstyle.Tblanc,
                                    Appstyle.Tblanc,
                                  ],
                                  child: Row(
                                    children: [
                                      /// LEFT: Icon + Title
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            "assets/icons/sidebar/parametre_icon.png",
                                            width: 40,
                                            color: Appstyle.violet
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            l10n.parametre,
                                            style: Appstyle.textXLB.copyWith(
                                              color: Appstyle.violet,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),

                                      /// RIGHT: Time + Account
                                      Row(
                                        children: [
                                          const ConnectionStatusBar(),
                                          const SizedBox(width: 20),
                                          TimeDateWidget(
                                           iconHeure:
                                                "assets/icons/hour_icon.png",
                                            iconDate:
                                                "assets/icons/agenda_icon.png",
                                          ),
                                          const SizedBox(width: 20),
                                          AccountWidget(
                                            name: userName,
                                            imageUrl:
                                                "assets/images/support.png",
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: paddingV / 2),

                                /// ✅ TAB BAR (même pattern que Produit/Zakat)
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    isScrollable: false,
                                    onTap: (_) => setState(() {}),
                                    indicator: BoxDecoration(
                                      color: Appstyle.violet,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    labelColor: Colors.white,
                                    unselectedLabelColor: Appstyle.gris,
                                    dividerColor: Colors.transparent,
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    padding: const EdgeInsets.all(6),
                                    labelStyle: Appstyle.textXS.copyWith(fontWeight: FontWeight.w600),
                                    unselectedLabelStyle: Appstyle.textXS.copyWith(fontWeight: FontWeight.w500),
                                    tabs: List.generate(3, (index) {
                                      final isSelected = currentTab == index;
                                      return Tab(
                                        icon: Image.asset(
                                          tabIcons[index],
                                          width: 20,
                                          height: 20,
                                          color: isSelected ? Colors.white : Appstyle.gris,
                                        ),
                                        text: tabNames[index],
                                      );
                                    }),
                                  ),
                                ),

                                SizedBox(height: paddingV),

                                /// Settings Form
                                Form(
                                    key: formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        if (currentTab == TAB_SYSTEME)
                                          _buildSystemeTab(l10n, translator, halfScreenWidth, paddingV, isRTL)
                                        else if (currentTab == TAB_MAGASIN)
                                          _buildMagasinTab(l10n, halfScreenWidth, paddingV, isRTL)
                                        else if (currentTab == TAB_AVANCE)
                                          _buildAvanceTab(l10n, halfScreenWidth, paddingV, isRTL),

                                        SizedBox(height: paddingV * 1.5),

                                        /// Bouton de sauvegarde unique pour l'ensemble des paramètres
                                        _buildSaveBar(l10n, textDirection),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // ONGLET SYSTÈME — Paramètre système, Marge, Seuil, Paiement, Zakat
  // ==========================================================
  Widget _buildSystemeTab(
    AppLocalizations l10n,
    ListsConstTranslator translator,
    double halfScreenWidth,
    double paddingV,
    bool isRTL,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              _section(
                title: l10n.systemSettings,
                icon: "assets/icons/sidebar/parametre_icon.png",
                child: Column(
                  children: [
                    SizedBox(
                      width: halfScreenWidth,
                      child: ChampAvecLabel(
                        distance: 200,
                        label: l10n.language,
                        child: TextListe(
                          value: selectedLanguage,
                          items: availableLanguages,
                          onChanged: (v) => setState(() => selectedLanguage = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: halfScreenWidth,
                      child: ChampAvecLabel(
                        distance: 200,
                        label: l10n.currency,
                        child: TextListe(
                          value: selectedCurrency,
                          items: availableCurrencies,
                          onChanged: (v) => setState(() => selectedCurrency = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: halfScreenWidth,
                      child: ChampAvecLabel(
                        distance: 200,
                        label: l10n.quantityDecimals,
                        child: Builder(
                          builder: (context) {
                            final decimalesItems = <int, String>{
                              0: '0  (${5.toStringAsFixed(0)})',
                              1: '1  (${5.toStringAsFixed(1)})',
                              2: '2  (${5.toStringAsFixed(2)})',
                            };
                            return TextListe(
                              clearable: false,
                              value: decimalesItems[_decimalesQuantite],
                              items: decimalesItems.values.toList(),
                              onChanged: (v) {
                                final decimales = decimalesItems.entries
                                    .firstWhere((e) => e.value == v)
                                    .key;
                                setState(() => _decimalesQuantite = decimales);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                   const SizedBox(height: 20),
                    SizedBox(
                      width: halfScreenWidth,
                      child: Text(
                        l10n.quantityDecimalsHint,
                        style: Appstyle.textS.copyWith(color: Appstyle.gris),
                      ),
                    ),    const SizedBox(height: 10),

                  ],
                ),
               ),
              SizedBox(height: paddingV),
              _buildMargeSection(l10n, translator, halfScreenWidth),
              SizedBox(height: paddingV),
              _buildSeuilSection(l10n, halfScreenWidth),
              SizedBox(height: paddingV),
              _buildVenteSection(l10n, translator, halfScreenWidth),

            ],
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              _buildPaiementSection(l10n, halfScreenWidth, paddingV),
              SizedBox(height: paddingV),
              _buildBonusSection(l10n, halfScreenWidth),
              SizedBox(height: paddingV),
              _buildZakatSection(l10n, halfScreenWidth),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ONGLET MAGASIN — Information utilisateur + Information entreprise
  // ==========================================================
  Widget _buildMagasinTab(
    AppLocalizations l10n,
    double halfScreenWidth,
    double paddingV,
    bool isRTL,
  ) {
    // Contenu limité à une demi-largeur d'écran (comme l'onglet Système qui
    // affiche deux colonnes), au lieu de s'étirer sur toute la largeur.
    return Align(
      alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
      child: SizedBox(
        width: halfScreenWidth + 40,
        child: Column(
      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _section(
          title: l10n.userInformation,
          icon: "assets/icons/info_icon.png",
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChampAvecLabel(
                      label: l10n.lastName,
                      obligatoire: true,
                      child: TextChampL(
                        controller: nomController,
                        obligatoire: true,
                        hint: l10n.lastName,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ChampAvecLabel(
                      label: l10n.firstName,
                      obligatoire: true,
                      child: TextChampL(
                        controller: prenomController,
                        obligatoire: true,
                        hint: l10n.firstName,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: paddingV),
        _buildEntrepriseSection(l10n, halfScreenWidth, paddingV),
      ],
        ),
      ),
    );
  }

  // ==========================================================
  // ONGLET AVANCÉ — Périphériques & impression + Sauvegarde
  // ==========================================================
  Widget _buildAvanceTab(
    AppLocalizations l10n,
    double halfScreenWidth,
    double paddingV,
    bool isRTL,
  ) {
    // Contenu limité à une demi-largeur d'écran (cohérent avec l'onglet
    // Magasin), au lieu de s'étirer sur toute la largeur.
    return Align(
      alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
      child: SizedBox(
        width: halfScreenWidth + 40,
        child: Column(
      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _buildImprimanteSection(l10n, halfScreenWidth, paddingV),
        SizedBox(height: paddingV),
        _buildBackupSection(l10n, halfScreenWidth, paddingV),
      ],
        ),
      ),
    );
  }

  // ==========================================================
  // MARGE — UI (ex-onglet Paramètre de l'écran Produit)
  // ==========================================================
  Widget _buildMargeSection(
    AppLocalizations l10n,
    ListsConstTranslator translator,
    double halfScreenWidth,
  ) {
    return _section(
      title: l10n.margin,
      icon: "assets/icons/prix_icon.png",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: halfScreenWidth,
            child: ChampAvecLabel(
              label: l10n.typeCalcul,
              distance: 200,
              key: ValueKey(selectedtypecacul),
              child: TextListe(
                clearable: false,
                value: selectedtypecacul,
                items: translator.typeCalculDisplayList,
                onChanged: (v) {
                  setState(() {
                    selectedtypecacul = v.toString();
                    final param = _paramGeneral;
                    if (param != null) {
                      tauxController.text = selectedtypecacul == translator.translateTypeCalcul("Pourcentage")
                          ? param.TauxMargePerncetage.toString()
                          : param.TauxMargeMontant.toString();
                    }
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: halfScreenWidth - 40,
                child: ChampAvecLabel(
                  distance: 200,
                  label: l10n.marginRate,
                  child: TextChampL(
                    maxValue: selectedtypecacul == translator.translateTypeCalcul("Pourcentage") ? 100 : null,
                    controller: tauxController,
                    hint: '',
                    numeric: true,
                  ),
                ),
              ),

              Text(
                selectedtypecacul == translator.translateTypeCalcul("Pourcentage") ? "%" : l10n.currency,
                style: Appstyle.textMB.copyWith(
                  color: Appstyle.violet,
                  fontWeight: FontWeight.bold,
                ),
              ),


            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SEUIL — UI (ex-onglet Paramètre de l'écran Produit)
  // ==========================================================
  Widget _buildSeuilSection(AppLocalizations l10n, double halfScreenWidth) {
    return _section(
      title: l10n.threshold,
      icon: "assets/icons/prix_icon.png",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: halfScreenWidth,
            child: ChampAvecLabel(
              distance: 200,
              label: l10n.minimum,
              child: TextChampL(controller: minController, hint: '', numeric: true),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: halfScreenWidth,
            child: ChampAvecLabel(
              distance: 200,
              label: l10n.maximum,
              child: TextChampL(controller: maxController, hint: '', numeric: true),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // VENTE SOUS PRIX D'ACHAT — UI
  // ==========================================================
  Widget _buildVenteSection(
    AppLocalizations l10n,
    ListsConstTranslator translator,
    double halfScreenWidth,
  ) {
    return _section(
      title: l10n.saleBelowCostLabel,
      icon: "assets/icons/prix_icon.png",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: halfScreenWidth,
            child: ChampAvecLabel(
              distance: 200,
              label: l10n.saleBelowCostLabel,
              child: TextListe(
                clearable: false,
                value: selectedVenteSousAchat,
                items: translator.venteSousAchatDisplayList,
                onChanged: (v) => setState(() => selectedVenteSousAchat = v),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: halfScreenWidth,
            child: Text(
              l10n.saleBelowCostHint,
              style: Appstyle.textS.copyWith(color: Appstyle.gris),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ZAKAT — UI (ex-onglet Paramètre de l'écran Zakat)
  // ==========================================================
  Widget _buildZakatSection(AppLocalizations l10n, double halfScreenWidth) {
    return _section(
      title: l10n.zakatParameter,
      icon: "assets/icons/sidebar/zakat_icon.png",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: halfScreenWidth,
            child: ChampAvecLabel(
              label: l10n.nissab,
              distance: 200,
              child: TextChampL(
                controller: _nisabController,
                hint: '560000.00 DA',
                numeric: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: halfScreenWidth,
            child: ChampAvecLabel(
              distance: 200,
              label: l10n.zakatRate,
              child: TextChampL(
                controller: _tauxZakatController,
                hint: '2.5',
                numeric: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Barre unique de sauvegarde de tous les paramètres (des 3 onglets).
  Widget _buildSaveBar(AppLocalizations l10n, TextDirection textDirection) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: BoxDecoration(
        color: Appstyle.Tblanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Appstyle.grisC, width: 1.5),
      ),
      child: Row(
        textDirection: textDirection,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 200,
            child: MainButton(
              text: _isSavingAll ? l10n.saving : l10n.save,
              icon: Icons.save_outlined,
              color: Appstyle.violet,
              onPressed: _isSavingAll ? null : _saveAll,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 1. INFORMATIONS GÉNÉRALES — UI
  // ==========================================================
  Widget _buildEntrepriseSection(
    AppLocalizations l10n,
    double halfScreenWidth,
    double paddingV,
  ) {
    return _section(
      title: l10n.shopInformation,
      icon: "assets/icons/sidebar/magasin_icon.png",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: halfScreenWidth,
            child: ChampAvecLabel(
              distance: halfScreenWidth*0.432,
              parent: true,
              label: l10n.shopName,
              obligatoire: true,
              child: TextChampL(
                controller: _nomBoutiqueController,
                obligatoire: true,
                hint: l10n.enterShopName,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: halfScreenWidth,
            child: ChampAvecLabel(
              distance: halfScreenWidth*0.432,
              label: l10n.shopAddress,
              child: TextChampL(
                controller: _adresseController,
                hint: l10n.shopAddressHint,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: halfScreenWidth,
            child: ChampAvecLabel(
              distance: halfScreenWidth*0.432,
              label: l10n.shopPhone,
              child: TextChampL(controller: _telephoneController, hint: ''),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: halfScreenWidth,
            child: ChampAvecLabel(
              distance: halfScreenWidth*0.432,
              label: l10n.shopEmail,
              child: TextChampL(controller: _emailController, hint: ''),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: halfScreenWidth,
            child: ChampAvecLabel(
              distance: halfScreenWidth*0.432,
              label: l10n.ticketMessage,
              child: TextChampL(
                controller: _messageTicketController,
                hint: l10n.ticketMessageHint,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.legalInformation,
            style: Appstyle.textSB.copyWith(color: Appstyle.TgrisF),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: halfScreenWidth,
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: (halfScreenWidth - 12) / 2,
                  child: ChampAvecLabel(
                    distance: halfScreenWidth*0.17,
                    label: l10n.nisLabel,
                    child: TextChampL(
                      controller: _nisController,
                      hint: '',
                      width: 183,
                    ),
                  ),
                ),
                SizedBox(
                  width: (halfScreenWidth - 12) / 2,
                  child: ChampAvecLabel(
                    distance: halfScreenWidth*0.17,
                    label: l10n.articleLabel,
                    child: TextChampL(
                      controller: _articleController,
                      hint: '',
                      width: 183,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: halfScreenWidth,
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: (halfScreenWidth - 12) / 2,
                  child: ChampAvecLabel(
                    distance: halfScreenWidth*0.17,
                    label: l10n.rcLabel,
                    child: TextChampL(
                      controller: _rcController,
                      hint: '',
                      width: 183,
                    ),
                  ),
                ),
                SizedBox(
                  width: (halfScreenWidth - 12) / 2,
                  child: ChampAvecLabel(
                    distance: halfScreenWidth*0.17,
                    label: l10n.nifLabel,
                    child: TextChampL(
                      controller: _nifController,
                      hint: '',
                      width: 183,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.shopLogo,
            style: Appstyle.textSB.copyWith(color: Appstyle.TgrisF),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_pickedLogoFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _pickedLogoFile!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_logoPath != null && _logoPath!.isNotEmpty)
                FutureBuilder<File?>(
                  future: LogoService.getLogoFile(_logoPath),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          snapshot.data!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Appstyle.grisC,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  },
                )
              else
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Appstyle.grisC,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image_outlined, color: Colors.white),
                ),
              const SizedBox(width: 12),
              MainButton(
                text: l10n.changeLogo,
                icon: Icons.upload_outlined,
                color: Appstyle.indigo,
                onPressed: _pickLogo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 2. MODES DE PAIEMENT — UI
  // ==========================================================
  Widget _buildPaiementSection(
    AppLocalizations l10n,
    double halfScreenWidth,
    double paddingV,
  ) {
    return _section(
      title: l10n.paymentMethodsSection,
      icon: "assets/icons/devise_icon.png",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paymentMethodsHint,
            style: Appstyle.textS.copyWith(color: Appstyle.gris),
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: halfScreenWidth,
            child: Column(
              children: [
                // Wrap each SwitchListTile with a Container or SizedBox with constrained width
                Container(
                  constraints: BoxConstraints(maxWidth: halfScreenWidth),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.especes),
                    value: _especesVisible,
                    onChanged: (v) => _setModePaiementVisible((val) => _especesVisible = val, v),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(maxWidth: halfScreenWidth),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.carte),
                    value: _carteVisible,
                    onChanged: (v) => _setModePaiementVisible((val) => _carteVisible = val, v),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(maxWidth: halfScreenWidth),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.cheque),
                    value: _chequeVisible,
                    onChanged: (v) => _setModePaiementVisible((val) => _chequeVisible = val, v),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(maxWidth: halfScreenWidth),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.virement),
                    value: _virementVisible,
                    onChanged: (v) => _setModePaiementVisible((val) => _virementVisible = val, v),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PROGRAMME DE BONUS/FIDÉLITÉ — UI
  // ==========================================================
  Widget _buildBonusSection(AppLocalizations l10n, double halfScreenWidth) {
    return _section(
      title: l10n.loyaltyProgram,
      icon: "assets/icons/devise_icon.png",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: halfScreenWidth),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.activateLoyaltyProgram),
              value: _activeBonus,
              onChanged: (v) => setState(() => _activeBonus = v),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: halfScreenWidth,
            child: ChampAvecLabel(
              distance: 200,
              label: l10n.bonusRate,
              child: TextChampL(
                enabled: _activeBonus,
                controller: bonusTauxController,
                hint: '',
                numeric: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 3. PÉRIPHÉRIQUES & IMPRESSION — UI
  // ==========================================================
  Widget _buildImprimanteSection(
    AppLocalizations l10n,
    double halfScreenWidth,
    double paddingV,
  ) {
    final typeItems = <String, String>{
      TypeImprimante.bluetooth: l10n.printerTypeBluetooth,
      TypeImprimante.usb: l10n.printerTypeUsb,
      TypeImprimante.reseau: l10n.printerTypeReseau,
      TypeImprimante.normale: l10n.printerTypeNormale,
    };

    return _section(
      title: l10n.devicesSection,
      icon: "assets/icons/sidebar/parametre_icon.png",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: halfScreenWidth,
            child: ChampAvecLabel(
              label: l10n.printerType,
              child: TextListe(
                clearable: false,
                value: typeItems[_typeImprimante],
                items: typeItems.values.toList(),
                onChanged: (v) {
                  final type = typeItems.entries
                      .firstWhere((e) => e.value == v)
                      .key;
                  setState(() {
                    _typeImprimante = type;
                    _selectedPrinterName = null;
                    _availablePrinterNames = [];
                  });
                  _refreshPrinterList();
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_typeImprimante == TypeImprimante.usb ||
              _typeImprimante == TypeImprimante.normale) ...[
            SizedBox(
              width: halfScreenWidth,
              child: ChampAvecLabel(
                label: l10n.selectPrinterLabel,
                child: Row(
                  children: [
                    Expanded(
                      child: TextListe(
                        clearable: false,
                        value: _selectedPrinterName,
                        items: _availablePrinterNames,
                        onChanged: (v) =>
                            setState(() => _selectedPrinterName = v),
                      ),
                    ),
                    IconButton(
                      icon: _isLoadingPrinters
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      onPressed: _isLoadingPrinters
                          ? null
                          : _refreshPrinterList,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_typeImprimante == TypeImprimante.reseau) ...[
            SizedBox(
              width: halfScreenWidth,
              child: ChampAvecLabel(
                label: l10n.ipAddressLabel,
                child: TextChampL(
                  controller: _ipController,
                  hint: '192.168.1.100',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: halfScreenWidth,
              child: ChampAvecLabel(
                label: l10n.portLabel,
                child: TextChampL(
                  controller: _portController,
                  hint: '9100',
                  numeric: true,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_typeImprimante != TypeImprimante.normale)
            SizedBox(
              width: halfScreenWidth,
              child: ChampAvecLabel(
                label: l10n.rollWidthLabel,
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<int>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('58mm'),
                        value: 58,
                        groupValue: _largeurRouleau,
                        onChanged: (v) => setState(() => _largeurRouleau = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<int>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('80mm'),
                        value: 80,
                        groupValue: _largeurRouleau,
                        onChanged: (v) => setState(() => _largeurRouleau = v!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // 4. SAUVEGARDE — UI
  // ==========================================================
  Widget _buildBackupSection(
    AppLocalizations l10n,
    double halfScreenWidth,
    double paddingV,
  ) {
    final frequencyItems = <String, String>{
      FrequenceBackup.demarrage: l10n.frequencyStartup,
      FrequenceBackup.quotidien: l10n.frequencyDaily,
      FrequenceBackup.hebdomadaire: l10n.frequencyWeekly,
    };

    return _section(
      title: l10n.backupSection,
      icon: "assets/icons/sidebar/parametre_icon.png",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(

            width: halfScreenWidth,
            child: ChampAvecLabel(
              distance: 160,
              label: l10n.backupFolder,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dossierBackup ?? l10n.chooseFolder,
                      style: Appstyle.textS,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  MainButton(
                    text: l10n.chooseFolder,
                    color: Appstyle.indigo,
                    onPressed: _chooseBackupFolder,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ✅ Dossier de tous les fichiers générés par l'app (Excel,
          // factures/BL PDF, tickets...) — distinct du dossier de sauvegarde
          // de la base de données ci-dessus.
          SizedBox(
            width: halfScreenWidth,
            child: ChampAvecLabel(
              distance: 300,
              label: l10n.documentsFolder,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dossierDocuments ?? l10n.chooseFolder,
                      style: Appstyle.textS,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  MainButton(
                    text: l10n.chooseFolder,
                    color: Appstyle.indigo,
                    onPressed: _chooseDocumentsFolder,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: halfScreenWidth,
            child: ChampAvecLabel(
              label: l10n.lastBackup,
              child: Text(
                _backupParam?.derniereSauvegarde?.toString() ??
                    l10n.neverBackedUp,
                style: Appstyle.textS,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Wrap the SwitchListTile with a constrained container
          Container(
            constraints: BoxConstraints(maxWidth: halfScreenWidth),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.autoBackup),
              value: _autoBackupActif,
              onChanged: (v) => setState(() => _autoBackupActif = v),
            ),
          ),
          if (_autoBackupActif)
            SizedBox(
              width: halfScreenWidth,
              child: ChampAvecLabel(
                label: l10n.backupFrequency,
                child: TextListe(
                  clearable: false,
                  value: frequencyItems[_frequence],
                  items: frequencyItems.values.toList(),
                  onChanged: (v) {
                    final freq = frequencyItems.entries
                        .firstWhere((e) => e.value == v)
                        .key;
                    setState(() => _frequence = freq);
                  },
                ),
              ),
            ),
          SizedBox(height: paddingV*2),
          SizedBox(
            width: halfScreenWidth,
            child: Row(
              children: [
                Expanded(
                  child: MainButton(
                    text: _isBackingUp ? l10n.saving : l10n.backupNow,
                    icon: Icons.backup_outlined,
                    color: Appstyle.indigo,
                    onPressed: _isBackingUp ? null : _backupNow,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MainButton(
                    text: l10n.restoreBackup,
                    icon: Icons.restore_outlined,
                    color: Appstyle.gris,
                    onPressed: _isRestoring ? null : _restoreBackup,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section widget matching the design of GestionCaisseScreen
Widget _section({
  required String title,
  required String icon,
  required Widget child,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 0),
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
    decoration: BoxDecoration(
      color: Appstyle.Tblanc,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Appstyle.grisC, width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(icon, width: 22, height: 22, color: Appstyle.Tblue),
            const SizedBox(width: 8),
            Text(
              title,
              style: Appstyle.textL.copyWith(
                color: Appstyle.Tblue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        child,
      ],
    ),
  );
}
