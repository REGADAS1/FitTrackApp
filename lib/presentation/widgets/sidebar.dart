// lib/presentation/widgets/sidebar.dart

import 'package:fit_track_app/presentation/menus/chat_page.dart';
import 'package:fit_track_app/presentation/menus/dashboard_page.dart';
import 'package:fit_track_app/presentation/menus/feed_page.dart';
import 'package:fit_track_app/presentation/menus/training_plans.dart';
import 'package:fit_track_app/presentation/menus/user_profile_page.dart';
import 'package:flutter/material.dart';

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

          // Início
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

          // Feed
          ListTile(
            leading: const Icon(Icons.rss_feed, color: Colors.white),
            title: const Text('Feed', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const FeedPage()));
              onClose();
            },
          ),

          // Perfil
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

          // Planos de Treino
          ListTile(
            leading: const Icon(Icons.fitness_center, color: Colors.white),
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

          // Chat
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.white),
            title: const Text('Chat', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ChatPage()));
              onClose();
            },
          ),

          const Spacer(),

          // Fechar menu
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
