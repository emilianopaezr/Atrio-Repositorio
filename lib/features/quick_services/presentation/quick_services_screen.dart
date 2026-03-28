import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';

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

  final _categories = [
    'Todos',
    'Mudanza',
    'Limpieza',
    'Armado',
    'Eventos',
    'Jardineria',
    'Reparaciones',
  ];

  final List<_ServiceData> _availableServices = [
    _ServiceData(id: 'qs1', title: 'Ayuda con Mudanza', description: 'Carga y descarga de cajas, muebles y enseres. Cuento con camioneta propia.', provider: 'Juan M.', providerRating: 4.8, providerJobs: 34, price: 25, category: 'Mudanza', icon: Icons.local_shipping_rounded, isVerified: true),
    _ServiceData(id: 'qs2', title: 'Armado de Muebles', description: 'Ikea, Sodimac y mas. Armado profesional con herramientas propias.', provider: 'Carlos R.', providerRating: 4.9, providerJobs: 52, price: 30, category: 'Armado', icon: Icons.handyman_rounded, isVerified: true),
    _ServiceData(id: 'qs3', title: 'Limpieza Profunda', description: 'Departamento o casa completa. Incluyo productos de limpieza.', provider: 'Maria L.', providerRating: 4.7, providerJobs: 28, price: 40, category: 'Limpieza', icon: Icons.cleaning_services_rounded, isVerified: false),
    _ServiceData(id: 'qs4', title: 'Apoyo en Evento', description: 'Organizacion, montaje y logistica para todo tipo de eventos.', provider: 'Ana G.', providerRating: 4.6, providerJobs: 19, price: 35, category: 'Eventos', icon: Icons.celebration_rounded, isVerified: false),
    _ServiceData(id: 'qs5', title: 'Pintura de Interiores', description: 'Pintura de paredes, techos y acabados. Material incluido.', provider: 'Roberto P.', providerRating: 4.8, providerJobs: 41, price: 45, category: 'Reparaciones', icon: Icons.format_paint_rounded, isVerified: true),
    _ServiceData(id: 'qs6', title: 'Jardineria Basica', description: 'Corte de cesped, poda de arbustos y limpieza general.', provider: 'Pedro S.', providerRating: 4.5, providerJobs: 16, price: 20, category: 'Jardineria', icon: Icons.grass_rounded, isVerified: false),
    _ServiceData(id: 'qs7', title: 'Montaje de TV', description: 'Instalacion de televisor en pared con soporte incluido.', provider: 'Luis F.', providerRating: 4.9, providerJobs: 63, price: 35, category: 'Armado', icon: Icons.tv_rounded, isVerified: true),
    _ServiceData(id: 'qs8', title: 'Limpieza Post-Obra', description: 'Limpieza completa de escombros y polvo despues de remodelacion.', provider: 'Sandra V.', providerRating: 4.7, providerJobs: 22, price: 55, category: 'Limpieza', icon: Icons.cleaning_services_rounded, isVerified: false),
  ];

  final List<_ServiceRequest> _requests = [
    _ServiceRequest(id: 'qr1', title: 'Necesito ayuda para mover sofa', description: 'Sofa grande de 3 cuerpos, piso 4 sin ascensor. Necesito 2 personas.', requester: 'Daniela M.', budget: 30, category: 'Mudanza', urgency: 'Hoy', offers: 3, postedAgo: 'Hace 2h'),
    _ServiceRequest(id: 'qr2', title: 'Armar escritorio de IKEA', description: 'Modelo MALM con 2 cajones. Ya tengo las herramientas basicas.', requester: 'Tomas R.', budget: 25, category: 'Armado', urgency: 'Semana', offers: 5, postedAgo: 'Hace 4h'),
    _ServiceRequest(id: 'qr3', title: 'Limpieza profunda depto 2 hab', description: '65m2, cocina, bano, sala y 2 habitaciones. Preferible traer productos.', requester: 'Camila S.', budget: 50, category: 'Limpieza', urgency: 'Manana', offers: 2, postedAgo: 'Hace 1h'),
    _ServiceRequest(id: 'qr4', title: 'Pintar habitacion infantil', description: 'Habitacion de 12m2, paredes lisas. Color a definir, compro la pintura.', requester: 'Lucia V.', budget: 60, category: 'Reparaciones', urgency: 'Semana', offers: 1, postedAgo: 'Hace 6h'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_ServiceData> get _filteredServices {
    if (_selectedCategory == 'Todos') return _availableServices;
    return _availableServices.where((s) => s.category == _selectedCategory).toList();
  }

  List<_ServiceRequest> get _filteredRequests {
    if (_selectedCategory == 'Todos') return _requests;
    return _requests.where((r) => r.category == _selectedCategory).toList();
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
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filteredServices.length,
                  itemBuilder: (context, index) => _ServiceCard(service: _filteredServices[index], onTap: () => _showServiceDetail(_filteredServices[index])),
                ),
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filteredRequests.length,
                  itemBuilder: (context, index) => _RequestCard(request: _filteredRequests[index], onTap: () => _showRequestDetail(_filteredRequests[index])),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showServiceDetail(_ServiceData service) {
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
                Container(width: 56, height: 56, decoration: BoxDecoration(color: AtrioColors.neonLime.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)), child: Icon(service.icon, color: AtrioColors.neonLime, size: 28)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(service.title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AtrioColors.hostTextPrimary)),
                  const SizedBox(height: 4),
                  Text(service.category, style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextTertiary)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('\$${service.price.toInt()}', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AtrioColors.neonLime)),
                  Text('/hora', style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextTertiary)),
                ]),
              ]),
              const SizedBox(height: 20),
              Text(service.description, style: GoogleFonts.inter(fontSize: 14, color: AtrioColors.hostTextSecondary, height: 1.5)),
              const SizedBox(height: 24),
              // Provider card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AtrioColors.hostSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AtrioColors.hostCardBorder)),
                child: Row(children: [
                  CircleAvatar(radius: 22, backgroundColor: AtrioColors.neonLime.withValues(alpha: 0.15), child: Text(service.provider[0], style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AtrioColors.neonLime, fontSize: 18))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(service.provider, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AtrioColors.hostTextPrimary)),
                      if (service.isVerified) ...[const SizedBox(width: 6), Icon(Icons.verified, size: 16, color: AtrioColors.neonLimeDark)],
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 14, color: AtrioColors.ratingGold), const SizedBox(width: 3),
                      Text('${service.providerRating}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AtrioColors.hostTextPrimary)),
                      Text(' · ${service.providerJobs} trabajos', style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextTertiary)),
                    ]),
                  ])),
                  GestureDetector(
                    onTap: () { Navigator.pop(ctx); _showChatSnack(service.provider); },
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
                onPressed: () { Navigator.pop(ctx); _showHireConfirmation(service); },
                style: ElevatedButton.styleFrom(backgroundColor: AtrioColors.neonLime, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: Text('Contratar por \$${service.price.toInt()}/hr', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
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

  void _showRequestDetail(_ServiceRequest request) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(color: AtrioColors.hostBackground, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(controller: scrollCtrl, padding: const EdgeInsets.all(24), children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AtrioColors.hostCardBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.schedule, size: 14, color: Colors.orange), const SizedBox(width: 4), Text(request.urgency, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange))])),
              const Spacer(),
              Text(request.postedAgo, style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextTertiary)),
            ]),
            const SizedBox(height: 16),
            Text(request.title, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AtrioColors.hostTextPrimary)),
            const SizedBox(height: 10),
            Text(request.description, style: GoogleFonts.inter(fontSize: 14, color: AtrioColors.hostTextSecondary, height: 1.5)),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AtrioColors.hostSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AtrioColors.hostCardBorder)),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Presupuesto', style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextTertiary)),
                  const SizedBox(height: 2),
                  Text('\$${request.budget.toInt()}', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AtrioColors.neonLime)),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Solicitado por', style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextTertiary)),
                  const SizedBox(height: 2),
                  Text(request.requester, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AtrioColors.hostTextPrimary)),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: AtrioColors.hostSurfaceVariant, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.how_to_reg, size: 18, color: AtrioColors.neonLimeDark), const SizedBox(width: 8),
                Text('${request.offers} personas ya ofertaron', style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextSecondary)),
                const Spacer(),
                Text(request.category, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AtrioColors.neonLimeDark)),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 54, child: ElevatedButton.icon(
              onPressed: () { Navigator.pop(ctx); _showMakeOffer(request); },
              style: ElevatedButton.styleFrom(backgroundColor: AtrioColors.neonLime, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              icon: const Icon(Icons.send_rounded, size: 20),
              label: Text('Hacer oferta', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
            )),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(ctx); _showChatSnack(request.requester); },
              style: OutlinedButton.styleFrom(foregroundColor: AtrioColors.neonLime, side: BorderSide(color: AtrioColors.neonLime.withValues(alpha: 0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: Text('Preguntar antes', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            )),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  void _showHireConfirmation(_ServiceData service) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: AtrioColors.hostBackground, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AtrioColors.hostCardBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AtrioColors.neonLime.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(Icons.check_circle_outline, size: 48, color: AtrioColors.neonLime)),
          const SizedBox(height: 20),
          Text('Confirmar contratacion', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AtrioColors.hostTextPrimary)),
          const SizedBox(height: 8),
          Text('${service.provider} realizara "${service.title}" por \$${service.price.toInt()}/hora', style: GoogleFonts.inter(fontSize: 14, color: AtrioColors.hostTextSecondary, height: 1.4), textAlign: TextAlign.center),
          const SizedBox(height: 20),
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
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Row(children: [const Icon(Icons.check_circle, color: Colors.black, size: 20), const SizedBox(width: 10), Expanded(child: Text('Servicio contratado! Chatea con ${service.provider}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black)))]),
                backgroundColor: AtrioColors.neonLime, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), duration: const Duration(seconds: 3),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AtrioColors.neonLime, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            child: Text('Confirmar y chatear', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
          )),
          const SizedBox(height: 10),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Volver', style: GoogleFonts.inter(fontSize: 14, color: AtrioColors.hostTextSecondary))),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showMakeOffer(_ServiceRequest request) {
    final priceController = TextEditingController(text: request.budget.toInt().toString());
    final messageController = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: AtrioColors.hostBackground, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AtrioColors.hostCardBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Hacer oferta', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AtrioColors.hostTextPrimary)),
            const SizedBox(height: 4),
            Text('Para: "${request.title}"', style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextTertiary)),
            const SizedBox(height: 20),
            Text('Tu precio (\$)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AtrioColors.hostTextPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: priceController, keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AtrioColors.neonLime),
              decoration: InputDecoration(
                prefixText: '\$ ', prefixStyle: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AtrioColors.neonLime),
                filled: true, fillColor: AtrioColors.hostSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AtrioColors.hostCardBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AtrioColors.hostCardBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AtrioColors.neonLimeDark, width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Mensaje (opcional)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AtrioColors.hostTextPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: messageController, maxLines: 3,
              style: GoogleFonts.inter(fontSize: 14, color: AtrioColors.hostTextPrimary),
              decoration: InputDecoration(
                hintText: 'Cuentale por que eres la mejor opcion...', hintStyle: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextTertiary),
                filled: true, fillColor: AtrioColors.hostSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AtrioColors.hostCardBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AtrioColors.hostCardBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AtrioColors.neonLimeDark, width: 1.5)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
              onPressed: () {
                final price = priceController.text.trim();
                final msg = messageController.text.trim();
                if (price.isEmpty || double.tryParse(price) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Ingresa un precio válido', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                  return;
                }
                Navigator.pop(ctx);
                _showOfferConfirmation(request, double.parse(price), msg);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AtrioColors.neonLime, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: Text('Revisar oferta', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
            )),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  void _showOfferConfirmation(_ServiceRequest request, double price, String message) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: AtrioColors.hostBackground, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AtrioColors.hostCardBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AtrioColors.neonLime.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(Icons.send_rounded, size: 40, color: AtrioColors.neonLime)),
          const SizedBox(height: 20),
          Text('Confirmar oferta', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AtrioColors.hostTextPrimary)),
          const SizedBox(height: 8),
          Text('Para: "${request.title}"', style: GoogleFonts.inter(fontSize: 14, color: AtrioColors.hostTextSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AtrioColors.hostSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AtrioColors.hostCardBorder)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Tu precio', style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextSecondary)),
                Text('\$${price.toInt()}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AtrioColors.neonLime)),
              ]),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: AtrioColors.hostCardBorder, height: 1),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: Text('Mensaje:', style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextTertiary))),
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerLeft, child: Text(message, style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextSecondary), maxLines: 3, overflow: TextOverflow.ellipsis)),
              ],
              const SizedBox(height: 12),
              const Divider(color: AtrioColors.hostCardBorder, height: 1),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Solicitante', style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextSecondary)),
                Text(request.requester, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AtrioColors.hostTextPrimary)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Row(children: [const Icon(Icons.check_circle, color: Colors.black, size: 20), const SizedBox(width: 10), const Expanded(child: Text('Oferta enviada exitosamente', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)))]),
                backgroundColor: AtrioColors.neonLime, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AtrioColors.neonLime, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            child: Text('Confirmar y enviar', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
          )),
          const SizedBox(height: 10),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Volver a editar', style: GoogleFonts.inter(fontSize: 14, color: AtrioColors.hostTextSecondary))),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showChatSnack(String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 18), const SizedBox(width: 10), Text('Abriendo chat con $name...', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black))]),
      backgroundColor: AtrioColors.neonLime, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), duration: const Duration(seconds: 2),
    ));
  }
}

// ═══════ DATA MODELS ═══════
class _ServiceData {
  final String id, title, description, provider, category;
  final double providerRating, price;
  final int providerJobs;
  final IconData icon;
  final bool isVerified;
  const _ServiceData({required this.id, required this.title, required this.description, required this.provider, required this.providerRating, required this.providerJobs, required this.price, required this.category, required this.icon, required this.isVerified});
}

class _ServiceRequest {
  final String id, title, description, requester, category, urgency, postedAgo;
  final double budget;
  final int offers;
  const _ServiceRequest({required this.id, required this.title, required this.description, required this.requester, required this.budget, required this.category, required this.urgency, required this.offers, required this.postedAgo});
}

// ═══════ SERVICE CARD ═══════
class _ServiceCard extends StatelessWidget {
  final _ServiceData service;
  final VoidCallback onTap;
  const _ServiceCard({required this.service, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AtrioColors.hostSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AtrioColors.hostCardBorder)),
        child: Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: AtrioColors.neonLime.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: Icon(service.icon, color: AtrioColors.neonLime, size: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(service.title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AtrioColors.hostTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)), if (service.isVerified) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.verified, size: 16, color: AtrioColors.neonLimeDark))]),
            const SizedBox(height: 2),
            Text('${service.provider} · ${service.providerJobs} trabajos', style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [const Icon(Icons.star_rounded, size: 14, color: AtrioColors.ratingGold), const SizedBox(width: 3), Text('${service.providerRating}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AtrioColors.hostTextPrimary))]),
          ])),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${service.price.toInt()}', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AtrioColors.neonLime)),
            Text('/hora', style: GoogleFonts.inter(fontSize: 11, color: AtrioColors.hostTextTertiary)),
          ]),
        ]),
      ),
    );
  }
}

// ═══════ REQUEST CARD ═══════
class _RequestCard extends StatelessWidget {
  final _ServiceRequest request;
  final VoidCallback onTap;
  const _RequestCard({required this.request, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AtrioColors.hostSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AtrioColors.hostCardBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(request.title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AtrioColors.hostTextPrimary))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AtrioColors.neonLime, borderRadius: BorderRadius.circular(8)), child: Text('\$${request.budget.toInt()}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black))),
          ]),
          const SizedBox(height: 6),
          Text(request.description, style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.hostTextSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.person_outline, size: 14, color: AtrioColors.hostTextTertiary), const SizedBox(width: 4),
            Text(request.requester, style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.hostTextTertiary)),
            const SizedBox(width: 12),
            Icon(Icons.schedule, size: 14, color: Colors.orange), const SizedBox(width: 4),
            Text(request.urgency, style: GoogleFonts.inter(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AtrioColors.hostSurfaceVariant, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.how_to_reg, size: 12, color: AtrioColors.neonLimeDark), const SizedBox(width: 4), Text('${request.offers} ofertas', style: GoogleFonts.inter(fontSize: 11, color: AtrioColors.hostTextSecondary, fontWeight: FontWeight.w600))])),
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
