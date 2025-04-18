import 'dart:async';
import 'package:fit_track_app/presentation/auth/pages/signup.dart';
import 'package:fit_track_app/presentation/auth/pages/check_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fit_track_app/data/core/configs/theme/assets/app_vectors.dart';
import 'package:fit_track_app/data/core/configs/theme/assets/app_images.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final TextEditingController _Email = TextEditingController();
  final TextEditingController _Password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    );

    final hintStyle = const TextStyle(
      color: Color.fromARGB(255, 180, 180, 180),
    );

    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppImages.signupOrsigninBG),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // CONTEÚDO
          Column(
            children: [
              // Botão de voltar
              SafeArea(
                child: Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.only(left: 16, top: 12),
                  child: ClipOval(
                    child: Material(
                      color: Colors.black45,
                      child: InkWell(
                        splashColor: Colors.white24,
                        onTap: () => Navigator.pop(context),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Formulário
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      // Logo
                      SvgPicture.asset(AppVectors.logo_white, height: 250),
                      const SizedBox(height: 0),

                      // Email
                      TextFormField(
                        controller: _Email,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Email',
                          hintStyle: hintStyle,
                          border: inputBorder,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Palavra-passe
                      TextFormField(
                        controller: _Password,
                        obscureText: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Palavra-passe',
                          hintStyle: hintStyle,
                          border: inputBorder,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Botão "Login"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final email = _Email.text.trim();
                            final password = _Password.text;

                            try {
                              await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                    email: email,
                                    password: password,
                                  );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Login efetuado com sucesso!',
                                  ),
                                  backgroundColor: Colors.grey[800],
                                  duration: const Duration(milliseconds: 1300),
                                ),
                              );

                              await Future.delayed(
                                const Duration(milliseconds: 1500),
                              );

                              // Redireciona para verificação de perfil
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CheckProfilePage(),
                                ),
                              );
                            } on FirebaseAuthException catch (e) {
                              String errorMessage;

                              switch (e.code) {
                                case 'user-not-found':
                                  errorMessage =
                                      'Nenhuma conta encontrada com esse email.';
                                  break;
                                case 'wrong-password':
                                  errorMessage = 'Palavra-passe incorreta.';
                                  break;
                                case 'invalid-email':
                                  errorMessage = 'Email inválido.';
                                  break;
                                default:
                                  errorMessage =
                                      'Erro ao fazer login. Tenta novamente.';
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Frase com "Registar" clicável
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Ainda não tens conta? ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => SignupPage()),
                              );
                            },
                            child: const Text(
                              'Regista-te',
                              style: TextStyle(
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
