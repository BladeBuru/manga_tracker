import 'package:dashbook/dashbook.dart';
import 'package:flutter/material.dart';
import '../../core/components/intput_textfield.dart';
import '../../core/theme/app_theme.dart';

void addInputTextFieldStory(Dashbook dashbook) {
  dashbook.storiesOf('Core/InputTextField').add('Variantes', (_) {
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text("Champs texte - Variantes")),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  // Champ Email
                  IntputTexteField(
                    controller: emailController,
                    hintText: "Adresse e-mail",
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Veuillez saisir une adresse e-mail.";
                      }
                      if (!value.contains('@')) {
                        return "Adresse invalide.";
                      }
                      return null;
                    },
                    prefixIcon: const Icon(Icons.email),
                  ),

                  const SizedBox(height: 20),

                  // Champ Username
                  IntputTexteField(
                    controller: usernameController,
                    hintText: "Nom d'utilisateur",
                    prefixIcon: const Icon(Icons.person),
                    autofillHints: const [AutofillHints.username],
                  ),

                  const SizedBox(height: 20),

                  // Champ Mot de passe
                  IntputTexteField(
                    controller: passwordController,
                    hintText: "Mot de passe",
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    prefixIcon: const Icon(Icons.lock),
                  ),

                  const SizedBox(height: 20),

                  // Champ Numéro de téléphone
                  IntputTexteField(
                    controller: phoneController,
                    hintText: "Téléphone",
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    prefixIcon: const Icon(Icons.phone),
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: () {
                      final valid = formKey.currentState?.validate() ?? false;
                      debugPrint("Formulaire valide : $valid");
                    },
                    child: const Text("Valider les champs"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  });
}
