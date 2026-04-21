import 'package:flutter/material.dart';
import 'package:sigetu/features/admin/data/admin_sede_roles_api.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_form_section_card.dart';

class AdminSedeStaffStep extends StatelessWidget {
  const AdminSedeStaffStep({
    super.key,
    required this.staffUsers,
    required this.sedeStaffUsers,
    required this.selectedStaffUserIds,
    required this.searchQuery,
    required this.isLoading,
    required this.infoMessage,
    required this.errorMessage,
    required this.onSearchChanged,
    required this.onToggleUser,
  });

  final List<AdminStaffUser> staffUsers;
  final List<AdminStaffUser> sedeStaffUsers;
  final Set<int> selectedStaffUserIds;
  final String searchQuery;
  final bool isLoading;
  final String? infoMessage;
  final String? errorMessage;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onToggleUser;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final assignedStaffIds = sedeStaffUsers.map((staff) => staff.id).toSet();

    final filteredSedeStaffUsers = normalizedQuery.isEmpty
      ? sedeStaffUsers
      : sedeStaffUsers.where((staff) {
        final name = staff.fullName.toLowerCase();
        final email = staff.email.toLowerCase();
        return name.contains(normalizedQuery) || email.contains(normalizedQuery);
        }).toList();

    final filteredStaffUsers = normalizedQuery.isEmpty
        ? staffUsers
        : staffUsers.where((staff) {
            final name = staff.fullName.toLowerCase();
            final email = staff.email.toLowerCase();
            return name.contains(normalizedQuery) || email.contains(normalizedQuery);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFormSectionCard(
          icon: Icons.group_add_outlined,
          title: 'Asignar Staff',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (infoMessage != null) ...[
                Text(
                  infoMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 10),
              ],
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre o correo',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              if (!isLoading) ...[
                Text(
                  'Actualmente en esta sede (activos): ${sedeStaffUsers.length}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (filteredSedeStaffUsers.isEmpty)
                  const Text('No hay staff activo asociado a esta sede.')
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredSedeStaffUsers.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final staff = filteredSedeStaffUsers[index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.verified_user_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          title: Text(staff.fullName),
                          subtitle: staff.email.isEmpty ? null : Text(staff.email),
                          trailing: const Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text('Pertenece'),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Disponibles para asignar',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (staffUsers.isEmpty)
                const Text('No hay usuarios staff disponibles.')
              else if (filteredStaffUsers.isEmpty)
                const Text('No hay resultados para la búsqueda.')
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredStaffUsers.length,
                    itemBuilder: (context, index) {
                      final staff = filteredStaffUsers[index];
                      final isSelected = selectedStaffUserIds.contains(staff.id);
                      final alreadyAssigned = assignedStaffIds.contains(staff.id);
                      return CheckboxListTile(
                        value: isSelected,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(staff.displayLabel),
                        subtitle: alreadyAssigned
                            ? Text(
                                'Ya pertenece a la sede',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                        onChanged: alreadyAssigned ? null : (_) => onToggleUser(staff.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
