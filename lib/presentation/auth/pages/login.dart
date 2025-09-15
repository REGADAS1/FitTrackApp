import 'dart:async';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fit_track_app/presentation/auth/pages/signup.dart';
import 'package:fit_track_app/presentation/auth/pages/check_profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fit_track_app/data/core/configs/theme/assets/app_images.dart';

const String kKeepSignedInKey = 'keep_signed_in';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;
  bool _keepSignedIn = true; // default

  @override
  void initState() {
    super.initState();
    _loadKeepSignedIn();
  }

  Future<void> _loadKeepSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _keepSignedIn = prefs.getBool(kKeepSignedInKey) ?? true;
    });
  }

  Future<void> _saveKeepSignedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kKeepSignedInKey, value);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  OutlineInputBorder _inputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    );
  }

  InputDecoration _decoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      hintStyle: const TextStyle(color: Color.fromARGB(255, 120, 120, 120)),
      border: _inputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preenche email e palavra-passe.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      // No Web, define a persistência antes de fazer login:
      if (kIsWeb) {
        // LOCAL => mantém sessão mesmo após fechar o browser/app
        // SESSION => limpa ao fechar o separador/app
        await FirebaseAuth.instance.setPersistence(
          _keepSignedIn ? Persistence.LOCAL : Persistence.SESSION,
        );
      }
      // Em Android/iOS, o Firebase já persiste por defeito até signOut()

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // guarda a preferência (para o arranque da app)
      await _saveKeepSignedIn(_keepSignedIn);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Login efetuado com sucesso!',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          duration: Duration(milliseconds: 1300),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CheckProfilePage()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Nenhuma conta encontrada com esse email.';
          break;
        case 'wrong-password':
          errorMessage = 'Palavra-passe incorreta.';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido.';
          break;
        default:
          errorMessage = 'Erro ao fazer login. Tenta novamente.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocorreu um erro inesperado.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _keepSignedInControl() {
    return InkWell(
      onTap: () async {
        setState(() => _keepSignedIn = !_keepSignedIn);
        await _saveKeepSignedIn(_keepSignedIn);
      },
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: _keepSignedIn ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow:
                  _keepSignedIn
                      ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : [],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child:
                  _keepSignedIn
                      ? const Icon(
                        Icons.check,
                        key: ValueKey('on'),
                        size: 18,
                        color: Colors.black,
                      )
                      : const SizedBox(key: ValueKey('off')),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Manter sessão iniciada',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      Image.asset('assets/images/adpro_white.png', height: 160),
                      const SizedBox(height: 24),

                      // Email
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.black),
                        cursorColor: Colors.black,
                        decoration: _decoration(hint: 'Email'),
                      ),
                      const SizedBox(height: 16),

                      // Palavra-passe
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        style: const TextStyle(color: Colors.black),
                        cursorColor: Colors.black,
                        decoration: _decoration(
                          hint: 'Palavra-passe',
                          suffixIcon: IconButton(
                            onPressed:
                                () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.black54,
                            ),
                            tooltip:
                                _obscure
                                    ? 'Mostrar palavra-passe'
                                    : 'Ocultar palavra-passe',
                          ),
                        ),
                        onFieldSubmitted: (_) => _handleLogin(),
                      ),
                      const SizedBox(height: 18),

                      // Checkbox "Manter sessão iniciada"
                      _keepSignedInControl(),
                      const SizedBox(height: 24),

                      // Botão "Login"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
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
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => SignupPage(),
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
