import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Role.dart';
import 'package:caisse_dz/Services/RoleDetail.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/models/RoleDetail.dart';
import 'package:caisse_dz/data/models/role.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import '../../../Services/Historique.dart';
import '../../../data/constant.dart';
import '../../../data/models/histore.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';

// ✅ Fonction globale pour sauvegarder le rôle avec historique
Future<ApiResponse<int>> _SaveRole({
  required Role role,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = await RoleServices(db);
  final serviceh = await HistoriqueServices(db);

  final response = await services.addRole(role);

  // Ajouter l'historique
  if (response.success) {
    int idh = await _GetNextHistoriqueId();
    Historique histo = Historique(
      id: idh,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idh,
      ),
      type: "Role",
      desc: "L'utilisateur $userName a ajouté le Rôle ${role.rolenom}",
      oper: ListsConst.typeHisto[0],
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await serviceh.addHistorique(histo);
  }

  return response;
}

// ✅ Fonction pour sauvegarder les permissions du rôle
Future<ApiResponse<int>> _SaveRolePermissions({required RoleDetail roleDetail}) async {
  final db = await DbCreator.openDb();
  final services = RoleDetailServices(db);
  final response = await services.addRole(roleDetail);
  return response;
}

// ✅ Fonction pour obtenir le prochain ID du rôle
Future<int> _GetNextId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await RoleServices.getNextRoleId(txn);
  });
  return id;
}

// ✅ Fonction pour obtenir le prochain ID des détails du rôle
Future<int> _GetNextDetailId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await RoleDetailServices.getNextRoleDetailId(txn);
  });
  return id;
}

// ✅ Fonction pour obtenir le prochain ID de l'historique
Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

final TextEditingController codeControllerN = TextEditingController(text: "R01");
final TextEditingController nomRoleControllerN = TextEditingController();
final TextEditingController observationControllerN = TextEditingController();
final TextEditingController nombreControllerN = TextEditingController(text: "0");

void resetRoleForm() {
  codeControllerN.text = "R0";
  nomRoleControllerN.clear();
  observationControllerN.clear();
  nombreControllerN.text = "0";
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> RoleNouveau(BuildContext context) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context);

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      kind: DialogKind.refuser,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredCreate,
    );
    return;
  }

  int id = await _GetNextId();

  String code = CodeGenerator.generateCode(
    prefix: CodePrefix.role,
    id: id,
    digitCount: 4,
  );

  codeControllerN.text = code;

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return RoleCreationDialog(
        id: id,
        code: code,
        userName: userName,
        userCode: userCode,
      );
    },
  );
}

class RoleCreationDialog extends StatefulWidget {
  final int id;
  final String code;
  final String userName;
  final String userCode;

  const RoleCreationDialog({
    Key? key,
    required this.id,
    required this.code,
    required this.userName,
    required this.userCode,
  }) : super(key: key);

  @override
  State<RoleCreationDialog> createState() => _RoleCreationDialogState();
}

class _RoleCreationDialogState extends State<RoleCreationDialog> {
  int _currentStep = 0;

  // Controllers for step 1
  final TextEditingController _nomRoleController = TextEditingController();
  final TextEditingController _observationController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // RoleDetail object to store permissions
  late RoleDetail _roleDetail;

  // List of permissions with their display names and icons
  final List<PermissionItem> _permissionsList = [
    PermissionItem(key: 'dash', label: 'Tableau de bord', icon: Icons.dashboard),
    PermissionItem(key: 'caisse', label: 'Caisse', icon: Icons.point_of_sale),
    PermissionItem(key: 'produit', label: 'Produits', icon: Icons.inventory),
    PermissionItem(key: 'pannier', label: 'Pannier', icon: Icons.shopping_cart),
    PermissionItem(key: 'client', label: 'Clients', icon: Icons.people),
    PermissionItem(key: 'fournisseur', label: 'Fournisseurs', icon: Icons.business),
    PermissionItem(key: 'entree', label: 'Entrées', icon: Icons.input),
    PermissionItem(key: 'sortie', label: 'Sorties', icon: Icons.output),
    PermissionItem(key: 'retour', label: 'Retours', icon: Icons.undo),
    PermissionItem(key: 'stock', label: 'Stock', icon: Icons.warehouse),
    PermissionItem(key: 'besoin', label: 'Besoins', icon: Icons.assignment),
    PermissionItem(key: 'utilisateur', label: 'Utilisateurs', icon: Icons.person),
    PermissionItem(key: 'gestionCaisse', label: 'Gestion Caisse', icon: Icons.local_grocery_store),
    PermissionItem(key: 'zakat', label: 'Zakat', icon: Icons.mosque),
    PermissionItem(key: 'parametre', label: 'Paramètres', icon: Icons.settings, isLocked: true),
    PermissionItem(key: 'historique', label: 'Historique', icon: Icons.history, isLocked: true),
  ];

  // Phase 3 : permissions spéciales — actions sensibles transversales, pas
  // liées à un module de la sidebar (voir data/models/RoleDetail.dart).
  final List<PermissionItem> _specialPermissionsList = [
    PermissionItem(key: 'voirPrixAchat', label: 'Voir le prix d\'achat', icon: Icons.attach_money),
    PermissionItem(key: 'voirMarge', label: 'Voir la marge / taux de marge', icon: Icons.trending_up),
    PermissionItem(key: 'modifierPrixVente', label: 'Modifier le prix de vente', icon: Icons.sell),
    PermissionItem(key: 'annulerOperations', label: 'Annuler des opérations', icon: Icons.undo),
    PermissionItem(key: 'changerCaisseMagasin', label: 'Changer sa caisse/magasin assigné', icon: Icons.swap_horiz),
    PermissionItem(key: 'gererTransfertsCaisse', label: 'Voir/gérer les transferts entre caisses', icon: Icons.compare_arrows),
    PermissionItem(key: 'voirStockTousMagasins', label: 'Voir le stock de tous les magasins', icon: Icons.warehouse),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize RoleDetail with all permissions set to false
    _roleDetail = RoleDetail(
      id: widget.id,
      Rolecode: widget.code,
      creeParCode: widget.userCode,
      dateCree: DateTime.now(),
      dash: false,
      caisse: false,
      produit: false,
      pannier: false,
      client: false,
      fournisseur: false,
      entree: false,
      sortie: false,
      retour: false,
      stock: false,
      besoin: false,
      utilisateur: false,
      gestionCaisse: false,
      zakat: false,
      parametre: false,
      historique: false,
      voirPrixAchat: false,
      voirMarge: false,
      modifierPrixVente: false,
      annulerOperations: false,
      changerCaisseMagasin: false,
      gererTransfertsCaisse: false,
      voirStockTousMagasins: false,
    );
  }

  @override
  void dispose() {
    _nomRoleController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  // Method to update permission in RoleDetail
  void _updatePermission(String key, bool value) {
    setState(() {
      switch (key) {
        case 'dash':
          _roleDetail.dash = value;
          break;
        case 'caisse':
          _roleDetail.caisse = value;
          break;
        case 'produit':
          _roleDetail.produit = value;
          break;
        case 'pannier':
          _roleDetail.pannier = value;
          break;
        case 'client':
          _roleDetail.client = value;
          break;
        case 'fournisseur':
          _roleDetail.fournisseur = value;
          break;
        case 'entree':
          _roleDetail.entree = value;
          break;
        case 'sortie':
          _roleDetail.sortie = value;
          break;
        case 'retour':
          _roleDetail.retour = value;
          break;
        case 'stock':
          _roleDetail.stock = value;
          break;
        case 'besoin':
          _roleDetail.besoin = value;
          break;
        case 'utilisateur':
          _roleDetail.utilisateur = value;
          break;
        case 'gestionCaisse':
          _roleDetail.gestionCaisse = value;
          break;
        case 'zakat':
          _roleDetail.zakat = value;
          break;
        case 'parametre':
          _roleDetail.parametre = value;
          break;
        case 'historique':
          _roleDetail.historique = value;
          break;
        case 'voirPrixAchat':
          _roleDetail.voirPrixAchat = value;
          break;
        case 'voirMarge':
          _roleDetail.voirMarge = value;
          break;
        case 'modifierPrixVente':
          _roleDetail.modifierPrixVente = value;
          break;
        case 'annulerOperations':
          _roleDetail.annulerOperations = value;
          break;
        case 'changerCaisseMagasin':
          _roleDetail.changerCaisseMagasin = value;
          break;
        case 'gererTransfertsCaisse':
          _roleDetail.gererTransfertsCaisse = value;
          break;
        case 'voirStockTousMagasins':
          _roleDetail.voirStockTousMagasins = value;
          break;
      }
    });
  }

  // Method to get permission value from RoleDetail
  bool _getPermissionValue(String key) {
    switch (key) {
      case 'dash':
        return _roleDetail.dash;
      case 'caisse':
        return _roleDetail.caisse;
      case 'produit':
        return _roleDetail.produit;
      case 'pannier':
        return _roleDetail.pannier;
      case 'client':
        return _roleDetail.client;
      case 'fournisseur':
        return _roleDetail.fournisseur;
      case 'entree':
        return _roleDetail.entree;
      case 'sortie':
        return _roleDetail.sortie;
      case 'retour':
        return _roleDetail.retour;
      case 'stock':
        return _roleDetail.stock;
      case 'besoin':
        return _roleDetail.besoin;
      case 'utilisateur':
        return _roleDetail.utilisateur;
      case 'gestionCaisse':
        return _roleDetail.gestionCaisse;
      case 'zakat':
        return _roleDetail.zakat;
      case 'parametre':
        return _roleDetail.parametre;
      case 'historique':
        return _roleDetail.historique;
      case 'voirPrixAchat':
        return _roleDetail.voirPrixAchat;
      case 'voirMarge':
        return _roleDetail.voirMarge;
      case 'modifierPrixVente':
        return _roleDetail.modifierPrixVente;
      case 'annulerOperations':
        return _roleDetail.annulerOperations;
      case 'changerCaisseMagasin':
        return _roleDetail.changerCaisseMagasin;
      case 'gererTransfertsCaisse':
        return _roleDetail.gererTransfertsCaisse;
      case 'voirStockTousMagasins':
        return _roleDetail.voirStockTousMagasins;
      default:
        return false;
    }
  }

  // Sélection/désélection groupée, scopée aux permissions spéciales
  // (indépendante de _toggleAllPermissions qui ne couvre que les modules).
  void _toggleAllSpecialPermissions() {
    setState(() {
      final newValue = !_areAllSpecialPermissionsSelected();
      for (final permission in _specialPermissionsList) {
        _updatePermissionValueOnly(permission.key, newValue);
      }
    });
  }

  bool _areAllSpecialPermissionsSelected() {
    return _specialPermissionsList.every((p) => _getPermissionValue(p.key));
  }

  // Variante de _updatePermission sans setState (déjà fait par l'appelant),
  // pour éviter un setState par item dans une boucle.
  void _updatePermissionValueOnly(String key, bool value) {
    switch (key) {
      case 'voirPrixAchat':
        _roleDetail.voirPrixAchat = value;
        break;
      case 'voirMarge':
        _roleDetail.voirMarge = value;
        break;
      case 'modifierPrixVente':
        _roleDetail.modifierPrixVente = value;
        break;
      case 'annulerOperations':
        _roleDetail.annulerOperations = value;
        break;
      case 'changerCaisseMagasin':
        _roleDetail.changerCaisseMagasin = value;
        break;
      case 'gererTransfertsCaisse':
        _roleDetail.gererTransfertsCaisse = value;
        break;
      case 'voirStockTousMagasins':
        _roleDetail.voirStockTousMagasins = value;
        break;
    }
  }

  // Method to select/deselect all permissions
  // ✅ 'parametre'/'historique' sont réservées à Admin (voir PermissionItem.isLocked) :
  // exclues du calcul et jamais assignées par "Tout sélectionner".
  void _toggleAllPermissions() {
    setState(() {
      bool allTrue = _roleDetail.dash &&
          _roleDetail.caisse &&
          _roleDetail.produit &&
          _roleDetail.pannier &&
          _roleDetail.client &&
          _roleDetail.fournisseur &&
          _roleDetail.entree &&
          _roleDetail.sortie &&
          _roleDetail.retour &&
          _roleDetail.stock &&
          _roleDetail.besoin &&
          _roleDetail.utilisateur &&
          _roleDetail.gestionCaisse &&
          _roleDetail.zakat;

      bool newValue = !allTrue;

      _roleDetail.dash = newValue;
      _roleDetail.caisse = newValue;
      _roleDetail.produit = newValue;
      _roleDetail.pannier = newValue;
      _roleDetail.client = newValue;
      _roleDetail.fournisseur = newValue;
      _roleDetail.entree = newValue;
      _roleDetail.sortie = newValue;
      _roleDetail.retour = newValue;
      _roleDetail.stock = newValue;
      _roleDetail.besoin = newValue;
      _roleDetail.utilisateur = newValue;
      _roleDetail.gestionCaisse = newValue;
      _roleDetail.zakat = newValue;
    });
  }

  bool _areAllPermissionsSelected() {
    return _roleDetail.dash &&
        _roleDetail.caisse &&
        _roleDetail.produit &&
        _roleDetail.pannier &&
        _roleDetail.client &&
        _roleDetail.fournisseur &&
        _roleDetail.entree &&
        _roleDetail.sortie &&
        _roleDetail.retour &&
        _roleDetail.stock &&
        _roleDetail.besoin &&
        _roleDetail.utilisateur &&
        _roleDetail.gestionCaisse &&
        _roleDetail.zakat;
  }

  // ✅ Méthode pour sauvegarder le rôle (appelée depuis le bouton Save)
  Future<void> _saveRole() async {
    final l10n = AppLocalizations.of(context);

    // ✅ Unicité du nom du rôle avant toute création.
    final roleNomExistant = await RoleServices.findRoleByNom(_nomRoleController.text);
    if (roleNomExistant != null) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        kind: DialogKind.refuser,
        titre_concerne: l10n.role,
        message: l10n.roleNameAlreadyExists,
      );
      return;
    }

    // Créer l'objet Role
    Role role = Role(
      observation: _observationController.text,
      dateCree: DateTime.now(),
      rolenom: _nomRoleController.text,
      code: widget.code,
      etat: true,
      id: widget.id,
      creeParCode: widget.userCode,
    );

    // ✅ Appeler la fonction globale avec userName et userCode
    final response = await _SaveRole(
      role: role,
      userName: widget.userName,
      userCode: widget.userCode,
    );

    if (!response.success) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        kind: DialogKind.refuser,
        titre_concerne: l10n.role,
        message: response.message,
      );
      return;
    }

    // Sauvegarder les permissions
    _roleDetail.id = await _GetNextDetailId();
    final permissionsResponse = await _SaveRolePermissions(roleDetail: _roleDetail);

    if (!permissionsResponse.success) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        kind: DialogKind.refuser,
        titre_concerne: l10n.permissions,
        message: permissionsResponse.message,
      );
      return;
    }

    await InformationDialog(
      context: context,
      titre_type_message: l10n.success,
      titre_concerne: l10n.role,
      message: response.message,
    );

    resetRoleForm();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _resetForm() {
    _nomRoleController.clear();
    _observationController.clear();
    setState(() {
      // Reset all permissions to false
      _roleDetail.dash = false;
      _roleDetail.caisse = false;
      _roleDetail.produit = false;
      _roleDetail.pannier = false;
      _roleDetail.client = false;
      _roleDetail.fournisseur = false;
      _roleDetail.entree = false;
      _roleDetail.sortie = false;
      _roleDetail.retour = false;
      _roleDetail.stock = false;
      _roleDetail.besoin = false;
      _roleDetail.utilisateur = false;
      _roleDetail.gestionCaisse = false;
      _roleDetail.zakat = false;
      _roleDetail.parametre = false;
      _roleDetail.historique = false;
      _roleDetail.voirPrixAchat = false;
      _roleDetail.voirMarge = false;
      _roleDetail.modifierPrixVente = false;
      _roleDetail.annulerOperations = false;
      _roleDetail.changerCaisseMagasin = false;
      _roleDetail.gererTransfertsCaisse = false;
      _roleDetail.voirStockTousMagasins = false;
      _currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: BaseDialog(
          width: 900,
          height: 1020,
          header: TitreAvecLigne(
            imagePath: 'assets/icons/role_icon.png',
            text: l10n.newRole,
          ),
          content: Column(
            children: [
              // Step indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    _buildStepIndicator(0, l10n.roleInfo, Icons.info),
                    Expanded(child: Container(height: 2, color: Appstyle.violet.withOpacity(0.3))),
                    _buildStepIndicator(1, l10n.permissions, Icons.lock),
                    Expanded(child: Container(height: 2, color: Appstyle.violet.withOpacity(0.3))),
                    _buildStepIndicator(2, l10n.specialPermissions, Icons.security),
                  ],
                ),
              ),

              // Step content
              Expanded(
                child: switch (_currentStep) {
                  0 => _buildStep1(l10n),
                  1 => _buildStep2(l10n),
                  _ => _buildStep3(l10n),
                },
              ),
            ],
          ),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_currentStep == 0) ...[
                MainButton(
                  text: l10n.cancel,
                  icon: Icons.cancel,
                  color: Appstyle.gris,
                  onPressed: () {
                    _resetForm();
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 10),
                MainButton(
                  text: l10n.next,
                  icon: Icons.arrow_forward,
                  color: Appstyle.violet,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _currentStep = 1;
                      });
                    } else {
                      await InformationDialog(
                        context: context,
                        titre_type_message: l10n.error,
                        kind: DialogKind.refuser,
                        titre_concerne: l10n.role,
                        message: l10n.fillRequiredFields,
                      );
                    }
                  },
                ),
              ] else if (_currentStep == 1) ...[
                MainButton(
                  text: l10n.previous,
                  icon: Icons.arrow_back,
                  color: Appstyle.gris,
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                    });
                  },
                ),
                const SizedBox(width: 10),
                MainButton(
                  text: l10n.cancel,
                  icon: Icons.cancel,
                  color: Appstyle.gris,
                  onPressed: () {
                    _resetForm();
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 10),
                MainButton(
                  text: l10n.next,
                  icon: Icons.arrow_forward,
                  color: Appstyle.violet,
                  onPressed: () {
                    setState(() {
                      _currentStep = 2;
                    });
                  },
                ),
              ] else ...[
                MainButton(
                  text: l10n.previous,
                  icon: Icons.arrow_back,
                  color: Appstyle.gris,
                  onPressed: () {
                    setState(() {
                      _currentStep = 1;
                    });
                  },
                ),
                const SizedBox(width: 10),
                MainButton(
                  text: l10n.cancel,
                  icon: Icons.cancel,
                  color: Appstyle.gris,
                  onPressed: () {
                    _resetForm();
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 10),
                MainButton(
                  text: l10n.save,
                  icon: Icons.save,
                  color: Appstyle.violet,
                  onPressed: _saveRole,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    bool isActive = _currentStep == step;
    bool isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted ? Appstyle.violet : Appstyle.gris.withOpacity(0.3),
            border: Border.all(
              color: isActive ? Appstyle.violet : Appstyle.gris,
              width: 2,
            ),
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Appstyle.violet : Appstyle.gris,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChampAvecLabel(
                    label: l10n.code,
                    child: TextChampL(
                      controller: codeControllerN,
                      enabled: false,
                      hint: widget.code,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ChampAvecLabel(
                    label: l10n.role,
                    obligatoire: true,
                    child: TextChampL(
                      obligatoire: true,
                      controller: _nomRoleController,
                      hint: l10n.roleNameHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChampAvecLabel(
                    label: l10n.observation,
                    child: TextChampL(
                      controller: _observationController,
                      hint: l10n.observationHint,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ChampAvecLabel(
                    label: l10n.userCount,
                    child: TextChampL(
                      controller: nombreControllerN,
                      enabled: false,
                      hint: "0",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Appstyle.violet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Appstyle.radiusSM),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Appstyle.violet, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.permissionsDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: Appstyle.violet,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.selectPermissions,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 8,
            ),
            itemCount: _permissionsList.length,
            itemBuilder: (context, index) {
              final permission = _permissionsList[index];
              // ✅ Verrouillée à false en permanence pour 'parametre'/'historique'
              // (réservé au rôle Admin) : ni sélectionnable ni affichée comme
              // sélectionnée.
              final isSelected = !permission.isLocked && _getPermissionValue(permission.key);
              final isLocked = permission.isLocked;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                  side: BorderSide(
                    color: isSelected
                        ? Appstyle.violet
                        : Appstyle.gris.withOpacity(0.3),
                  ),
                ),
                child: InkWell(
                  onTap: isLocked
                      ? null
                      : () {
                          _updatePermission(permission.key, !isSelected);
                        },
                  borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          permission.icon,
                          color: isLocked
                              ? Appstyle.neutral300
                              : (isSelected ? Appstyle.violet : Appstyle.gris),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            permission.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: isLocked
                                  ? Appstyle.neutral300
                                  : (isSelected ? Appstyle.violet : Appstyle.ink500),
                            ),
                          ),
                        ),
                        if (isLocked)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(Icons.lock_outline, size: 16, color: Appstyle.neutral300),
                          ),
                        Checkbox(
                          value: isSelected,
                          onChanged: isLocked
                              ? null
                              : (bool? value) {
                                  _updatePermission(permission.key, value ?? false);
                                },
                          activeColor: Appstyle.violet,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _toggleAllPermissions,
                icon: Icon(Icons.select_all, size: 18),
                label: Text(_areAllPermissionsSelected()
                    ? l10n.deselectAll
                    : l10n.selectAll),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Phase 3 : permissions spéciales — même présentation que _buildStep2,
  // sans notion de verrouillage (aucune permission spéciale n'est réservée).
  Widget _buildStep3(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Appstyle.violet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Appstyle.radiusSM),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Appstyle.violet, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.specialPermissionsDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: Appstyle.violet,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.selectSpecialPermissions,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 8,
            ),
            itemCount: _specialPermissionsList.length,
            itemBuilder: (context, index) {
              final permission = _specialPermissionsList[index];
              final isSelected = _getPermissionValue(permission.key);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                  side: BorderSide(
                    color: isSelected
                        ? Appstyle.violet
                        : Appstyle.gris.withOpacity(0.3),
                  ),
                ),
                child: InkWell(
                  onTap: () => _updatePermission(permission.key, !isSelected),
                  borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          permission.icon,
                          color: isSelected ? Appstyle.violet : Appstyle.gris,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            permission.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                              color: isSelected ? Appstyle.violet : Appstyle.ink500,
                            ),
                          ),
                        ),
                        Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) => _updatePermission(permission.key, value ?? false),
                          activeColor: Appstyle.violet,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _toggleAllSpecialPermissions,
                icon: Icon(Icons.select_all, size: 18),
                label: Text(_areAllSpecialPermissionsSelected()
                    ? l10n.deselectAll
                    : l10n.selectAll),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PermissionItem {
  final String key;
  final String label;
  final IconData icon;
  // ✅ Réservé au rôle Admin (seedé au démarrage) : jamais assignable à un
  // rôle personnalisé créé depuis ce formulaire.
  final bool isLocked;

  PermissionItem({
    required this.key,
    required this.label,
    required this.icon,
    this.isLocked = false,
  });
}