// lib/widgets/pt_sidebar.dart

import 'package:flutter/material.dart';
import 'package:fit_track_app/data/core/configs/theme/assets/app_images.dart';
import 'package:fit_track_app/PT/pages/pt_dashboard.dart';
import 'package:fit_track_app/PT/pages/exercise_list.dart';

class PTSidebar extends StatelessWidget {
  final String currentRoute;

  const PTSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2C2C2C),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black87),
            child: Center(
              child: SizedBox(
                height: 120,
                child: Image.asset(
                  'assets/images/nvrtap_white.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.dashboard,
            label: 'Dashboard',
            route: '/',
            destination: const PTDashboardPage(),
          ),
          _buildMenuItem(
            context,
            icon: Icons.people,
            label: 'Alunos',
            route: '/alunos',
            destination:
                const PTDashboardPage(), // substitui se tiveres outra página
          ),
          _buildMenuItem(
            context,
            icon: Icons.fitness_center,
            label: 'Exercícios',
            route: '/exercicios',
            destination: const ExerciseListPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required Widget destination,
  }) {
    final isActive = currentRoute == route;

    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      tileColor: isActive ? Colors.black45 : null,
      onTap: () {
        if (!isActive) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        } else {
          Navigator.pop(context);
        }
      },
    );
  }
}
