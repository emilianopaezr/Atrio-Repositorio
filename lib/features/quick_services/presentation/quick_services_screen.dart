import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

const _bg = Color(0xFF0A0A0A);
const _surface = Color(0xFF141414);
const _surfaceLight = Color(0xFF1E1E1E);
const _border = Color(0xFF2A2A2A);
const _textPrimary = Color(0xFFFFFFFF);
const _textSecondary = Color(0xFFAAAAAA);
const _textMuted = Color(0xFF666666);
const _lime = Color(0xFFD4FF00);
const _limeDark = Color(0xFF9BBF00);

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
    _ServiceRequest(id: 'qr2', title: 'Armar escritorio de IKEA', description: 'Modelo MALM con 2 cajones. Ya tengo las herramientas basicas.', requester: 'Tomas R.', budget: 25, category: 'Armado', urgency: 'Esta semana', offers: 5, postedAgo: 'Hace 4h'),
    _ServiceRequest(id: 'qr3', title: 'Limpieza profunda depto 2 hab', description: '65m2, cocina, bano, sala y 2 habitaciones. Preferible traer productos.', requester: 'Camila S.', budget: 50, category: 'Limpieza', urgency: 'Manana', offers: 2, postedAgo: 'Hace 1h'),
    _ServiceRequest(id: 'qr4', title: 'Pintar habitacion infantil', description: 'Habitacion de 12m2, paredes lisas. Color a definir, compro la pintura.', requester: 'Lucia V.', budget: 60, category: 'Reparaciones', urgency: 'Esta semana', offers: 1, postedAgo: 'Hace 6h'),
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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Servicios Rapidos', style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w800, color: _textPrimary)),
        actions: [
          GestureDetector(
            onTap: () => context.push('/publish-service', extra: 'offer'),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _lime.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add, size: 16, color: _lime),
                const SizedBox(width: 4),
                Text('Publicar', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700, color: _lime)),
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
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: _lime, borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.black,
              unselectedLabelColor: _textSecondary,
              labelStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500),
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
                      color: isSelected ? _lime : _surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? _limeDark : _border),
                    ),
                    child: Text(cat, style: GoogleFonts.roboto(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.black : _textSecondary)),
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
          decoration: const BoxDecoration(color: _bg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(
            controller: scrollCtrl, padding: const EdgeInsets.all(24),
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(color: _lime.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)), child: Icon(service.icon, color: _lime, size: 28)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(service.title, style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w800, color: _textPrimary)),
                  const SizedBox(height: 4),
                  Text(service.category, style: GoogleFonts.roboto(fontSize: 13, color: _textMuted)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('\$${service.price.toInt()}', style: GoogleFonts.roboto(fontSize: 28, fontWeight: FontWeight.w800, color: _lime)),
                  Text('/hora', style: GoogleFonts.roboto(fontSize: 12, color: _textMuted)),
                ]),
              ]),
              const SizedBox(height: 20),
              Text(service.description, style: GoogleFonts.roboto(fontSize: 14, color: _textSecondary, height: 1.5)),
              const SizedBox(height: 24),
              // Provider card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
                child: Row(children: [
                  CircleAvatar(radius: 22, backgroundColor: _lime.withValues(alpha: 0.15), child: Text(service.provider[0], style: GoogleFonts.roboto(fontWeight: FontWeight.w700, color: _lime, fontSize: 18))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(service.provider, style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary)),
                      if (service.isVerified) ...[const SizedBox(width: 6), Icon(Icons.verified, size: 16, color: _limeDark)],
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)), const SizedBox(width: 3),
                      Text('${service.providerRating}', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary)),
                      Text(' · ${service.providerJobs} trabajos', style: GoogleFonts.roboto(fontSize: 13, color: _textMuted)),
                    ]),
                  ])),
                  GestureDetector(
                    onTap: () { Navigator.pop(ctx); _showChatSnack(service.provider); },
                    child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _lime.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.chat_outlined, size: 20, color: _lime)),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Text('Como funciona', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary)),
              const SizedBox(height: 14),
              _StepItem(step: '1', title: 'Contratas el servicio', subtitle: 'Acuerdan fecha, hora y detalles por chat'),
              _StepItem(step: '2', title: 'Se realiza el trabajo', subtitle: 'El proveedor marca avances en tiempo real'),
              _StepItem(step: '3', title: 'Confirmas y pagas', subtitle: 'Solo pagas cuando estas satisfecho'),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
                onPressed: () { Navigator.pop(ctx); _showHireConfirmation(service); },
                style: ElevatedButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: Text('Contratar por \$${service.price.toInt()}/hr', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w800)),
              )),
              const SizedBox(height: 12),
              Center(child: Text('Pago seguro · Garantía Atrio', style: GoogleFonts.roboto(fontSize: 12, color: _textMuted))),
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
          decoration: const BoxDecoration(color: _bg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(controller: scrollCtrl, padding: const EdgeInsets.all(24), children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.schedule, size: 14, color: Colors.orange), const SizedBox(width: 4), Text(request.urgency, style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange))])),
              const Spacer(),
              Text(request.postedAgo, style: GoogleFonts.roboto(fontSize: 12, color: _textMuted)),
            ]),
            const SizedBox(height: 16),
            Text(request.title, style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w800, color: _textPrimary)),
            const SizedBox(height: 10),
            Text(request.description, style: GoogleFonts.roboto(fontSize: 14, color: _textSecondary, height: 1.5)),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Presupuesto', style: GoogleFonts.roboto(fontSize: 12, color: _textMuted)),
                  const SizedBox(height: 2),
                  Text('\$${request.budget.toInt()}', style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.w800, color: _lime)),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Solicitado por', style: GoogleFonts.roboto(fontSize: 12, color: _textMuted)),
                  const SizedBox(height: 2),
                  Text(request.requester, style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: _surfaceLight, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.how_to_reg, size: 18, color: _limeDark), const SizedBox(width: 8),
                Text('${request.offers} personas ya ofertaron', style: GoogleFonts.roboto(fontSize: 13, color: _textSecondary)),
                const Spacer(),
                Text(request.category, style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, color: _limeDark)),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 54, child: ElevatedButton.icon(
              onPressed: () { Navigator.pop(ctx); _showMakeOffer(request); },
              style: ElevatedButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              icon: const Icon(Icons.send_rounded, size: 20),
              label: Text('Hacer oferta', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w800)),
            )),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(ctx); _showChatSnack(request.requester); },
              style: OutlinedButton.styleFrom(foregroundColor: _lime, side: BorderSide(color: _lime.withValues(alpha: 0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: Text('Preguntar antes', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600)),
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
        decoration: const BoxDecoration(color: _bg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _lime.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(Icons.check_circle_outline, size: 48, color: _lime)),
          const SizedBox(height: 20),
          Text('Confirmar contratacion', style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w800, color: _textPrimary)),
          const SizedBox(height: 8),
          Text('${service.provider} realizara "${service.title}" por \$${service.price.toInt()}/hora', style: GoogleFonts.roboto(fontSize: 14, color: _textSecondary, height: 1.4), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          // Milestones
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Avances del servicio', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary)),
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
                content: Row(children: [const Icon(Icons.check_circle, color: Colors.black, size: 20), const SizedBox(width: 10), Expanded(child: Text('Servicio contratado! Chatea con ${service.provider}', style: GoogleFonts.roboto(fontWeight: FontWeight.w600, color: Colors.black)))]),
                backgroundColor: _lime, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), duration: const Duration(seconds: 3),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            child: Text('Confirmar y chatear', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w800)),
          )),
          const SizedBox(height: 10),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Volver', style: GoogleFonts.roboto(fontSize: 14, color: _textSecondary))),
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
          decoration: const BoxDecoration(color: _bg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Hacer oferta', style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w800, color: _textPrimary)),
            const SizedBox(height: 4),
            Text('Para: "${request.title}"', style: GoogleFonts.roboto(fontSize: 13, color: _textMuted)),
            const SizedBox(height: 20),
            Text('Tu precio (\$)', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: priceController, keyboardType: TextInputType.number,
              style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.w800, color: _lime),
              decoration: InputDecoration(
                prefixText: '\$ ', prefixStyle: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.w800, color: _lime),
                filled: true, fillColor: _surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _limeDark, width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Mensaje (opcional)', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: messageController, maxLines: 3,
              style: GoogleFonts.roboto(fontSize: 14, color: _textPrimary),
              decoration: InputDecoration(
                hintText: 'Cuentale por que eres la mejor opcion...', hintStyle: GoogleFonts.roboto(fontSize: 13, color: _textMuted),
                filled: true, fillColor: _surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _limeDark, width: 1.5)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Row(children: [const Icon(Icons.check_circle, color: Colors.black, size: 20), const SizedBox(width: 10), const Expanded(child: Text('Oferta enviada!', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)))]),
                  backgroundColor: _lime, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              },
              style: ElevatedButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: Text('Enviar oferta', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w800)),
            )),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  void _showChatSnack(String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 18), const SizedBox(width: 10), Text('Abriendo chat con $name...', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black))]),
      backgroundColor: _lime, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), duration: const Duration(seconds: 2),
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
      child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: _lime.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: Icon(service.icon, color: _lime, size: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(service.title, style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)), if (service.isVerified) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.verified, size: 16, color: _limeDark))]),
            const SizedBox(height: 2),
            Text('${service.provider} · ${service.providerJobs} trabajos', style: GoogleFonts.roboto(fontSize: 12, color: _textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)), const SizedBox(width: 3), Text('${service.providerRating}', style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary))]),
          ])),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${service.price.toInt()}', style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w800, color: _lime)),
            Text('/hora', style: GoogleFonts.roboto(fontSize: 11, color: _textMuted)),
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
      child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(request.title, style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _lime, borderRadius: BorderRadius.circular(8)), child: Text('\$${request.budget.toInt()}', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black))),
          ]),
          const SizedBox(height: 6),
          Text(request.description, style: GoogleFonts.roboto(fontSize: 13, color: _textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.person_outline, size: 14, color: _textMuted), const SizedBox(width: 4),
            Text(request.requester, style: GoogleFonts.roboto(fontSize: 12, color: _textMuted)),
            const SizedBox(width: 12),
            Icon(Icons.schedule, size: 14, color: Colors.orange), const SizedBox(width: 4),
            Text(request.urgency, style: GoogleFonts.roboto(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _surfaceLight, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.how_to_reg, size: 12, color: _limeDark), const SizedBox(width: 4), Text('${request.offers} ofertas', style: GoogleFonts.roboto(fontSize: 11, color: _textSecondary, fontWeight: FontWeight.w600))])),
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
      Container(width: 28, height: 28, decoration: BoxDecoration(color: _lime, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text(step, style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
        const SizedBox(height: 2),
        Text(subtitle, style: GoogleFonts.roboto(fontSize: 12, color: _textMuted)),
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
      Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: status == 'done' ? _lime : status == 'active' ? _lime.withValues(alpha: 0.3) : _border), child: status == 'done' ? const Icon(Icons.check, size: 12, color: Colors.black) : null),
      const SizedBox(width: 10),
      Text(label, style: GoogleFonts.roboto(fontSize: 13, color: status == 'pending' ? _textMuted : _textPrimary)),
    ]));
  }
}
