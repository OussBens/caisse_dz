import 'dart:ui';

import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/EntrepriseParam.dart';
import 'package:caisse_dz/Services/PaiementParam.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/quantite_format.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../base_dialog.dart';
import '../information_dialog.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/titre_avec_ligne.dart';

const List<String> _availableLanguages = ["fr", "en", "ar"];
const List<String> _availableCurrencies = ["DZD", "EUR", "USD"];

final _nomBoutiqueController = TextEditingController();
final _adresseController = TextEditingController();
final _telephoneController = TextEditingController();
final _emailController = TextEditingController();
final _rcController = TextEditingController();
final _nifController = TextEditingController();
final _nisController = TextEditingController();
final _articleController = TextEditingController();
final _messageTicketController = TextEditingController();

final GlobalKey<FormState> _initialSetupFormKey = GlobalKey<FormState>();

/// Dialog de configuration initiale de la boutique, affiché une seule fois
/// (voir SideBarWidget, flag EncryptedPreferences "initial_setup_completed")
/// après la toute première connexion. Réutilise exactement les mêmes
/// services que ParametreScreen (EntrepriseParamServices, PaiementParamServices,
/// ParamServices, AuthState.updateUserParameters) : aucune logique de
/// sauvegarde dupliquée, juste une UI condensée en dialog.
Future<void> InitialSetupDialog(BuildContext context) async {
  final auth = Provider.of<AuthState>(context, listen: false);

  final entreprise = await EntrepriseParamServices.getEntrepriseParam();
  final paiement = await PaiementParamServices.getPaiementParam();
  final quantiteParam = await ParamServices.getParam();

  if (!context.mounted) return;

  _nomBoutiqueController.text =
      entreprise.nomBoutique == 'Ma Boutique' ? '' : entreprise.nomBoutique;
  _adresseController.text = entreprise.adresse ?? '';
  _telephoneController.text = entreprise.telephone ?? '';
  _emailController.text = entreprise.email ?? '';
  _rcController.text = entreprise.rc ?? '';
  _nifController.text = entreprise.nif ?? '';
  _nisController.text = entreprise.nis ?? '';
  _articleController.text = entreprise.article ?? '';
  _messageTicketController.text = entreprise.messageTicket ?? '';

  String selectedLanguage = auth.currentLanguage ?? 'fr';
  String selectedCurrency = auth.currentCurrency ?? 'DZD';
  int decimalesQuantite = quantiteParam.decimalesQuantite;
  bool especesVisible = paiement.especesVisible;
  bool carteVisible = paiement.carteVisible;
  bool chequeVisible = paiement.chequeVisible;
  bool virementVisible = paiement.virementVisible;
  bool isSaving = false;

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.45),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          Future<void> save() async {
            if (!_initialSetupFormKey.currentState!.validate()) return;
            setState(() => isSaving = true);

            try {
              final userCode = auth.userCode;
              if (userCode == null) {
                if (!context.mounted) return;
                await InformationDialog(
                  context: context,
                  titre_type_message: l10n.error,
                  titre_concerne: l10n.parametre,
                  message: l10n.pleaseLoginFirst,
                );
                return;
              }

              final db = await DbCreator.openDb();

              entreprise
                ..nomBoutique = _nomBoutiqueController.text
                ..adresse = _adresseController.text
                ..telephone = _telephoneController.text
                ..email = _emailController.text
                ..rc = _rcController.text
                ..nif = _nifController.text
                ..nis = _nisController.text
                ..article = _articleController.text
                ..messageTicket = _messageTicketController.text;
              final entrepriseResponse =
                  await EntrepriseParamServices(db).updateEntrepriseParam(entreprise, userCode);

              paiement
                ..especesVisible = especesVisible
                ..carteVisible = carteVisible
                ..chequeVisible = chequeVisible
                ..virementVisible = virementVisible;
              final paiementResponse =
                  await PaiementParamServices(db).updatePaiementParam(paiement, userCode);

              quantiteParam
                ..decimalesQuantite = decimalesQuantite
                ..modifParCode = userCode
                ..Datemodif = DateTime.now();
              await ParamServices(db).updateParam(quantiteParam);
              QuantiteFormat.decimales = decimalesQuantite;

              final userParamError = await auth.updateUserParameters(
                language: selectedLanguage,
                currency: selectedCurrency,
                magasin: auth.currentMagasin ?? '',
                magasinId: auth.currentMagasinId ?? '',
                modifiedBy: auth.username ?? '',
                modifiedByCode: userCode,
                reason: "Configuration initiale",
              );

              if (!context.mounted) return;

              final failed = !entrepriseResponse.success ||
                  !paiementResponse.success ||
                  userParamError != null;
              if (failed) {
                final errorMessage = userParamError ??
                    (!entrepriseResponse.success
                        ? entrepriseResponse.message
                        : paiementResponse.message);
                await InformationDialog(
                  context: context,
                  titre_type_message: l10n.error,
                  titre_concerne: l10n.parametre,
                  message: errorMessage,
                );
                return;
              }

              await InformationDialog(
                context: context,
                titre_type_message: l10n.success,
                titre_concerne: l10n.parametre,
                message: l10n.settingsSaved,
                onTerminer: () {
                  if (context.mounted) Navigator.pop(context);
                },
              );
            } catch (e, stack) {
              debugPrint('InitialSetupDialog.save exception: $e\n$stack');
              if (!context.mounted) return;
              await InformationDialog(
                context: context,
                titre_type_message: l10n.error,
                titre_concerne: l10n.parametre,
                message: '${l10n.errorSavingSettings}: $e',
              );
            } finally {
              if (context.mounted) setState(() => isSaving = false);
            }
          }

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: BaseDialog(
                width: 900,
                height: 640,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/parametre_icon.png',
                  text: l10n.initialSetupTitle,
                ),
                content: Form(
                  key: _initialSetupFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.initialSetupSubtitle,
                          style: Appstyle.textS.copyWith(color: Appstyle.gris),
                        ),
                        const SizedBox(height: 16),
                        ChampAvecLabel(
                          label: l10n.language,
                          distance: 160,
                          parent: true,
                          child: TextListe(
                            clearable: false,
                            value: selectedLanguage,
                            items: _availableLanguages,
                            onChanged: (v) =>
                                setState(() => selectedLanguage = v ?? selectedLanguage),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ChampAvecLabel(
                          label: l10n.currency,
                          distance: 160,
                          parent: true,
                          child: TextListe(
                            clearable: false,
                            value: selectedCurrency,
                            items: _availableCurrencies,
                            onChanged: (v) =>
                                setState(() => selectedCurrency = v ?? selectedCurrency),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ChampAvecLabel(
                          label: l10n.quantityDecimals,
                          distance: 160,
                          parent: true,
                          child: Builder(
                            builder: (context) {
                              const items = <int, String>{0: '0', 1: '1', 2: '2'};
                              return TextListe(
                                clearable: false,
                                value: items[decimalesQuantite],
                                items: items.values.toList(),
                                onChanged: (v) {
                                  final decimales =
                                      items.entries.firstWhere((e) => e.value == v).key;
                                  setState(() => decimalesQuantite = decimales);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        ChampAvecLabel(
                          label: l10n.shopName,
                          distance: 400,
                          parent: true,
                          obligatoire: true,
                          child: TextChampL(
                            controller: _nomBoutiqueController,
                            obligatoire: true,
                            hint: l10n.enterShopName,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ChampAvecLabel(
                          label: l10n.shopAddress,
                          distance: 400,
                          parent: true,
                          child: TextChampL(controller: _adresseController, hint: l10n.shopAddressHint),
                        ),
                        const SizedBox(height: 10),
                        ChampAvecLabel(
                          label: l10n.shopPhone,
                          distance: 400,
                          parent: true,
                          child: TextChampL(controller: _telephoneController, hint: ''),
                        ),
                        const SizedBox(height: 10),
                        ChampAvecLabel(
                          label: l10n.shopEmail,
                          distance: 400,
                          parent: true,
                          child: TextChampL(controller: _emailController, hint: ''),
                        ),
                        const SizedBox(height: 10),
                        ChampAvecLabel(
                          label: l10n.ticketMessage,
                          distance: 400,
                          parent: true,
                          child: TextChampL(
                            controller: _messageTicketController,
                            hint: l10n.ticketMessageHint,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ChampAvecLabel(
                                label: l10n.rcLabel,
                                distance: 150,
                                parent: true,
                                child: TextChampL(controller: _rcController, hint: ''),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ChampAvecLabel(
                                label: l10n.nifLabel,
                                distance: 150,
                                parent: true,
                                child: TextChampL(controller: _nifController, hint: ''),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ChampAvecLabel(
                                label: l10n.nisLabel,
                                distance: 150,
                                parent: true,
                                child: TextChampL(controller: _nisController, hint: ''),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ChampAvecLabel(
                                label: l10n.articleLabel,
                                distance: 150,
                                parent: true,
                                child: TextChampL(controller: _articleController, hint: ''),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.paymentMethodsSection,
                          style: Appstyle.textSB.copyWith(color: Appstyle.TgrisF),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.especes),
                          value: especesVisible,
                          onChanged: (v) => setState(() => especesVisible = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.carte),
                          value: carteVisible,
                          onChanged: (v) => setState(() => carteVisible = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.cheque),
                          value: chequeVisible,
                          onChanged: (v) => setState(() => chequeVisible = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.virement),
                          value: virementVisible,
                          onChanged: (v) => setState(() => virementVisible = v),
                        ),
                      ],
                    ),
                  ),
                ),
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MainButton(
                      text: l10n.cancel,
                      icon: Icons.cancel,
                      color: Appstyle.gris,
                      onPressed: isSaving ? null : () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: isSaving ? l10n.saving : l10n.finish,
                      icon: Icons.check_circle_outline,
                      color: Appstyle.violet,
                      onPressed: isSaving ? null : save,
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
