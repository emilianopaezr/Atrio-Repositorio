import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/models/dispute_model.dart';
import '../../../core/providers/disputes_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/error_handler.dart';
import '../../../l10n/app_localizations.dart';

class DisputeDetailScreen extends ConsumerStatefulWidget {
  final String disputeId;
  const DisputeDetailScreen({super.key, required this.disputeId});

  @override
  ConsumerState<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends ConsumerState<DisputeDetailScreen> {
  int _selectedTab = 0;
  bool _defenseExpanded = false;
  bool _isUploading = false;
  bool _isSubmittingDefense = false;
  final _defenseController = TextEditingController();

  @override
  void dispose() {
    _defenseController.dispose();
    super.dispose();
  }

  String _relativeTime(AppLocalizations l, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l.disputeTimeNow;
    if (diff.inMinutes < 60) return l.disputeTimeMin(diff.inMinutes);
    if (diff.inHours < 24) return l.disputeTimeHour(diff.inHours);
    if (diff.inDays < 7) return l.disputeTimeDay(diff.inDays);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final disputeAsync = ref.watch(disputeDetailProvider(widget.disputeId));

    return Scaffold(
      backgroundColor: AtrioColors.hostBackground,
      body: disputeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AtrioColors.neonLimeDark)),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AtrioColors.hostTextTertiary),
              const SizedBox(height: 12),
              Text(l.disputeLoadError, style: GoogleFonts.inter(color: AtrioColors.hostTextSecondary)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => ref.invalidate(disputeDetailProvider(widget.disputeId)),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l.btnRetry),
                style: TextButton.styleFrom(foregroundColor: AtrioColors.neonLimeDark),
              ),
            ],
          ),
        ),
        data: (dispute) {
          if (dispute == null) {
            return Center(child: Text(l.disputeNotFound, style: AtrioTypography.bodyLarge.copyWith(color: Colors.white)));
          }

          final guestName = dispute.guestData?['display_name'] as String? ?? l.disputeGuest;
          final hostName = dispute.hostData?['display_name'] as String? ?? l.disputeHost;
          final currentUserId = SupabaseConfig.auth.currentUser?.id;
          final isHost = currentUserId == dispute.hostId;

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
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AtrioColors.hostSurfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l.disputeHeaderTitle(dispute.id.length > 8 ? dispute.id.substring(0, 8) : dispute.id),
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1),
                      ),
                      const Spacer(),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Scrollable content
                Expanded(
                  child: RefreshIndicator(
                    color: AtrioColors.neonLimeDark,
                    onRefresh: () async => ref.invalidate(disputeDetailProvider(widget.disputeId)),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                                        gradient: const LinearGradient(
                                          colors: [AtrioColors.neonLimeDark, AtrioColors.neonLime],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        l.disputeAmountAtStake(dispute.amount.toCLP),
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_relativeTime(l, dispute.createdAt)} • ${l.disputePriorityLabel(_priorityLabel(l, dispute.priority))}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Timeline ──
                          _buildTimeline(l, dispute.status, dispute.createdAt, dispute.updatedAt),
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
                                Expanded(child: _profileColumn(guestName, l.disputeGuest, dispute.guestData?['photo_url'] as String?, AtrioColors.neonLimeDark)),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: AtrioColors.hostSurfaceVariant, shape: BoxShape.circle),
                                  child: const Icon(Icons.compare_arrows, color: AtrioColors.hostTextSecondary, size: 16),
                                ),
                                Expanded(child: _profileColumn(hostName, l.disputeHost, dispute.hostData?['photo_url'] as String?, AtrioColors.warning)),
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
                                _tabButton(l.disputeTabReport, 0),
                                _tabButton(l.disputeTabDefense, 1),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Evidence section
                          if (_selectedTab == 0) ...[
                            _buildGuestEvidenceSection(dispute),
                          ],

                          // Host defense
                          if (_selectedTab == 1) ...[
                            _buildHostDefenseSection(dispute, isHost),
                          ],

                          const SizedBox(height: 20),

                          // Resolution Actions (only for open disputes)
                          if (dispute.status == 'abierta' || dispute.status == 'en_revision')
                            _buildResolutionSection(),
                        ],
                      ),
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

  // ── Timeline widget ──
  Widget _buildTimeline(AppLocalizations l, String currentStatus, DateTime createdAt, DateTime updatedAt) {
    final steps = [
      _TimelineStep(l.disputeStepOpen, 'abierta', Icons.flag_outlined),
      _TimelineStep(l.disputeStepReview, 'en_revision', Icons.search),
      _TimelineStep(l.disputeStepResolved, 'resuelta', Icons.check_circle_outline),
      _TimelineStep(l.disputeStepClosed, 'cerrada', Icons.lock_outline),
    ];
    final currentIdx = steps.indexWhere((s) => s.statusKey == currentStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AtrioColors.hostSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtrioColors.hostCardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.disputeProgress, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 14),
          Row(
            children: List.generate(steps.length, (i) {
              final isActive = i <= currentIdx;
              final isCurrent = i == currentIdx;
              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: isActive ? AtrioColors.neonLimeDark : AtrioColors.hostSurfaceVariant,
                            shape: BoxShape.circle,
                            border: isCurrent ? Border.all(color: AtrioColors.neonLime, width: 2) : null,
                          ),
                          child: Icon(steps[i].icon, size: 16, color: isActive ? Colors.white : AtrioColors.hostTextTertiary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          steps[i].label,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? AtrioColors.neonLime : AtrioColors.hostTextTertiary,
                          ),
                        ),
                      ],
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          color: i < currentIdx ? AtrioColors.neonLimeDark : AtrioColors.hostSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            l.disputeTimestamps(
              '${createdAt.day}/${createdAt.month}/${createdAt.year}',
              _relativeTime(l, updatedAt),
            ),
            style: GoogleFonts.inter(fontSize: 11, color: AtrioColors.hostTextTertiary),
          ),
        ],
      ),
    );
  }

  // ── Guest evidence section ──
  Widget _buildGuestEvidenceSection(DisputeModel dispute) {
    final l = AppLocalizations.of(context);
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    final isGuest = currentUserId == dispute.guestId;

    return Container(
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
              Text(l.disputeEvidenceTitle, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AtrioColors.warning, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          if (dispute.guestReport.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AtrioColors.hostSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                dispute.guestReport,
                style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextSecondary, fontStyle: FontStyle.italic, height: 1.5),
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
                itemBuilder: (context, index) => _evidenceImage(dispute.guestEvidence[index]),
              ),
            ),
          ],
          if (isGuest && (dispute.status == 'abierta' || dispute.status == 'en_revision')) ...[
            const SizedBox(height: 12),
            _uploadButton(dispute.id, isHost: false),
          ],
        ],
      ),
    );
  }

  // ── Host defense section ──
  Widget _buildHostDefenseSection(DisputeModel dispute, bool isHost) {
    final l = AppLocalizations.of(context);
    if (dispute.hostDefense != null) {
      return Container(
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
                  const Icon(Icons.circle, color: AtrioColors.neonLimeDark, size: 14),
                  const SizedBox(width: 8),
                  Text(l.disputeHostDefenseTitle, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AtrioColors.neonLime, letterSpacing: 0.5)),
                  const Spacer(),
                  Icon(_defenseExpanded ? Icons.expand_less : Icons.expand_more, color: AtrioColors.hostTextTertiary, size: 20),
                ],
              ),
            ),
            if (_defenseExpanded) ...[
              const SizedBox(height: 12),
              Text(dispute.hostDefense!, style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextSecondary, height: 1.5)),
              if (dispute.hostEvidence.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: dispute.hostEvidence.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) => _evidenceImage(dispute.hostEvidence[index]),
                  ),
                ),
              ],
              if (isHost && (dispute.status == 'abierta' || dispute.status == 'en_revision')) ...[
                const SizedBox(height: 12),
                _uploadButton(dispute.id, isHost: true),
              ],
            ],
          ],
        ),
      );
    }

    // No defense yet
    if (isHost && (dispute.status == 'abierta' || dispute.status == 'en_revision')) {
      return _buildDefenseForm(dispute.id);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AtrioColors.hostSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        l.disputeNoDefenseYet,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextTertiary),
      ),
    );
  }

  // ── Defense form ──
  Widget _buildDefenseForm(String disputeId) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AtrioColors.hostSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtrioColors.hostCardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.disputeYourDefense, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Text(l.disputeExplainFacts, style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextTertiary)),
          const SizedBox(height: 12),
          TextField(
            controller: _defenseController,
            maxLines: 5,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
            decoration: InputDecoration(
              hintText: l.disputeDefenseHint,
              hintStyle: GoogleFonts.inter(fontSize: 14, color: AtrioColors.hostTextTertiary),
              filled: true,
              fillColor: AtrioColors.hostSurfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmittingDefense ? null : () => _submitDefense(disputeId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AtrioColors.neonLime,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: _isSubmittingDefense
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(l.disputeSendDefense, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitDefense(String disputeId) async {
    final text = _defenseController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSubmittingDefense = true);
    try {
      await DatabaseService.submitHostDefense(disputeId, text);
      ref.invalidate(disputeDetailProvider(widget.disputeId));
      if (mounted) {
        final l = AppLocalizations.of(context);
        ErrorHandler.showSuccess(context, l.disputeDefenseSent);
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isSubmittingDefense = false);
    }
  }

  // ── Evidence upload ──
  Widget _uploadButton(String disputeId, {required bool isHost}) {
    final l = AppLocalizations.of(context);
    return OutlinedButton.icon(
      onPressed: _isUploading ? null : () => _pickAndUploadEvidence(disputeId, isHost: isHost),
      icon: _isUploading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AtrioColors.neonLime))
          : const Icon(Icons.add_photo_alternate_outlined, size: 18),
      label: Text(_isUploading ? l.disputeUploading : l.disputeAddEvidence, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AtrioColors.neonLime,
        side: BorderSide(color: AtrioColors.neonLime.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Future<void> _pickAndUploadEvidence(String disputeId, {required bool isHost}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final userId = SupabaseConfig.auth.currentUser?.id ?? 'anon';
      final url = await StorageService.uploadListingImage(
        hostId: userId,
        listingId: 'disputes/$disputeId',
        fileBytes: bytes,
        fileName: 'evidence_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await DatabaseService.addDisputeEvidence(disputeId, url, isHost: isHost);
      ref.invalidate(disputeDetailProvider(widget.disputeId));
      if (mounted) {
        final l = AppLocalizations.of(context);
        ErrorHandler.showSuccess(context, l.disputeEvidenceAdded);
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Resolution section ──
  Widget _buildResolutionSection() {
    final l = AppLocalizations.of(context);
    return Container(
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
          Text(l.disputeResolutionTitle, style: AtrioTypography.headingSmall.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          _ResolutionButton(
            icon: Icons.replay, label: l.disputeResolutionFullRefund,
            color: AtrioColors.error,
            onTap: () => _showResolutionDialog(context, 'reembolso_completo'),
          ),
          const SizedBox(height: 10),
          _ResolutionButton(
            icon: Icons.payments, label: l.disputeResolutionReleasePayment,
            color: AtrioColors.warning,
            onTap: () => _showResolutionDialog(context, 'pago_liberado'),
          ),
          const SizedBox(height: 10),
          _ResolutionButton(
            icon: Icons.pie_chart, label: l.disputeResolutionPartial,
            color: AtrioColors.neonLimeDark,
            onTap: () => _showResolutionDialog(context, 'reembolso_parcial'),
          ),
          const SizedBox(height: 14),
          Text(
            l.disputeResolutionFinal,
            style: GoogleFonts.inter(fontSize: 11, color: AtrioColors.hostTextTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showResolutionDialog(BuildContext context, String type) {
    final l = AppLocalizations.of(context);
    final labels = {
      'reembolso_completo': l.disputeResolutionLabelFullRefund,
      'pago_liberado': l.disputeResolutionLabelRelease,
      'reembolso_parcial': l.disputeResolutionLabelPartial,
    };
    final actionLabel = labels[type] ?? type;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AtrioColors.hostSurface,
        title: Text(l.disputeConfirmResolution(actionLabel), style: AtrioTypography.headingSmall.copyWith(color: Colors.white)),
        content: Text(
          l.disputeResolutionConfirmDesc,
          style: GoogleFonts.inter(fontSize: 14, color: AtrioColors.hostTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.btnCancel, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AtrioColors.hostTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.disputeResolutionApplied(actionLabel))),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AtrioColors.neonLimeDark,
              foregroundColor: Colors.white,
            ),
            child: Text(l.btnConfirm, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Helper widgets ──

  Widget _tabButton(String label, int idx) {
    final selected = _selectedTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AtrioColors.neonLimeDark : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AtrioColors.hostTextSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileColumn(String name, String role, String? photoUrl, Color accentColor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: accentColor.withValues(alpha: 0.3),
          backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
          child: photoUrl == null ? Text(name.isNotEmpty ? name[0] : '?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)) : null,
        ),
        const SizedBox(height: 6),
        Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(role, style: GoogleFonts.inter(fontSize: 10, color: AtrioColors.hostTextSecondary)),
      ],
    );
  }

  Widget _evidenceImage(String url) {
    return GestureDetector(
      onTap: () => _showFullImage(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 140, height: 120, fit: BoxFit.cover,
          placeholder: (_, _) => Container(width: 140, height: 120, color: AtrioColors.hostSurfaceVariant),
          errorWidget: (_, _, _) => Container(
            width: 140, height: 120, color: AtrioColors.hostSurfaceVariant,
            child: const Icon(Icons.broken_image, color: AtrioColors.hostTextTertiary),
          ),
        ),
      ),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  String _priorityLabel(AppLocalizations l, String p) {
    switch (p) {
      case 'alta': return l.disputesPriorityHigh;
      case 'media': return l.disputesPriorityMedium;
      case 'baja': return l.disputesPriorityLow;
      default: return p.capitalize;
    }
  }
}

class _TimelineStep {
  final String label;
  final String statusKey;
  final IconData icon;
  const _TimelineStep(this.label, this.statusKey, this.icon);
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
            Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
            const Icon(Icons.chevron_right, color: AtrioColors.hostTextTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
