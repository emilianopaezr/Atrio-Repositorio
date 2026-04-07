import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';

/// Quick Services - casual gig marketplace
/// Flow:
///   1. Browse services (tab "Disponibles") or requests (tab "Solicitudes")
///   2. Tap a service → detail with "Contratar" button
///   3. Tap a request → detail with "Hacer oferta" button
///   4. Once accepted → chat + milestones tracker
class QuickServicesScreen extends ConsumerStatefulWidget {
  const QuickServicesScreen({super.key});

  @override
  ConsumerState<QuickServicesScreen> createState() =>
      _QuickServicesScreenState();
}

class _QuickServicesScreenState extends ConsumerState<QuickServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'Todos';
  List<Map<String, dynamic>> _realServices = [];
  bool _isLoading = true;
  String? _error;

  final _categories = [
    'Todos',
    'Mudanza',
    'Limpieza',
    'Armado',
    'Eventos',
    'Jardinería',
    'Reparaciones',
    'Pintura',
    'Plomería',
    'Electricidad',
    'Tecnología',
    'Mascotas',
    'Belleza',
    'Clases',
    'Cocina',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      if (mounted) setState(() { _realServices = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Error al cargar servicios'; _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    if (_selectedCategory == 'Todos') return _realServices;
    final cat = _selectedCategory.toLowerCase();
    return _realServices.where((s) {
      final category = (s['category'] as String? ?? '').toLowerCase();
      final tags = List<String>.from(s['tags'] ?? []);
      return category.contains(cat) || tags.any((t) => t.toLowerCase().contains(cat));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtrioColors.hostBackground,
      appBar: AppBar(
        backgroundColor: AtrioColors.hostBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AtrioColors.hostTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Servicios Rapidos', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AtrioColors.hostTextPrimary)),
        actions: [
          GestureDetector(
            onTap: () => context.push('/publish-service', extra: 'offer'),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AtrioColors.neonLime.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add, size: 16, color: AtrioColors.neonLime),
                const SizedBox(width: 4),
                Text('Publicar', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AtrioColors.neonLime)),
              ]),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AtrioColors.hostSurface, borderRadius: BorderRadius.circular(14)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: AtrioColors.neonLime, borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.black,
              unselectedLabelColor: AtrioColors.hostTextSecondary,
              labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: const [Tab(text: 'Disponibles'), Tab(text: 'Solicitudes')],
            ),
          ),
          // Categories
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AtrioColors.neonLime : AtrioColors.hostSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AtrioColors.neonLimeDark : AtrioColors.hostCardBorder),
                    ),
                    child: Text(cat, style: GoogleFonts.inter(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.black : AtrioColors.hostTextSecondary)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AtrioColors.neonLime))
                  : _error != null
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!, style: GoogleFonts.inter(color: AtrioColors.hostTextSecondary)),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _loadServices, child: Text('Reintentar', style: GoogleFonts.inter(color: AtrioColors.neonLime))),
                      ]))
                    : _filteredServices.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.handyman_rounded, size: 48, color: AtrioColors.hostTextTertiary),
                          const SizedBox(height: 12),
                          Text('No hay servicios disponibles', style: GoogleFonts.inter(fontSize: 15, color: AtrioColors.hostTextSecondary)),
                          const SizedBox(height: 4),
                          Text('Publica el tuyo con el botón +', style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextTertiary)),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredServices.length,
                          itemBuilder: (context, index) {
                            final s = _filteredServices[index];
                            return _RealServiceCard(service: s, onTap: () => _showRealServiceDetail(s));
                          },
                        ),
                // Solicitudes tab - coming soon
                Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.campaign_rounded, size: 48, color: AtrioColors.hostTextTertiary),
                  const SizedBox(height: 12),
                  Text('Solicitudes próximamente', style: GoogleFonts.inter(fontSize: 15, color: AtrioColors.hostTextSecondary)),
                  const SizedBox(height: 4),
                  Text('Pronto podrás publicar lo que necesitas', style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextTertiary)),
                ])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRealServiceDetail(Map<String, dynamic> service) {
    final title = service['title'] ?? 'Servicio';
    final description = service['description'] ?? '';
    final price = (service['base_price'] as num?)?.toDouble() ?? 0;
    final priceUnit = service['price_unit'] ?? 'session';
    final rating = (service['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (service['review_count'] as num?)?.toInt() ?? 0;
    final hostId = service['host_id'] as String;
    final host = service['host'] as Map<String, dynamic>?;
    final hostName = host?['display_name'] ?? 'Proveedor';
    final hostVerified = host?['is_verified'] == true;
    final category = service['category'] ?? service['type'] ?? '';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(color: AtrioColors.hostBackground, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(
            controller: scrollCtrl, padding: const EdgeInsets.all(24),
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AtrioColors.hostCardBorder, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(color: AtrioColors.neonLime.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.handyman_rounded, color: AtrioColors.neonLime, size: 28)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AtrioColors.hostTextPrimary)),
                  const SizedBox(height: 4),
                  Text(category, style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextTertiary)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(price.toCLP, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AtrioColors.neonLime)),
                  Text('/$priceUnit', style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextTertiary)),
                ]),
              ]),
              const SizedBox(height: 20),
              if (description.isNotEmpty)
                Text(description, style: GoogleFonts.inter(fontSize: 14, color: AtrioColors.hostTextSecondary, height: 1.5)),
              const SizedBox(height: 24),
              // Provider card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AtrioColors.hostSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AtrioColors.hostCardBorder)),
                child: Row(children: [
                  CircleAvatar(radius: 22, backgroundColor: AtrioColors.neonLime.withValues(alpha: 0.15), child: Text(hostName[0], style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AtrioColors.neonLime, fontSize: 18))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(hostName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AtrioColors.hostTextPrimary)),
                      if (hostVerified) ...[const SizedBox(width: 6), Icon(Icons.verified, size: 16, color: AtrioColors.neonLimeDark)],
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 14, color: AtrioColors.ratingGold), const SizedBox(width: 3),
                      Text(rating.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AtrioColors.hostTextPrimary)),
                      Text(' · $reviewCount reseñas', style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextTertiary)),
                    ]),
                  ])),
                  GestureDetector(
                    onTap: () { Navigator.pop(ctx); _openChatWith(hostId); },
                    child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AtrioColors.neonLime.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.chat_outlined, size: 20, color: AtrioColors.neonLime)),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Text('Como funciona', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AtrioColors.hostTextPrimary)),
              const SizedBox(height: 14),
              _StepItem(step: '1', title: 'Contratas el servicio', subtitle: 'Acuerdan fecha, hora y detalles por chat'),
              _StepItem(step: '2', title: 'Se realiza el trabajo', subtitle: 'El proveedor marca avances en tiempo real'),
              _StepItem(step: '3', title: 'Confirmas y pagas', subtitle: 'Solo pagas cuando estas satisfecho'),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
                onPressed: () { Navigator.pop(ctx); _showRealHireConfirmation(service); },
                style: ElevatedButton.styleFrom(backgroundColor: AtrioColors.neonLime, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: Text('Contratar por ${price.toCLP}/$priceUnit', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
              )),
              const SizedBox(height: 12),
              Center(child: Text('Pago seguro · Garantía Atrio', style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextTertiary))),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showRealHireConfirmation(Map<String, dynamic> service) {
    final title = service['title'] ?? 'Servicio';
    final price = (service['base_price'] as num?)?.toDouble() ?? 0;
    final priceUnit = service['price_unit'] ?? 'session';
    final hostId = service['host_id'] as String;
    final host = service['host'] as Map<String, dynamic>?;
    final hostName = host?['display_name'] ?? 'Proveedor';
    final listingId = service['id'] as String;
    const serviceFeeRate = 0.07;
    final serviceFee = price * serviceFeeRate;
    final total = price + serviceFee;
    bool hiring = false;

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: AtrioColors.hostBackground, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AtrioColors.hostCardBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AtrioColors.neonLime.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(Icons.check_circle_outline, size: 48, color: AtrioColors.neonLime)),
          const SizedBox(height: 20),
          Text('Confirmar contratación', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AtrioColors.hostTextPrimary)),
          const SizedBox(height: 8),
          Text('$hostName realizará "$title" por ${price.toCLP}/$priceUnit', style: GoogleFonts.inter(fontSize: 14, color: AtrioColors.hostTextSecondary, height: 1.4), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          // Price breakdown
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AtrioColors.hostSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AtrioColors.hostCardBorder)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Precio del servicio', style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextSecondary)),
                Text(price.toCLP, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AtrioColors.hostTextPrimary)),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Tarifa Atrio (7%)', style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextSecondary)),
                Text(serviceFee.toCLP, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AtrioColors.hostTextPrimary)),
              ]),
              const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: AtrioColors.hostCardBorder, height: 1)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AtrioColors.hostTextPrimary)),
                Text(total.toCLP, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AtrioColors.neonLime)),
              ]),
            ]),
          ),
          const SizedBox(height: 10),
          // Milestones
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AtrioColors.hostSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AtrioColors.hostCardBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Avances del servicio', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AtrioColors.hostTextPrimary)),
              const SizedBox(height: 12),
              _MilestonePreview(label: 'Acordar detalles', status: 'pending'),
              _MilestonePreview(label: 'En camino / Inicio', status: 'pending'),
              _MilestonePreview(label: 'Trabajo en progreso', status: 'pending'),
              _MilestonePreview(label: 'Finalizado y pagado', status: 'pending'),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
            onPressed: hiring ? null : () async {
              setSheetState(() => hiring = true);
              try {
                await _hireRealService(hostId, listingId, title, price, serviceFee, total);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'), backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                }
              } finally {
                if (ctx.mounted) setSheetState(() => hiring = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AtrioColors.neonLime, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            child: hiring
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                : Text('Confirmar ${total.toCLP}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
          )),
          const SizedBox(height: 10),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Volver', style: GoogleFonts.inter(fontSize: 14, color: AtrioColors.hostTextSecondary))),
          const SizedBox(height: 8),
        ]),
      ),
      ),
    );
  }

  /// Create a service booking and open chat with the real host
  Future<void> _hireRealService(String hostId, String listingId, String title, double price, double fee, double total) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    final now = DateTime.now();
    await DatabaseService.createBooking({
      'guest_id': currentUser.id,
      'host_id': hostId,
      'listing_id': listingId,
      'check_in': now.toIso8601String(),
      'check_out': now.add(const Duration(hours: 2)).toIso8601String(),
      'guests_count': 1,
      'base_total': price,
      'cleaning_fee': 0,
      'service_fee': fee,
      'total': total,
      'status': 'pending',
      'payment_status': 'pending',
      'rental_mode': 'hours',
      'notes': 'Servicio Rápido: $title',
    });

    final convo = await DatabaseService.getOrCreateConversation(
      userId1: currentUser.id,
      userId2: hostId,
    );

    await DatabaseService.sendMessage(
      conversationId: convo['id'],
      senderId: currentUser.id,
      text: 'Hola! Acabo de solicitar "$title" por ${price.toCLP}. Coordinemos los detalles.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [Icon(Icons.check_circle, color: Colors.black, size: 20), SizedBox(width: 10), Expanded(child: Text('Servicio solicitado!', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)))]),
        backgroundColor: AtrioColors.neonLime, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      context.push('/chat/${convo['id']}');
    }
  }

  /// Open a real chat with a specific host
  Future<void> _openChatWith(String hostId) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    try {
      final convo = await DatabaseService.getOrCreateConversation(
        userId1: currentUser.id,
        userId2: hostId,
      );
      if (mounted) {
        context.push('/chat/${convo['id']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al abrir chat: $e'),
          backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }
}

// ═══════ REAL SERVICE CARD ═══════
class _RealServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onTap;
  const _RealServiceCard({required this.service, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final title = service['title'] ?? 'Servicio';
    final price = (service['base_price'] as num?)?.toDouble() ?? 0;
    final priceUnit = service['price_unit'] ?? 'session';
    final rating = (service['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (service['review_count'] as num?)?.toInt() ?? 0;
    final host = service['host'] as Map<String, dynamic>?;
    final hostName = host?['display_name'] ?? 'Proveedor';
    final hostVerified = host?['is_verified'] == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AtrioColors.hostSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AtrioColors.hostCardBorder)),
        child: Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: AtrioColors.neonLime.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.handyman_rounded, color: AtrioColors.neonLime, size: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AtrioColors.hostTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)), if (hostVerified) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.verified, size: 16, color: AtrioColors.neonLimeDark))]),
            const SizedBox(height: 2),
            Text('$hostName · $reviewCount reseñas', style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [const Icon(Icons.star_rounded, size: 14, color: AtrioColors.ratingGold), const SizedBox(width: 3), Text(rating.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AtrioColors.hostTextPrimary))]),
          ])),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(price.toCLP, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AtrioColors.neonLime)),
            Text('/$priceUnit', style: GoogleFonts.inter(fontSize: 11, color: AtrioColors.hostTextTertiary)),
          ]),
        ]),
      ),
    );
  }
}

// ═══════ STEP ITEM ═══════
class _StepItem extends StatelessWidget {
  final String step, title, subtitle;
  const _StepItem({required this.step, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 28, height: 28, decoration: BoxDecoration(color: AtrioColors.neonLime, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text(step, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AtrioColors.hostTextPrimary)),
        const SizedBox(height: 2),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextTertiary)),
      ])),
    ]));
  }
}

// ═══════ MILESTONE PREVIEW ═══════
class _MilestonePreview extends StatelessWidget {
  final String label, status;
  const _MilestonePreview({required this.label, required this.status});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
      Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: status == 'done' ? AtrioColors.neonLime : status == 'active' ? AtrioColors.neonLime.withValues(alpha: 0.3) : AtrioColors.hostCardBorder), child: status == 'done' ? const Icon(Icons.check, size: 12, color: Colors.black) : null),
      const SizedBox(width: 10),
      Text(label, style: GoogleFonts.inter(fontSize: 13, color: status == 'pending' ? AtrioColors.hostTextTertiary : AtrioColors.hostTextPrimary)),
    ]));
  }
}
