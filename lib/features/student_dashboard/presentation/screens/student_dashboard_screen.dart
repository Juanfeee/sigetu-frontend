import 'package:flutter/material.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Estudiante'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _DashboardCard(
              title: 'Mis Turnos',
              icon: Icons.calendar_today_outlined,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _DashboardCard(
              title: 'Solicitar Turno',
              icon: Icons.add_circle_outline,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _DashboardCard(
              title: 'Perfil',
              icon: Icons.person_outline,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded),
        onTap: onTap,
      ),
    );
  }
}
