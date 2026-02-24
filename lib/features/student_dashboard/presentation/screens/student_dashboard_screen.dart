import 'package:flutter/material.dart';
import 'package:sigetu/core/widgets/section_header.dart';
import 'package:sigetu/features/student_dashboard/presentation/screens/seleccionar_sede_screen.dart';
import 'package:sigetu/features/student_dashboard/presentation/widgets/dashboard_card.dart';
import 'package:sigetu/core/theme/app_gradients.dart';

class StudentDashboardScreen extends StatelessWidget {

  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Estudiante')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SectionHeader(
              title: 'SIGETU - UNIAUTÓNOMA',
              subtitle: 'Solicita tus turnos de manera fácil y rápida',
            ),
            DashboardCard(
              title: 'Solicitar Turno',
              subtitle: 'Agenda una nueva cita',
              //icono con calendario y un signo de más
              icon: Icons.calendar_month_outlined,
              gradient: AppGradients.primary(context),
              textColor: Colors.white,
              iconColor: Colors.white,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SeleccionarSedeScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            DashboardCard(
              title: 'Mis Turnos',
              subtitle: 'Consulta tus turnos asignados',
              icon: Icons.list_outlined,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
