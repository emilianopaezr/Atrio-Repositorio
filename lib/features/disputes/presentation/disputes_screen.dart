import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/providers/disputes_provider.dart';
import '../../../core/models/dispute_model.dart';
import '../../../core/utils/extensions.dart';

class DisputesScreen extends ConsumerWidget {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(disputeFilterProvider);
    final disputesAsync = ref.watch(filteredDisputesProvider);

    return Scaffold(
      backgroundColor: AtrioColors.hostBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AtrioColors.hostSurfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.arrow_back, color: AtrioColors.hostTextPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('Disputas', style: AtrioTypography.headingLarge.copyWith(color: AtrioColors.hostTextPrimary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AtrioColors.hostSurfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.filter_list, color: AtrioColors.hostTextPrimary, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _FilterChip(label: 'Todas', value: 'todas', current: filter, ref: ref),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Abiertas', value: 'abiertas', current: filter, ref: ref),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'En Revisión', value: 'en_revision', current: filter, ref: ref),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Cerradas', value: 'cerradas', current: filter, ref: ref),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: disputesAsync.when(
                data: (disputes) {
                  if (disputes.isEmpty) {
                    return Center(
                      child: Text('No hay disputas', style: AtrioTypography.bodyLarge.copyWith(color: AtrioColors.hostTextSecondary)),
                    );
                  }
                  return RefreshIndicator(
                    color: AtrioColors.neonLimeDark,
                    onRefresh: () async => ref.invalidate(filteredDisputesProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: disputes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _DisputeCard(dispute: disputes[index]),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 48, color: AtrioColors.error.withValues(alpha: 0.6)),
                      const SizedBox(height: 16),
                      Text('Error al cargar disputas', style: AtrioTypography.bodyMedium.copyWith(color: AtrioColors.hostTextSecondary)),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(filteredDisputesProvider),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Reintentar'),
                        style: TextButton.styleFrom(foregroundColor: AtrioColors.neonLimeDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AtrioColors.neonLime,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Próximamente: Crear nueva disputa')),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final WidgetRef ref;

  const _FilterChip({required this.label, required this.value, required this.current, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isActive = current == value;
    return GestureDetector(
      onTap: () => ref.read(disputeFilterProvider.notifier).setFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AtrioColors.neonLimeDark : AtrioColors.hostSurfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? AtrioColors.hostTextPrimary : AtrioColors.hostTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _DisputeCard extends StatelessWidget {
  final DisputeModel dispute;
  const _DisputeCard({required this.dispute});

  Color get _statusColor {
    switch (dispute.status) {
      case 'abierta': return AtrioColors.success;
      case 'en_revision': return AtrioColors.warning;
      case 'resuelta': return AtrioColors.neonLimeDark;
      case 'cerrada': return AtrioColors.hostTextTertiary;
      default: return AtrioColors.hostTextSecondary;
    }
  }

  String get _statusLabel {
    switch (dispute.status) {
      case 'abierta': return 'Abierta';
      case 'en_revision': return 'En Revisión';
      case 'resuelta': return 'Resuelta';
      case 'cerrada': return 'Cerrada';
      default: return dispute.status;
    }
  }

  IconData get _typeIcon {
    switch (dispute.type) {
      case 'limpieza': return Icons.cleaning_services;
      case 'daños': return Icons.broken_image;
      case 'cancelación': return Icons.cancel;
      case 'servicio': return Icons.room_service;
      default: return Icons.report_problem;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/dispute/${dispute.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AtrioColors.hostCardBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AtrioColors.neonLimeDark.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_typeIcon, color: AtrioColors.neonLimeDark, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dispute.title, style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.hostTextPrimary)),
                      const SizedBox(height: 2),
                      Text('#${dispute.id}', style: AtrioTypography.caption.copyWith(color: AtrioColors.hostTextSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AtrioColors.neonLimeDark.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dispute.amount.toCLP,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AtrioColors.neonLime),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(_statusLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: _statusColor)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: dispute.priority == 'alta'
                        ? AtrioColors.error.withValues(alpha: 0.15)
                        : dispute.priority == 'media'
                            ? AtrioColors.warning.withValues(alpha: 0.15)
                            : AtrioColors.hostSurfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dispute.priority == 'alta' ? 'Alta' : dispute.priority == 'media' ? 'Media' : 'Baja',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: dispute.priority == 'alta' ? AtrioColors.error : dispute.priority == 'media' ? AtrioColors.warning : AtrioColors.hostTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
