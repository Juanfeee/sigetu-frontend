import 'package:flutter/material.dart';
import 'package:sigetu/core/utils/responsive.dart';
import 'package:sigetu/core/widgets/section_header.dart';
import 'package:sigetu/features/headquarters/presentation/screens/seleccionar_sede_screen.dart';
import 'package:sigetu/features/student_dashboard/presentation/widgets/dashboard_card.dart';
import 'package:sigetu/core/theme/app_gradients.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = !Responsive.isMobile(context);
    final hPad = Responsive.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'SIGETU - UNIAUTÓNOMA',
                  subtitle: 'Solicita tus turnos de manera fácil y rápida',
                ),
                const SizedBox(height: 20),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSolicitarTurnoCard(context)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildMisTurnosCard(context)),
                    ],
                  )
                else ...[
                  _buildSolicitarTurnoCard(context),
                  const SizedBox(height: 16),
                  _buildMisTurnosCard(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolicitarTurnoCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Solicitar turno: Agenda una nueva cita',
      child: DashboardCard(
        title: 'Solicitar Turno',
        subtitle: 'Agenda una nueva cita',
        icon: Icons.calendar_month_outlined,
        gradient: AppGradients.primary(context),
        textColor: scheme.onPrimary,
        iconColor: scheme.onPrimary,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SeleccionarSedeScreen()),
          );
        },
      ),
    );
  }

  Widget _buildMisTurnosCard(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Mis turnos: Consulta tus turnos asignados',
      child: DashboardCard(
        title: 'Mis Turnos',
        subtitle: 'Consulta tus turnos asignados',
        icon: Icons.list_outlined,
        onTap: () {},
      ),
    );
  }
}
