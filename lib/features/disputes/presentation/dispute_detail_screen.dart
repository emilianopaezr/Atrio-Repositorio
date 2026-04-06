import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/providers/disputes_provider.dart';
import '../../../core/utils/extensions.dart';

class DisputeDetailScreen extends ConsumerStatefulWidget {
  final String disputeId;
  const DisputeDetailScreen({super.key, required this.disputeId});

  @override
  ConsumerState<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends ConsumerState<DisputeDetailScreen> {
  int _selectedTab = 0;
  bool _defenseExpanded = false;

  @override
  Widget build(BuildContext context) {
    final disputeAsync = ref.watch(disputeDetailProvider(widget.disputeId));

    return Scaffold(
      backgroundColor: AtrioColors.hostBackground,
      body: disputeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Error al cargar. Intenta de nuevo.')),
        data: (dispute) {
          if (dispute == null) {
            return Center(child: Text('Disputa no encontrada', style: AtrioTypography.bodyLarge.copyWith(color: Colors.white)));
          }

          final guestName = dispute.guestData?['display_name'] ?? 'Huésped';
          final hostName = dispute.hostData?['display_name'] ?? 'Anfitrión';

          return SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        'DISPUTA #${dispute.id}',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1),
                      ),
                      const Spacer(),
                      const Icon(Icons.more_vert, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: AtrioColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Estado: ${dispute.status == 'abierta' ? 'Abierta' : dispute.status == 'en_revision' ? 'En Revisión' : dispute.status == 'resuelta' ? 'Resuelta' : 'Cerrada'}',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w100, color: AtrioColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main card
                        Container(
                          width: double.infinity,
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
                                  Expanded(
                                    child: Text(dispute.title, style: AtrioTypography.headingMedium.copyWith(color: Colors.white)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AtrioColors.neonLimeDark, AtrioColors.neonLime],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${dispute.amount.toCLP} en juego',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Reclamado hace 2 horas • ${dispute.priority == 'alta' ? 'Alta' : dispute.priority == 'media' ? 'Media' : 'Baja'} Prioridad',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w100, color: AtrioColors.hostTextSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Profiles
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AtrioColors.hostSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AtrioColors.hostCardBorder, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AtrioColors.neonLimeDark.withValues(alpha: 0.3),
                                      child: Text(guestName[0], style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(guestName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                                    Text('Huésped (Demandante)', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w100, color: AtrioColors.hostTextSecondary)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AtrioColors.hostSurfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.compare_arrows, color: AtrioColors.hostTextSecondary, size: 16),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AtrioColors.warning.withValues(alpha: 0.3),
                                      child: Text(hostName[0], style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(hostName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                                    Text('Anfitrión (Demandado)', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w100, color: AtrioColors.hostTextSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tabs
                        Container(
                          decoration: BoxDecoration(
                            color: AtrioColors.hostSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedTab = 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedTab == 0 ? AtrioColors.neonLimeDark : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Reporte del Huésped',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedTab == 0 ? Colors.white : AtrioColors.hostTextSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedTab = 1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedTab == 1 ? AtrioColors.neonLimeDark : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Defensa del Anfitrión',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedTab == 1 ? Colors.white : AtrioColors.hostTextSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Evidence section
                        if (_selectedTab == 0) ...[
                          Container(
                            width: double.infinity,
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
                                    const Icon(Icons.warning_amber, color: AtrioColors.warning, size: 18),
                                    const SizedBox(width: 8),
                                    Text('EVIDENCIA PRESENTADA', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AtrioColors.warning, letterSpacing: 0.5)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AtrioColors.hostSurfaceVariant,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    dispute.guestReport,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w100, color: AtrioColors.hostTextSecondary, fontStyle: FontStyle.italic, height: 1.5),
                                  ),
                                ),
                                if (dispute.guestEvidence.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 120,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: dispute.guestEvidence.length,
                                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                                      itemBuilder: (context, index) {
                                        return Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: CachedNetworkImage(
                                                imageUrl: dispute.guestEvidence[index],
                                                width: 140, height: 120, fit: BoxFit.cover,
                                                placeholder: (_, _) => Container(width: 140, height: 120, color: AtrioColors.hostSurfaceVariant),
                                                errorWidget: (_, _, _) => Container(
                                                  width: 140, height: 120, color: AtrioColors.hostSurfaceVariant,
                                                  child: const Icon(Icons.broken_image, color: AtrioColors.hostTextTertiary),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 6, right: 6,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.7),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  index == 0 ? '14:02 PM' : '14:05 PM',
                                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // Host defense
                        if (_selectedTab == 1 && dispute.hostDefense != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AtrioColors.hostSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AtrioColors.hostCardBorder, width: 0.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _defenseExpanded = !_defenseExpanded),
                                  child: Row(
                                    children: [
                                      Icon(Icons.circle, color: AtrioColors.neonLimeDark, size: 14),
                                      const SizedBox(width: 8),
                                      Text('DEFENSA DEL ANFITRIÓN', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AtrioColors.neonLime, letterSpacing: 0.5)),
                                      const Spacer(),
                                      Text(
                                        _defenseExpanded ? 'Colapsar' : 'Toca para expandir',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w100, color: AtrioColors.hostTextTertiary),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_defenseExpanded) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    dispute.hostDefense!,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w100, color: AtrioColors.hostTextSecondary, height: 1.5),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (_selectedTab == 1 && dispute.hostDefense == null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AtrioColors.hostSurface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'El anfitrión no ha presentado defensa aún.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w100, color: AtrioColors.hostTextTertiary),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Resolution Actions
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AtrioColors.hostSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AtrioColors.hostCardBorder, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Acción de Resolución', style: AtrioTypography.headingSmall.copyWith(color: Colors.white)),
                              const SizedBox(height: 16),
                              _ResolutionButton(
                                icon: Icons.replay,
                                label: 'Reembolso Completo al Huésped',
                                color: AtrioColors.error,
                                onTap: () => _showResolutionDialog(context, 'reembolso_completo'),
                              ),
                              const SizedBox(height: 10),
                              _ResolutionButton(
                                icon: Icons.payments,
                                label: 'Liberar Pago al Anfitrión',
                                color: AtrioColors.warning,
                                onTap: () => _showResolutionDialog(context, 'pago_liberado'),
                              ),
                              const SizedBox(height: 10),
                              _ResolutionButton(
                                icon: Icons.pie_chart,
                                label: 'Reembolso Parcial',
                                color: AtrioColors.neonLimeDark,
                                onTap: () => _showResolutionDialog(context, 'reembolso_parcial'),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Esta acción es final y activará pagos automáticos.',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w100, color: AtrioColors.hostTextTertiary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showResolutionDialog(BuildContext context, String type) {
    final labels = {
      'reembolso_completo': 'Reembolso Completo',
      'pago_liberado': 'Liberar Pago',
      'reembolso_parcial': 'Reembolso Parcial',
    };
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AtrioColors.hostSurface,
        title: Text('Confirmar ${labels[type]}', style: AtrioTypography.headingSmall.copyWith(color: Colors.white)),
        content: Text(
          '¿Estás seguro de aplicar esta resolución? Esta acción no se puede deshacer.',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w100, color: AtrioColors.hostTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AtrioColors.hostTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Resolución aplicada: ${labels[type]}')),
              );
            },
            child: Text('Confirmar', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ResolutionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ResolutionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            Icon(Icons.chevron_right, color: AtrioColors.hostTextTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
