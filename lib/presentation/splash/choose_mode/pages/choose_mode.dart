import 'dart:ui';

import 'package:fit_track_app/data/core/configs/theme/assets/app_images.dart';
import 'package:fit_track_app/data/core/configs/theme/assets/app_vectors.dart';
import 'package:fit_track_app/presentation/auth/pages/signup_or_signin.dart';
import 'package:fit_track_app/presentation/splash/choose_mode/pages/bloc/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class ChooseModePage extends StatelessWidget {
  const ChooseModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo com imagem
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage(AppImages.chooseModeBG),
              ),
            ),
          ),

          // Conteúdo principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  SvgPicture.asset(
                    AppVectors.logo_white,
                    alignment: Alignment.topCenter,
                    height: 250,
                  ),

                  // Espaço após logo
                  const SizedBox(height: 155),

                  // Texto + Botões de modo
                  Column(
                    children: [
                      const Text(
                        'Escolha o modo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 5,
                      ), // Espaçamento de 5px entre texto e botões
                      // Botões de modo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Dark Mode
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  context.read<ThemeCubit>().updateTheme(
                                    ThemeMode.dark,
                                  );
                                },
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Container(
                                      height: 80,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(
                                          0xFF343434,
                                        ).withOpacity(0.5),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: SvgPicture.asset(
                                          AppVectors.moon,
                                          fit: BoxFit.scaleDown,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Dark Mode',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 50),
                          // Light Mode
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  context.read<ThemeCubit>().updateTheme(
                                    ThemeMode.light,
                                  );
                                },
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Container(
                                      height: 80,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(
                                          0xFF343434,
                                        ).withOpacity(0.5),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: SvgPicture.asset(
                                          AppVectors.sun,
                                          fit: BoxFit.scaleDown,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Light Mode',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(), // empurra o botão "Começa Já" para o fim da tela
                  // Botão branco "Começa Já"
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const SignUpOrSignInPage(),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Começa Já',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
