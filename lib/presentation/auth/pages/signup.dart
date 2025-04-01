import 'package:fit_track_app/data/core/usecase/auth/signup.dart';
import 'package:fit_track_app/data/models/auth/create_user_req.dart';
import 'package:fit_track_app/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:fit_track_app/data/core/configs/theme/assets/app_vectors.dart';
import 'package:fit_track_app/data/core/configs/theme/assets/app_images.dart';
import 'package:fit_track_app/presentation/auth/pages/login.dart';

class SignupPage extends StatelessWidget {
  SignupPage({super.key});

  final TextEditingController _Name = TextEditingController();
  final TextEditingController _Lastname = TextEditingController();
  final TextEditingController _Email = TextEditingController();
  final TextEditingController _Password = TextEditingController();
  final TextEditingController _ConfirmPassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    );

    final hintStyle = TextStyle(
      color: const Color.fromARGB(255, 180, 180, 180),
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

          // CONTEÚDO POR CIMA
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

                      // Primeira linha: nome e apelido
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: TextFormField(
                                controller: _Name,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: 'Primeiro Nome',
                                  hintStyle: hintStyle,
                                  border: inputBorder,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              child: TextFormField(
                                controller: _Lastname,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: 'Último Nome',
                                  hintStyle: hintStyle,
                                  border: inputBorder,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

                      // Confirmar palavra-passe
                      TextFormField(
                        controller: _ConfirmPassword,
                        obscureText: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Confirmar Palavra-passe',
                          hintStyle: hintStyle,
                          border: inputBorder,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Botão "Registar"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = _Name.text.trim();
                            final lastname = _Lastname.text.trim();
                            final email = _Email.text.trim();
                            final password = _Password.text;
                            final confirmPassword = _ConfirmPassword.text;

                            if (password != confirmPassword) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'As palavras-passe não coincidem',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            var result = await sl<SignupUseCase>().call(
                              params: CreateUserReq(
                                name: name,
                                lastname: lastname,
                                email: email,
                                password: password,
                              ),
                            );

                            result.fold(
                              (l) {
                                // Erro (left)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l.toString()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                              (r) {
                                // Sucesso (right)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Conta criada com sucesso!',
                                    ),
                                    backgroundColor: Colors.grey[800],
                                  ),
                                );

                                // Redirecionar após 2 segundos
                                Future.delayed(const Duration(seconds: 1), () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => LoginPage(),
                                    ),
                                  );
                                });
                              },
                            );
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
                            'Registar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Frase com "Faz Login" que redireciona
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Já tens conta? ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => LoginPage(),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            child: const Text(
                              'Faz Login',
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
