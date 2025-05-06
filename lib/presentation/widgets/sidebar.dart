import 'package:fit_track_app/presentation/menus/chat_page.dart';
import 'package:fit_track_app/presentation/menus/dashboard_page.dart';
import 'package:fit_track_app/presentation/menus/training_plans.dart';
import 'package:flutter/material.dart';
import 'package:fit_track_app/presentation/menus/user_profile_page.dart';

class Sidebar extends StatelessWidget {
  final double width;
  final VoidCallback onClose;

  const Sidebar({super.key, required this.width, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),

          // Opção: Início (exemplo de item que só fecha o menu)
          ListTile(
            leading: const Icon(Icons.home, color: Colors.white),
            title: const Text('Início', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const DashboardPage()));
              onClose();
            },
          ),

          // Opção: Perfil (navega para UserProfilePage)
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text('Perfil', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UserProfilePage()),
              );
              onClose();
            },
          ),

          // Opção: Definições
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text(
              'Planos de Treino',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TrainingPlansPage()),
              );
              onClose();
            },
          ),

          // Opção: Definições
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text('Chat', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ChatPage()));
              onClose();
            },
          ),

          const Spacer(),

          // Botão de Fechar (opcional)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton.icon(
              onPressed: onClose,
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white70,
                size: 16,
              ),
              label: const Text(
                'Fechar menu',
                style: TextStyle(color: Colors.white70),
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
