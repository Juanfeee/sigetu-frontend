import 'package:flutter/material.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_form_section_card.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_toggle_card.dart';

class AdminSedeFormStep extends StatelessWidget {
  const AdminSedeFormStep({
    super.key,
    required this.formKey,
    required this.codigoController,
    required this.nombreController,
    required this.ubicacionController,
    required this.descripcionController,
    required this.esPublica,
    required this.filtrarCitasPorPrograma,
    required this.activo,
    required this.onEsPublicaChanged,
    required this.onFiltrarCitasChanged,
    required this.onActivoChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController codigoController;
  final TextEditingController nombreController;
  final TextEditingController ubicacionController;
  final TextEditingController descripcionController;
  final bool esPublica;
  final bool filtrarCitasPorPrograma;
  final bool activo;
  final ValueChanged<bool> onEsPublicaChanged;
  final ValueChanged<bool> onFiltrarCitasChanged;
  final ValueChanged<bool> onActivoChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          AdminFormSectionCard(
            icon: Icons.badge_outlined,
            title: 'Nombre de la Sede',
            child: TextFormField(
              controller: nombreController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Ej: Sede Administrativa',
                border: InputBorder.none,
                isDense: true,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 2) return 'Mínimo 2 caracteres';
                if (text.length > 120) return 'Máximo 120 caracteres';
                return null;
              },
            ),
          ),
          const SizedBox(height: 14),
          AdminFormSectionCard(
            icon: Icons.location_on_outlined,
            title: 'Dirección',
            child: TextFormField(
              controller: ubicacionController,
              textInputAction: TextInputAction.next,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ej: Calle 5 # 3-85, Popayán',
                border: InputBorder.none,
                isDense: true,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'La ubicación es obligatoria';
                if (text.length > 255) return 'Máximo 255 caracteres';
                return null;
              },
            ),
          ),
          const SizedBox(height: 14),
          AdminFormSectionCard(
            icon: Icons.confirmation_number_outlined,
            title: 'Código interno',
            child: TextFormField(
              controller: codigoController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Ej: sede123',
                border: InputBorder.none,
                isDense: true,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 2) return 'Mínimo 2 caracteres';
                if (text.length > 50) return 'Máximo 50 caracteres';
                return null;
              },
            ),
          ),
          const SizedBox(height: 14),
          AdminFormSectionCard(
            icon: Icons.notes_outlined,
            title: 'Descripción',
            subtitle: 'Opcional',
            child: TextFormField(
              controller: descripcionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Descripción breve de la sede',
                border: InputBorder.none,
                isDense: true,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length > 255) return 'Máximo 255 caracteres';
                return null;
              },
            ),
          ),
          const SizedBox(height: 14),
          AdminToggleCard(
            items: [
              AdminToggleItem(
                title: 'Es pública',
                value: esPublica,
                onChanged: onEsPublicaChanged,
              ),
              AdminToggleItem(
                title: 'Filtrar citas por programa',
                value: filtrarCitasPorPrograma,
                onChanged: onFiltrarCitasChanged,
              ),
              AdminToggleItem(
                title: 'Activa',
                value: activo,
                onChanged: onActivoChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
