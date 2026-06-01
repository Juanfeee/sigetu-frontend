import 'package:flutter/material.dart';
import 'package:sigetu/core/auth/auth_session.dart';
import 'package:sigetu/core/utils/responsive.dart';
import 'package:sigetu/core/widgets/section_header.dart';
import 'package:sigetu/features/headquarters/presentation/screens/admisiones_mercadeo_screen.dart';
import 'package:sigetu/features/headquarters/presentation/screens/asistencia_estudiantil_screen.dart';
import 'package:sigetu/features/headquarters/presentation/screens/sede_administrativa_screen.dart';
import 'package:sigetu/features/student_dashboard/presentation/widgets/dashboard_card.dart';

class SeleccionarSedeScreen extends StatelessWidget {
  const SeleccionarSedeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.horizontalPadding(context);
    final isWide = !Responsive.isMobile(context);
    final isGuest = AuthSession.isGuest;

    Widget cardAsistencia = isGuest
        ? _LockedCard(
            title: 'Asistencia Estudiantil',
            subtitle: 'Disponible solo para usuarios registrados',
            icon: Icons.support_agent_outlined,
          )
        : DashboardCard(
            title: 'Asistencia Estudiantil',
            subtitle: 'Orientación y apoyo académico',
            imagePath: 'assets/images/asistencia_estudiantil.png',
            icon: Icons.support_agent_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AsistenciaEstudiantilScreen(),
                ),
              );
            },
          );

    Widget cardAdministrativa = isGuest
        ? _LockedCard(
            title: 'Sede Administrativa',
            subtitle: 'Disponible solo para usuarios registrados',
            icon: Icons.apartment_outlined,
          )
        : DashboardCard(
            title: 'Sede Administrativa',
            subtitle: 'Trámites y documentación',
            imagePath: 'assets/images/asistencia_estudiantil.png',
            icon: Icons.apartment_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SedeAdministrativaScreen(),
                ),
              );
            },
          );

    Widget cardAdmisiones = DashboardCard(
      title: 'Admisiones y mercadeo',
      subtitle: 'Procesos de inscripción y matrícula',
      imagePath: 'assets/images/asistencia_estudiantil.png',
      icon: Icons.how_to_reg_outlined,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdmisionesMercadeoScreen()),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar sede')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
            children: [
              const SectionHeader(
                title: 'Selecciona la sede',
                subtitle: 'Elige la ubicación donde deseas solicitar tu turno',
              ),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cardAsistencia),
                    const SizedBox(width: 16),
                    Expanded(child: cardAdministrativa),
                    const SizedBox(width: 16),
                    Expanded(child: cardAdmisiones),
                  ],
                )
              else ...[
                cardAsistencia,
                const SizedBox(height: 16),
                cardAdministrativa,
                const SizedBox(height: 16),
                cardAdmisiones,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta bloqueada para modo invitado
class _LockedCard extends StatelessWidget {
  const _LockedCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: 0.45,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: scheme.onSurface),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.lock_outline, size: 18, color: scheme.onSurface),
          ],
        ),
      ),
    );
  }
}
