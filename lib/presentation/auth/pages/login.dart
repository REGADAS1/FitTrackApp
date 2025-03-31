import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:fit_track_app/data/core/configs/theme/assets/app_vectors.dart';
import 'package:fit_track_app/data/core/configs/theme/assets/app_images.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    );

    final hintStyle = TextStyle(color: Colors.grey[700]);

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
                          onPressed: () {
                            // Ação de login
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
                              Navigator.pop(
                                context,
                              ); // ou push para SignupPage()
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
