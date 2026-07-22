import 'dart:convert';
import 'dart:io';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final TextEditingController keyController         = TextEditingController();
  final TextEditingController emailController       = TextEditingController();
  final TextEditingController clientNameController  = TextEditingController();

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

    final text = '''
      Activation Request

        Client Name:
        ${clientNameController.text.trim()}

        Client Email:
        ${emailController.text.trim()}

        Machine ID:
        $machineId

        Transaction Name:
        ___________
      ''';

    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Demande copiée dans le presse-papier")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final machineId = generateMachineId();
    final auth = Provider.of<AuthState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Activation")),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Activation de l'application",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                /// Client Name
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Nom du client:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: clientNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Entrez le nom du client...",
                  ),
                ),
                const SizedBox(height: 20),

                /// Email
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Email du client:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Entrez l'email ici...",
                  ),
                ),
                const SizedBox(height: 20),

                /// Machine ID
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Machine ID:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 5),
                SelectableText(machineId),
                const SizedBox(height: 20),

                /// Copy Button
                ElevatedButton(
                  onPressed: copyRequestInfo,
                  child: const Text("Copier la demande d'activation"),
                ),

                const SizedBox(height: 30),

                /// Enter License Key
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Entrer la clé d'activation:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: keyController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Coller la clé ici...",
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    final key = keyController.text.trim();
                    final machineId = generateMachineId();
                    if (key.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Veuillez entrer une clé")),
                      );
                      return;
                    }
                    final success = await auth.activateApp(key, machineId);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Activation réussie ✅")),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Clé invalide ❌")),
                      );
                    }
                  },
                  child: const Text("Activer"),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
