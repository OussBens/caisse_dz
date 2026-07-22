import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/Auth/auth_state.dart';




class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  String? error;

  @override
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>(); // <-- synchronous, no await

    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Connexion",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: "Utilisateur"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Mot de passe"),
              ),
              const SizedBox(height: 20),

              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                  setState(() {
                    loading = true;
                    error = null;
                  });

                  final success = await auth.login(
                    usernameController.text.trim(),
                    passwordController.text.trim(),
                  );

                  if (!success) {
                    setState(() {
                      error = "Nom utilisateur ou mot de passe incorrect";
                      loading = false;
                    });
                  }

                },
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Se connecter"),
              ),

              const SizedBox(height: 15),

              /// ACTIVATE BUTTON (only if app is NOT activated)
              if (!auth.isActivated)
                TextButton(
                  onPressed: () {
                    context.push('/activate'); // <-- GoRouter navigation
                  },
                  child: const Text(
                    "Activer l'application",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}
