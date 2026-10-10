import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/Services/CaisseSession.dart';
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Services/Client.dart';
import '../../../data/models/verssement.dart';
import '../../dialog//confirmation_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/button/main_button.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';

Future<void> DeleteVerssements({
  required List<Verssement> verssements,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final versService = VerssementServices(db);
  final clientService = ClientServices(db);
  final fournisseurService = FournisseurServices(db);
  final caisseSessionService = CaisseSessionServices(db);
  final clients = await ClientServices.getAllClients();
  final fournisseurs = await FournisseurServices.getAllFournisseurs();

  for (var verssement in verssements) {
    if (verssement.typebeneficiare == "Client") {
      final client = clients.firstWhere(
            (c) => c.code == verssement.beneficiareCode,
        orElse: () => throw Exception("Client introuvable"),
      );

      if (verssement.sense == "Entrée") {
        await clientService.supprimerVersement(
          client.id,
          verssement.montant,
        );
      } else if (verssement.sense == "Sortie") {
        await clientService.supprimerVersementSortie(
          client.id,
          verssement.montant,
        );
      }
    }
    if (verssement.typebeneficiare == "Fournisseur") {
      final fournisseur = fournisseurs.firstWhere(
            (c) => c.code == verssement.beneficiareCode,
        orElse: () => throw Exception("Fournisseur introuvable"),
      );

      if (verssement.sense == "Entrée") {
        await fournisseurService.supprimerVersement(
          fournisseur.id,
          verssement.montant,
        );
      } else if (verssement.sense == "Sortie") {
        await fournisseurService.supprimerVersementSortie(
          fournisseur.id,
          verssement.montant,
        );
      }
    }
    // Soft-cancel du mouvement de caisse lié (jamais de suppression physique
    // du grand-livre) avant de supprimer le versement lui-même.
    final type = verssement.typebeneficiare == 'Fournisseur' ? 'versement_fournisseur' : 'versement_client';
    final mouvementsExistants = await CaisseSessionServices.getMouvementsByCodeOperation(
      verssement.code,
      type: type,
    );
    for (final mouvement in mouvementsExistants) {
      await caisseSessionService.annulerMouvement(
        code: mouvement.code,
        userCode: userCode,
        motif: "Versement ${verssement.code} supprimé",
      );
    }

    await versService.deleteverssement(verssement.id);
  }
}

Future<void> ActiverVersements(
    BuildContext context,
    List<Verssement> versementsSelectionnes,
    ) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      kind: DialogKind.refuser,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredDelete,
    );
    return;
  }

  // Un versement généré par un retour (Client/Sortie ou Fournisseur/Entrée)
  // ne peut pas être supprimé directement : il doit rester synchronisé avec
  // le retour, donc toute suppression doit passer par le retour lui-même.
  for (final v in versementsSelectionnes) {
    if (VerssementServices.estVersementDeRetour(v) ||
        await RetourServices.estLieAUnRetour(v.codeOperation)) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.information,
        titre_concerne: l10n.payment,
        message: l10n.versementLieRetourSuppr(v.code, v.codeOperation),
      );
      return;
    }
  }

  final clientsCatalogue = await ClientServices.getAllClients();
  final fournisseursCatalogue = await FournisseurServices.getAllFournisseurs();
  String nomBeneficiaire(Verssement v) => v.typebeneficiare == "Client"
      ? (clientsCatalogue.where((c) => c.code == v.beneficiareCode).firstOrNull?.nom ?? v.beneficiareCode)
      : (fournisseursCatalogue.where((f) => f.code == v.beneficiareCode).firstOrNull?.nom ?? v.beneficiareCode);

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 850,
                height: 550,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/devise_icon.png',
                  text: l10n.activatePayments,
                ),

                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedPayments,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Appstyle.Tnoir,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: versementsSelectionnes.length,
                        itemBuilder: (context, index) {
                          final v = versementsSelectionnes[index];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${l10n.paymentHash} #${v.id} - ${v.code}",
                                    style: Appstyle.textSB.copyWith(
                                      color: Appstyle.Tnoir,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  Text(
                                    "${l10n.amount}: ${v.montant} ${l10n.currency}",
                                    style: Appstyle.textS,
                                  ),

                                  Text(
                                    v.typebeneficiare == "Client"
                                        ? "${l10n.type}: ${l10n.client} | ${l10n.beneficiary}: ${nomBeneficiaire(v)}"
                                        : "${l10n.type}: ${l10n.supplier} | ${l10n.beneficiary}: ${nomBeneficiaire(v)}",
                                    style: Appstyle.textS,
                                  ),

                                  Text(
                                    "${l10n.status}: ${v.etat ? l10n.validated : l10n.cancelled}",
                                    style: Appstyle.textS.copyWith(
                                      color: v.etat == true
                                          ? Appstyle.success
                                          : Appstyle.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      l10n.confirmActivatePayments,
                      style: Appstyle.textS.copyWith(
                        color: Appstyle.TgrisC,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MainButton(
                      text: l10n.cancel,
                      icon: Icons.cancel,
                      color: Appstyle.gris,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.deletePayments,
                      color: Appstyle.violet,
                      icon: Icons.delete,
                      onPressed: () async {
                        await ConfirmationDialog(
                          context: context,
                          kind: DialogKind.danger,
                          titre: l10n.payment,
                          message: l10n.confirmDeletePayments,
                          onConfirmer: () async {
                            await DeleteVerssements(verssements: versementsSelectionnes, userCode: userCode);

                            await InformationDialog(
                                context: context,
                                titre_type_message: l10n.success,
                                titre_concerne: l10n.payment,
                                message: l10n.paymentsDeletedSuccess,
                                onTerminer: () {
                                  Navigator.pop(context);
                                }
                            );
                          },
                        );
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