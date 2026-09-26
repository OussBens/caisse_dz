import 'dart:convert';
import 'dart:io';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Identifiants créés automatiquement en base une fois l'app activée (voir
// DBCreate._insertDefaultData) — affichés ici pour que le client sache tout
// de suite avec quoi se connecter, sans avoir à nous les redemander.
const String kDefaultAdminUsername = 'admin';
const String kDefaultAdminPassword = '123456';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final TextEditingController keyController         = TextEditingController();
  final TextEditingController emailController       = TextEditingController();
  final TextEditingController clientNameController  = TextEditingController();

  bool activating = false;
  String? error;

  /// Generates machine ID (for support/logging)
  String generateMachineId() {
    final raw = Platform.localHostname +
        (Platform.environment['USERNAME'] ?? "") +
        Platform.operatingSystem;

    return sha256.convert(utf8.encode(raw)).toString();
  }

  /// Copy activation request to clipboard
  void copyRequestInfo() {
    final machineId = generateMachineId();

    final text = machineId;
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Demande copiée dans le presse-papier")),
    );
  }

  Future<void> _activer(AuthState auth) async {
    final key = keyController.text.trim();
    final machineId = generateMachineId();
    if (key.isEmpty) {
      setState(() => error = "Veuillez entrer une clé");
      return;
    }

    setState(() {
      activating = true;
      error = null;
    });

    final success = await auth.activateApp(key, machineId);

    if (!mounted) return;
    setState(() => activating = false);

    if (!success) {
      setState(() => error = "Clé invalide ❌");
      return;
    }

    await InformationDialog(
      context: context,
      width: 700,
      titre_type_message: "Activation",
      titre_concerne: "Application activée avec succès",
      message: "Voici votre identifiant de connexion :\n\n"
          "Utilisateur : $kDefaultAdminUsername\n"
          "Mot de passe : $kDefaultAdminPassword\n\n"
          "Vous pourrez le changer une fois connecté (Mon compte).",
      onTerminer: () {
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final machineId = generateMachineId();
    final auth = Provider.of<AuthState>(context, listen: false);

    return Scaffold(
      body: Row(
        // ✅ Même mise en page que l'écran de login (image à gauche,
        // formulaire à droite), toujours LTR quelle que soit la langue.
        textDirection: TextDirection.ltr,
        children: [
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/login_back.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "ACTIVATION",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 8,
                      ),
                    ),
                    SizedBox(height: 5),
                    SizedBox(width: 100, height: 4, child: ColoredBox(color: Colors.white)),
                    SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/caisse_dz_logo.png',
                        height: 100,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.shopping_cart,
                          size: 70,
                          color: Appstyle.violet,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Activation de l'application",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Appstyle.violet,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Envoyez-nous votre code machine pour recevoir votre clé d'activation.",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      _champ(
                        label: "Nom du client",
                        controller: clientNameController,
                        icon: Icons.person_outline,
                        hint: "Entrez le nom du client...",
                      ),
                      const SizedBox(height: 16),
                      _champ(
                        label: "Email du client",
                        controller: emailController,
                        icon: Icons.email_outlined,
                        hint: "Entrez l'email ici...",
                      ),
                      const SizedBox(height: 16),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Code machine :",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SelectableText(
                          machineId,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: copyRequestInfo,
                          icon: Icon(Icons.copy, color: Appstyle.violet, size: 18),
                          label: Text(
                            "Copier la demande d'activation",
                            style: TextStyle(color: Appstyle.violet),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Appstyle.violet),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Entrer la clé d'activation :",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: keyController,
                        maxLines: 3,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "Coller la clé ici...",
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Appstyle.violet, width: 2),
                          ),
                        ),
                      ),

                      // Identifiant qui sera utilisable juste après l'activation —
                      // affiché ici, avant même d'activer, pour que ce soit visible
                      // dès la première visite de cet écran (et pas seulement après
                      // succès, cf. le dialog affiché après activation).
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Appstyle.violetC,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Appstyle.violet, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Une fois activée, l'app se connecte avec :\n"
                                "Utilisateur : $kDefaultAdminUsername   —   Mot de passe : $kDefaultAdminPassword\n"
                                "(modifiable ensuite depuis Mon compte)",
                                style: TextStyle(fontSize: 12.5, color: Appstyle.violet, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  error!,
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: MainButton(
                          text: activating ? "Activation en cours..." : "Activer",
                          color: Appstyle.violet,
                          textColor: Colors.white,
                          iconColor: Colors.white,
                          icon: Icons.verified_outlined,
                          onPressed: activating ? null : () => _activer(auth),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _champ({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Appstyle.violet, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
