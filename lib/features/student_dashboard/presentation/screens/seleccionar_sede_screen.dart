import 'package:flutter/material.dart';
import 'package:sigetu/core/widgets/section_header.dart';
import 'package:sigetu/features/student_dashboard/presentation/widgets/dashboard_card.dart';

class SeleccionarSedeScreen extends StatelessWidget {
  const SeleccionarSedeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar sede')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SectionHeader(
              title: 'Selecciona la sede',
              subtitle: 'Elige la ubicación donde deseas solicitar tu turno',
            ),
            const SizedBox(height: 24),
            DashboardCard(
              title: 'Sede Principal',
              subtitle: 'Cl 5 ##385, Centro, Popayán, Cauca',
              icon: Icons.location_on_outlined,
              onTap: () {
                // Acción al seleccionar esta sede
              },
            ),
          ],
        ),
      ),
    );
  }
}
