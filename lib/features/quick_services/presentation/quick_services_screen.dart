import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/models/atrio_pricing_result.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/pricing_engine_service.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../shared/widgets/atrio_snackbar.dart';
import '../../../shared/widgets/edit_listing_sheet.dart';
import '../../../core/services/mercadopago_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/price_breakdown_card.dart';
import '../../../shared/widgets/verified_badge.dart';
import '../../checkout/presentation/card_payment_screen.dart';

/// Quick Services — guest-facing, light theme.
class QuickServicesScreen extends ConsumerStatefulWidget {
  const QuickServicesScreen({super.key});

  @override
  ConsumerState<QuickServicesScreen> createState() =>
      _QuickServicesScreenState();
}

class _QuickServicesScreenState extends ConsumerState<QuickServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';
  List<Map<String, dynamic>> _realServices = [];
  List<Map<String, dynamic>> _realRequests = [];
  bool _isLoading = true;
  String? _error;

  final _categories = const <(String, String, IconData)>[
    ('all', '', Icons.apps_rounded),
    ('moving', 'mudanza', Icons.local_shipping_rounded),
    ('cleaning', 'limpieza', Icons.cleaning_services_rounded),
    ('assembly', 'armado', Icons.handyman_rounded),
    ('events', 'eventos', Icons.celebration_rounded),
    ('gardening', 'jardinería', Icons.local_florist_rounded),
    ('repairs', 'reparaciones', Icons.build_rounded),
    ('painting', 'pintura', Icons.format_paint_rounded),
    ('plumbing', 'plomería', Icons.plumbing_rounded),
    ('electrical', 'electricidad', Icons.electrical_services_rounded),
    ('tech', 'tecnología', Icons.computer_rounded),
    ('pets', 'mascotas', Icons.pets_rounded),
    ('beauty', 'belleza', Icons.face_retouching_natural_rounded),
    ('classes', 'clases', Icons.school_rounded),
    ('cooking', 'cocina', Icons.restaurant_rounded),
  ];

  String _categoryLabel(AppLocalizations l, String value) {
    switch (value) {
      case 'all': return l.qsCatAll;
      case 'moving': return l.qsCatMoving;
      case 'cleaning': return l.qsCatCleaning;
      case 'assembly': return l.qsCatAssembly;
      case 'events': return l.qsCatEvents;
      case 'gardening': return l.qsCatGardening;
      case 'repairs': return l.qsCatRepairs;
      case 'painting': return l.qsCatPainting;
      case 'plumbing': return l.qsCatPlumbing;
      case 'electrical': return l.qsCatElectrical;
      case 'tech': return l.qsCatTech;
      case 'pets': return l.qsCatPets;
      case 'beauty': return l.qsCatBeauty;
      case 'classes': return l.qsCatClasses;
      case 'cooking': return l.qsCatCooking;
      default: return value;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _loadServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await DatabaseService.getPublishedListings(type: 'service', limit: 50);
      if (mounted) {
        setState(() {
          _realServices =
              data.where((s) => s['is_request'] != true).toList();
          _realRequests =
              data.where((s) => s['is_request'] == true).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        setState(() { _error = l.qsLoadError; _isLoading = false; });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    if (_selectedCategory == 'all') return _realServices;
    final cat = _categories.firstWhere((c) => c.$1 == _selectedCategory).$2;
    if (cat.isEmpty) return _realServices;
    return _realServices.where((s) {
      final category = (s['category'] as String? ?? '').toLowerCase();
      final tags = List<String>.from(s['tags'] ?? []);
      return category.contains(cat) || tags.any((t) => t.toLowerCase().contains(cat));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── EDITORIAL HEADER ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AtrioColors.guestSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AtrioColors.guestCardBorder),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 18, color: AtrioColors.guestTextPrimary),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/publish-service', extra: 'offer'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: AtrioColors.guestTextPrimary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            l.qsPublish,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.qsEyebrow,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AtrioColors.guestTextTertiary,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.qsTitle,
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.guestTextPrimary,
                      letterSpacing: -1.0,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.qsHeroSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AtrioColors.guestTextSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── TAB BAR ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AtrioColors.guestSurfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AtrioColors.neonLime,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.black,
                  unselectedLabelColor: AtrioColors.guestTextSecondary,
                  labelStyle: GoogleFonts.inter(
                      fontSize: 13.5, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                  unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 13.5, fontWeight: FontWeight.w600, letterSpacing: -0.2),
                  tabs: [Tab(text: l.qsTabAvailable), Tab(text: l.qsTabRequests)],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ─── CATEGORIES ───
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat.$1 == _selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat.$1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AtrioColors.guestTextPrimary
                            : AtrioColors.guestSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AtrioColors.guestTextPrimary
                              : AtrioColors.guestCardBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.$3,
                              size: 14,
                              color: isSelected ? AtrioColors.neonLime : AtrioColors.guestTextSecondary),
                          const SizedBox(width: 6),
                          Text(
                            _categoryLabel(l, cat.$1),
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? Colors.white : AtrioColors.guestTextPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // ─── CONTENT ───
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAvailableTab(l),
                  _buildRequestsTab(l),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTab(AppLocalizations l) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AtrioColors.neonLimeDark, strokeWidth: 2.5),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: AtrioColors.guestTextTertiary),
            const SizedBox(height: 12),
            Text(_error!, style: GoogleFonts.inter(color: AtrioColors.guestTextSecondary)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadServices,
              child: Text(
                l.btnRetry,
                style: GoogleFonts.inter(color: AtrioColors.guestTextPrimary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }
    final services = _filteredServices;
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AtrioColors.neonLime.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.handyman_rounded, size: 36, color: AtrioColors.neonLimeDark),
            ),
            const SizedBox(height: 16),
            Text(
              l.qsEmptyTitle,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AtrioColors.guestTextPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.qsEmptySubtitle,
              style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.guestTextTertiary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AtrioColors.guestTextPrimary,
      backgroundColor: AtrioColors.guestSurface,
      onRefresh: _loadServices,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
              child: Row(
                children: [
                  Text(
                    l.qsAvailableSection,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.guestTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l.qsResultsCount(services.length),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AtrioColors.guestTextTertiary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList.separated(
              itemCount: services.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ServiceCard(
                service: services[i],
                onTap: () => _showServiceDetail(services[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(AppLocalizations l) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AtrioColors.guestTextPrimary, strokeWidth: 2.5),
      );
    }
    final reqs = _realRequests;
    if (reqs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AtrioColors.guestSurfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_rounded,
                  size: 36, color: AtrioColors.guestTextSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              l.qsEmptyNoRequests,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AtrioColors.guestTextPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.qsEmptyPostFirst,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AtrioColors.guestTextTertiary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AtrioColors.guestTextPrimary,
      backgroundColor: AtrioColors.guestSurface,
      onRefresh: _loadServices,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
              child: Row(
                children: [
                  Text(
                    l.qsActiveRequests,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.guestTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l.qsResultsCount(reqs.length),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AtrioColors.guestTextTertiary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList.separated(
              itemCount: reqs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _RequestCard(
                request: reqs[i],
                onTap: () => _showServiceDetail(reqs[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SERVICE DETAIL SHEET
  // ─────────────────────────────────────────────────────────────
  void _showServiceDetail(Map<String, dynamic> service) {
    final l = AppLocalizations.of(context);
    final title = service['title'] ?? l.qsServiceDefault;
    final description = service['description'] ?? '';
    final price = (service['base_price'] as num?)?.toDouble() ?? 0;
    final priceUnit = service['price_unit'] ?? 'session';
    final rating = (service['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (service['review_count'] as num?)?.toInt() ?? 0;
    final hostId = service['host_id'] as String;
    final host = service['host'] as Map<String, dynamic>?;
    final hostName = host?['display_name'] ?? l.qsProviderDefault;
    final hostVerified = host?['is_verified'] == true;
    final hostPhoto = host?['photo_url'] as String?;
    final category = service['category'] ?? service['type'] ?? '';
    // If the service belongs to the signed-in user we surface
    // Edit/Delete affordances at the top of the sheet — guests never
    // see them.
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    final isOwner = currentUserId != null && currentUserId == hostId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: AtrioColors.guestBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              // Header row: drag handle centred, "···" menu top-right
              // when the signed-in user owns this service. Mirrors the
              // affordance pattern used on the host listings cards.
              SizedBox(
                height: 28,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AtrioColors.guestCardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    if (isOwner)
                      Positioned(
                        right: 0,
                        child: _ServiceMenuButton(
                          onTap: () => _showServiceOwnerOptions(
                            ctx,
                            service: service,
                            title: title.toString(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AtrioColors.guestSurfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.handyman_rounded,
                        color: AtrioColors.guestTextPrimary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: AtrioColors.guestTextPrimary,
                            letterSpacing: -0.6,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.toString().toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AtrioColors.guestTextTertiary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Price tag
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AtrioColors.guestTextPrimary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRECIO'.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white60,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          // All-inclusive price (base + 7% fee). The fee is
                          // shown separately only inside the breakdown sheet.
                          price.toCLPWithFee,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '/$priceUnit',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AtrioColors.guestTextSecondary,
                    height: 1.55,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Provider card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AtrioColors.guestSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AtrioColors.guestCardBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AtrioColors.neonLime.withValues(alpha: 0.2),
                      backgroundImage: hostPhoto != null
                          ? CachedNetworkImageProvider(hostPhoto)
                          : null,
                      child: hostPhoto == null
                          ? Text(
                              hostName.toString().substring(0, 1).toUpperCase(),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                color: AtrioColors.guestTextPrimary,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  hostName,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AtrioColors.guestTextPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hostVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, size: 16, color: verifiedBlue),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 13, color: AtrioColors.ratingGold),
                              const SizedBox(width: 3),
                              Text(
                                rating.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AtrioColors.guestTextPrimary,
                                ),
                              ),
                              Text(
                                l.qsDotReviewsCount(reviewCount),
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: AtrioColors.guestTextTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _openChatWith(hostId);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AtrioColors.guestSurfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded,
                            size: 18, color: AtrioColors.guestTextPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AtrioColors.neonLime,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l.qsHowItWorks,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.guestTextPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _StepItem(step: '1', title: l.qsStep1Title, subtitle: l.qsStep1Subtitle),
              _StepItem(step: '2', title: l.qsStep2Title, subtitle: l.qsStep2Subtitle),
              _StepItem(step: '3', title: l.qsStep3Title, subtitle: l.qsStep3Subtitle),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showHireConfirmation(service);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AtrioColors.guestTextPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          l.qsHireFor(price.toCLPWithFee, priceUnit),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 18, color: AtrioColors.neonLime),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 13, color: Color(0xFF009EE3)),
                    const SizedBox(width: 6),
                    Text(
                      l.qsSecurePayment,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AtrioColors.guestTextTertiary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // OWNER OPTIONS SHEET (Edit / Delete)
  // Mirrors host_listings: a small menu sheet opened from the
  // "···" button on the service detail, instead of two loud pills.
  // ─────────────────────────────────────────────────────────────
  void _showServiceOwnerOptions(
    BuildContext detailCtx, {
    required Map<String, dynamic> service,
    required String title,
  }) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: detailCtx,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AtrioColors.guestBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AtrioColors.guestCardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 22),
                _ServiceOptionTile(
                  icon: Icons.edit_outlined,
                  label: l.qsEditService,
                  color: AtrioColors.guestTextPrimary,
                  onTap: () async {
                    Navigator.pop(ctx); // close options sheet
                    Navigator.pop(detailCtx); // close detail sheet
                    final saved = await showEditListingSheet(
                      context,
                      listing: service,
                      // Services don't use a separate cleaning fee.
                      showCleaningFee: false,
                    );
                    if (saved == true) {
                      await _loadServices();
                      if (mounted) {
                        AtrioSnackbar.success(
                            context, l.qsEditServiceSavedSnack);
                      }
                    }
                  },
                ),
                _ServiceOptionTile(
                  icon: Icons.delete_outline_rounded,
                  label: l.qsDeleteService,
                  color: AtrioColors.error,
                  onTap: () async {
                    Navigator.pop(ctx); // close options sheet
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        backgroundColor: AtrioColors.guestSurface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: Text(
                          l.qsDeleteService,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            color: AtrioColors.guestTextPrimary,
                          ),
                        ),
                        content: Text(
                          l.qsDeleteServiceConfirm(title),
                          style: GoogleFonts.inter(
                            color: AtrioColors.guestTextSecondary,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogCtx, false),
                            child: Text(l.btnCancel,
                                style: GoogleFonts.inter(
                                  color: AtrioColors.guestTextSecondary,
                                )),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogCtx, true),
                            child: Text(l.btnDelete,
                                style: GoogleFonts.inter(
                                  color: AtrioColors.error,
                                  fontWeight: FontWeight.w800,
                                )),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await DatabaseService.deleteListing(
                            service['id'] as String);
                        if (!mounted) return;
                        if (detailCtx.mounted) Navigator.pop(detailCtx);
                        await _loadServices();
                        if (mounted) {
                          AtrioSnackbar.info(
                              context, l.qsDeleteServiceSnack);
                        }
                      } catch (_) {
                        if (mounted) {
                          AtrioSnackbar.danger(
                              context, l.hostListingsEditError);
                        }
                      }
                    }
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HIRE CONFIRMATION + MERCADO PAGO
  // ─────────────────────────────────────────────────────────────
  void _showHireConfirmation(Map<String, dynamic> service) {
    final l = AppLocalizations.of(context);
    final title = service['title'] ?? l.qsServiceDefault;
    final price = (service['base_price'] as num?)?.toInt() ?? 0;
    final priceUnit = service['price_unit'] ?? 'session';
    final hostId = service['host_id'] as String;
    final host = service['host'] as Map<String, dynamic>?;
    final hostName = host?['display_name'] ?? l.qsProviderDefault;
    final listingId = service['id'] as String;
    // Server-side single source of truth. Fire ONCE before showing the
    // sheet — captured in the closure so rebuilds don't re-trigger the
    // RPC, but the same future is awaited by FutureBuilder + the pay
    // button (so we never act on stale numbers).
    final pricingFuture = PricingEngineService.calculateAtrioPricing(
      hostId: hostId,
      basePrice: price,
      units: 1,
    );
    bool hiring = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          decoration: const BoxDecoration(
            color: AtrioColors.guestBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AtrioColors.guestCardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l.qsConfirmHire,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.guestTextPrimary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.qsHireMessage(hostName, title, price.toCLPWithFee, priceUnit),
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: AtrioColors.guestTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              // Server-driven pricing: never compute totals here.
              FutureBuilder<AtrioPricingResult>(
                future: pricingFuture,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: AtrioColors.guestSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AtrioColors.guestCardBorder),
                      ),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AtrioColors.guestTextSecondary,
                        ),
                      ),
                    );
                  }
                  if (snap.hasError || snap.data == null) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AtrioColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        l.hostListingsEditError,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AtrioColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  final p = snap.data!;
                  final feeLabel = p.servicioAtrioMinimoAplicado
                      ? l.qsAtrioFeeMinApplied
                      : (p.initialBenefitApplied
                          ? l.qsAtrioFeeInitial
                          : l.qsAtrioFee);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PriceBreakdownCard(
                        totalLabel: l.qsTotal,
                        total: p.precioTotal.toDouble(),
                        items: [
                          PriceBreakdownItem(
                              l.qsServicePrice, p.precioBase.toDouble()),
                          PriceBreakdownItem(
                              '$feeLabel (${p.porcentajeLabel})',
                              p.servicioAtrioAmount.toDouble()),
                        ],
                      ),
                      if (p.initialBenefitApplied) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AtrioColors.neonLime
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l.qsAtrioBenefitNote,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AtrioColors.guestTextPrimary,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              // MP card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AtrioColors.guestSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF009EE3).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF009EE3).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          size: 20, color: Color(0xFF009EE3)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mercado Pago',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AtrioColors.guestTextPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            l.checkoutMpMethods,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AtrioColors.guestTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (MercadoPagoService.isSandbox)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'TEST',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: hiring
                      ? null
                      : () async {
                          HapticFeedback.lightImpact();
                          setSheetState(() => hiring = true);
                          try {
                            // Always read the canonical pricing from the
                            // same Future the UI rendered, so we can never
                            // pay an amount the user didn't see.
                            final pricing = await pricingFuture;
                            if (!ctx.mounted) return;
                            await _hireAndPay(
                              hostId: hostId,
                              listingId: listingId,
                              title: title,
                              pricing: pricing,
                              sheetCtx: ctx,
                            );
                          } catch (e) {
                            if (mounted) ErrorHandler.showError(context, e);
                          } finally {
                            if (ctx.mounted) setSheetState(() => hiring = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AtrioColors.guestTextPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: hiring
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : FutureBuilder<AtrioPricingResult>(
                          future: pricingFuture,
                          builder: (ctx, snap) {
                            // Show "—" while the price is loading so the
                            // button is never empty mid-render.
                            final amount = snap.data?.precioTotal
                                    .toDouble()
                                    .toCLP ??
                                '—';
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_outline_rounded,
                                    size: 16, color: AtrioColors.neonLime),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    l.qsPayWithMp(amount),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: hiring ? null : () => Navigator.pop(ctx),
                  child: Text(
                    l.qsGoBack,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AtrioColors.guestTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Creates booking, opens Mercado Pago, and on approval kicks off chat.
  Future<void> _hireAndPay({
    required String hostId,
    required String listingId,
    required String title,
    required AtrioPricingResult pricing,
    required BuildContext sheetCtx,
  }) async {
    final l = AppLocalizations.of(context);
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    // Convenience locals — the canonical numbers live on `pricing`.
    final price = pricing.precioBase.toDouble();
    final fee = pricing.servicioAtrioAmount.toDouble();
    final total = pricing.precioTotal.toDouble();

    // Step 1 — Create the pending booking. Persist BOTH the legacy
    // (base_total / service_fee / total) columns and the new Servicio
    // Atrio snapshot, so anything that still reads the old shape keeps
    // working while we migrate consumers in later phases.
    final now = DateTime.now();
    final String bookingId;
    try {
      final booking = await DatabaseService.createBooking({
        'guest_id': currentUser.id,
        'host_id': hostId,
        'listing_id': listingId,
        'check_in': now.toIso8601String(),
        'check_out': now.add(const Duration(hours: 2)).toIso8601String(),
        'guests_count': 1,
        // Legacy columns (kept for backward compat during the migration)
        'base_total': price,
        'cleaning_fee': 0,
        'service_fee': fee,
        'total': total,
        // Servicio Atrio snapshot (new canonical columns)
        ...pricing.toBookingColumns(),
        'status': 'pending',
        'payment_status': 'pending',
        'rental_mode': 'hours',
        'special_requests': l.qsQuickServicePrefix(title),
      });
      bookingId = booking['id'] as String;
    } catch (e) {
      if (mounted) _snack('No se pudo crear la reserva: $e', isError: true);
      return;
    }

    // Step 2 — If MP is configured, run the real payment flow.
    if (!MercadoPagoService.isConfigured) {
      _snack(l.qsPaymentNotConfigured, isError: true);
      return;
    }

    try {
      if (!mounted) return;

      // Close the sheet first so the card form opens cleanly.
      if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      // Push the in-app card form. It calls the Edge Function for
      // server-side tokenization + payment.
      final paymentResult = await Navigator.of(context).push<PaymentResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => CardPaymentScreen(
            bookingId: bookingId,
            total: total,
            listingTitle: title,
          ),
        ),
      );

      if (!mounted) return;

      if (paymentResult == null) {
        _snack(l.qsPaymentPending, isError: false);
        return;
      }

      if (paymentResult.isApproved) {
        // Edge Function already updated the booking and trigger created
        // transactions + bumped host_profiles. Don't write from client —
        // RLS denies guest writes to those tables.
        final convo = await DatabaseService.getOrCreateConversation(
          userId1: currentUser.id,
          userId2: hostId,
        );
        await DatabaseService.sendMessage(
          conversationId: convo['id'],
          senderId: currentUser.id,
          text: l.qsChatHi(title, total.toCLP),
        );

        if (!mounted) return;
        _snack(l.qsPaymentApproved, isError: false);
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) context.push('/chat/${convo['id']}');
      } else if (paymentResult.isPending) {
        if (mounted) _snack(l.qsPaymentPending, isError: false);
      } else {
        if (mounted) _snack(l.qsPaymentRejected, isError: true);
      }
    } on MpException catch (e) {
      if (mounted) _snack(l.qsPaymentError(e.message), isError: true);
    }
  }

  Future<void> _openChatWith(String hostId) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;
    try {
      final convo = await DatabaseService.getOrCreateConversation(
        userId1: currentUser.id,
        userId2: hostId,
      );
      if (mounted) context.push('/chat/${convo['id']}');
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            size: 18,
            color: isError ? Colors.white : Colors.black,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: isError ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? AtrioColors.error : AtrioColors.neonLime,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ─────────────────────────────────────────────────────────────
// SERVICE CARD (light)
// ─────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onTap;
  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = service['title'] ?? l.qsServiceDefault;
    final price = (service['base_price'] as num?)?.toDouble() ?? 0;
    final priceUnit = service['price_unit'] ?? 'session';
    final rating = (service['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (service['review_count'] as num?)?.toInt() ?? 0;
    final host = service['host'] as Map<String, dynamic>?;
    final hostName = host?['display_name'] ?? l.qsProviderDefault;
    final hostVerified = host?['is_verified'] == true;
    final hostPhoto = host?['photo_url'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AtrioColors.guestCardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AtrioColors.guestSurfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.handyman_rounded,
                  color: AtrioColors.guestTextPrimary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AtrioColors.guestTextPrimary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hostVerified) ...[
                        const SizedBox(width: 5),
                        const Icon(Icons.verified, size: 14, color: verifiedBlue),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: AtrioColors.guestSurfaceVariant,
                        backgroundImage: hostPhoto != null
                            ? CachedNetworkImageProvider(hostPhoto)
                            : null,
                        child: hostPhoto == null
                            ? Text(
                                hostName.toString().substring(0, 1).toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AtrioColors.guestTextPrimary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l.qsProviderReviewsLine(hostName, reviewCount),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AtrioColors.guestTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: AtrioColors.ratingGold),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AtrioColors.guestTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  // All-inclusive price (base + 7% fee).
                  price.toCLPWithFee,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -0.6,
                  ),
                ),
                Text(
                  '/$priceUnit',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AtrioColors.guestTextTertiary,
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

// ─────────────────────────────────────────────────────────────
// STEP ITEM
// ─────────────────────────────────────────────────────────────
class _StepItem extends StatelessWidget {
  final String step, title, subtitle;
  const _StepItem({required this.step, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AtrioColors.guestTextPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AtrioColors.neonLime,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AtrioColors.guestTextSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Request card (urgency badge + budget) ───────────────────
class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onTap;
  const _RequestCard({required this.request, required this.onTap});

  ({String label, Color bg, Color fg}) _urgencyStyle(String? key) {
    switch (key) {
      case 'today':
        return (
          label: 'Hoy',
          bg: AtrioColors.error.withValues(alpha: 0.15),
          fg: AtrioColors.error,
        );
      case 'tomorrow':
        return (
          label: 'Mañana',
          bg: AtrioColors.vibrantOrange.withValues(alpha: 0.15),
          fg: AtrioColors.vibrantOrange,
        );
      case 'week':
        return (
          label: 'Esta semana',
          bg: AtrioColors.guestSurfaceVariant,
          fg: AtrioColors.guestTextSecondary,
        );
      case 'flexible':
      default:
        return (
          label: 'Flexible',
          bg: AtrioColors.neonLime.withValues(alpha: 0.22),
          fg: AtrioColors.neonLimeDark,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = request['title'] as String? ?? l.qsServiceDefault;
    final budget = (request['base_price'] as num?)?.toDouble() ?? 0;
    final host = request['host'] as Map<String, dynamic>?;
    final hostName = host?['display_name'] as String? ?? l.qsProviderDefault;
    final hostPhoto = host?['photo_url'] as String?;
    final description = request['description'] as String? ?? '';
    final urgency = _urgencyStyle(request['urgency'] as String?);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AtrioColors.guestCardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgency.bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 11, color: urgency.fg),
                      const SizedBox(width: 3),
                      Text(
                        urgency.label.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: urgency.fg,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  budget > 0 ? '\$${budget.toStringAsFixed(0)}' : '—',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  ' presupuesto',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AtrioColors.guestTextTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AtrioColors.guestTextPrimary,
                letterSpacing: -0.3,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AtrioColors.guestTextSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: AtrioColors.guestSurfaceVariant,
                  backgroundImage: hostPhoto != null
                      ? CachedNetworkImageProvider(hostPhoto)
                      : null,
                  child: hostPhoto == null
                      ? Text(
                          hostName.isNotEmpty
                              ? hostName.substring(0, 1).toUpperCase()
                              : '?',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AtrioColors.guestTextPrimary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    hostName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AtrioColors.guestTextSecondary,
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

/// Small "···" affordance shown next to the drag handle of the Quick
/// Services detail sheet when the signed-in user owns the service.
/// Tapping it surfaces a sheet with Editar / Eliminar — same pattern
/// as host_listings cards.
class _ServiceMenuButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ServiceMenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AtrioColors.guestSurface,
            shape: BoxShape.circle,
            border: Border.all(color: AtrioColors.guestCardBorder),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.more_horiz_rounded,
            size: 16,
            color: AtrioColors.guestTextPrimary,
          ),
        ),
      ),
    );
  }
}

/// Bordered option row used inside the owner options sheet (Editar /
/// Eliminar). Matches the _OptionTile style from host_listings but
/// uses the guest (light) palette for the Quick Services context.
class _ServiceOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ServiceOptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AtrioColors.guestCardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AtrioColors.guestTextTertiary),
          ],
        ),
      ),
    );
  }
}
