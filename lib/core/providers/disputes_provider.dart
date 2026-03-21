import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dispute_model.dart';

final disputeFilterProvider = NotifierProvider<DisputeFilterNotifier, String>(
  DisputeFilterNotifier.new,
);

class DisputeFilterNotifier extends Notifier<String> {
  @override
  String build() => 'todas';
  void setFilter(String value) => state = value;
}

final disputesProvider = FutureProvider<List<DisputeModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return _mockDisputes;
});

final disputeDetailProvider = FutureProvider.family<DisputeModel?, String>((ref, id) async {
  await Future.delayed(const Duration(milliseconds: 300));
  try {
    return _mockDisputes.firstWhere((d) => d.id == id);
  } catch (_) {
    return null;
  }
});

final filteredDisputesProvider = Provider<AsyncValue<List<DisputeModel>>>((ref) {
  final filter = ref.watch(disputeFilterProvider);
  final disputesAsync = ref.watch(disputesProvider);

  return disputesAsync.whenData((disputes) {
    if (filter == 'todas') return disputes;
    return disputes.where((d) => d.status == _filterToStatus(filter)).toList();
  });
});

String _filterToStatus(String filter) {
  switch (filter) {
    case 'abiertas': return 'abierta';
    case 'en_revision': return 'en_revision';
    case 'cerradas': return 'cerrada';
    default: return filter;
  }
}

final List<DisputeModel> _mockDisputes = [
  DisputeModel(
    id: 'B392-AX',
    bookingId: 'bk-001',
    guestId: '98e8b712-ae4d-446e-9c50-bf621a1efe75',
    hostId: '053c11bd-9fd7-484e-bb30-d75532d4db54',
    type: 'limpieza',
    title: 'Problema de Limpieza',
    description: 'El espacio no estaba limpio al momento de la llegada.',
    amount: 490.00,
    status: 'abierta',
    priority: 'alta',
    guestReport: '"La piscina estaba visiblemente sucia al llegar. Había algas en los lados y restos flotantes. No pudimos usar las amenidades por las que pagamos."',
    hostDefense: 'La piscina fue limpiada a las 10 AM. Aquí están las fotos de antes y después de la limpieza...',
    guestEvidence: [
      'https://images.unsplash.com/photo-1572331165267-854da2b021b1?w=400',
      'https://images.unsplash.com/photo-1562778612-e1e0cda9915c?w=400',
    ],
    hostEvidence: [
      'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?w=400',
    ],
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    guestData: {'display_name': 'Sara Jenkins', 'photo_url': null},
    hostData: {'display_name': 'Carlos O.', 'photo_url': null},
  ),
  DisputeModel(
    id: 'B441-CK',
    bookingId: 'bk-002',
    guestId: '98e8b712-ae4d-446e-9c50-bf621a1efe75',
    hostId: '053c11bd-9fd7-484e-bb30-d75532d4db54',
    type: 'daños',
    title: 'Daño a Propiedad',
    description: 'Daño reportado en el mobiliario del espacio.',
    amount: 1250.00,
    status: 'en_revision',
    priority: 'alta',
    guestReport: 'El sofá principal tenía una mancha grande que no estaba antes de nuestra llegada. El host nos culpa injustamente.',
    hostDefense: 'El sofá estaba en perfectas condiciones. Tengo fotos del check-in que lo demuestran.',
    guestEvidence: [],
    hostEvidence: [],
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
    guestData: {'display_name': 'María López', 'photo_url': null},
    hostData: {'display_name': 'Carlos O.', 'photo_url': null},
  ),
  DisputeModel(
    id: 'B512-FN',
    bookingId: 'bk-003',
    guestId: '98e8b712-ae4d-446e-9c50-bf621a1efe75',
    hostId: '053c11bd-9fd7-484e-bb30-d75532d4db54',
    type: 'cancelación',
    title: 'Cancelación Tardía',
    description: 'El host canceló la reserva a último minuto.',
    amount: 320.00,
    status: 'resuelta',
    priority: 'media',
    guestReport: 'El anfitrión canceló nuestra reserva 2 horas antes del check-in. Tuvimos que buscar alojamiento de emergencia.',
    hostDefense: 'Hubo una emergencia familiar. Informé al huésped lo antes posible.',
    guestEvidence: [],
    hostEvidence: [],
    resolution: 'reembolso_completo',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    guestData: {'display_name': 'Pedro Ramírez', 'photo_url': null},
    hostData: {'display_name': 'Ana García', 'photo_url': null},
  ),
  DisputeModel(
    id: 'B678-MQ',
    bookingId: 'bk-004',
    guestId: '98e8b712-ae4d-446e-9c50-bf621a1efe75',
    hostId: '053c11bd-9fd7-484e-bb30-d75532d4db54',
    type: 'servicio',
    title: 'Servicio Incompleto',
    description: 'El servicio de catering no incluyó lo acordado.',
    amount: 180.00,
    status: 'cerrada',
    priority: 'baja',
    guestReport: 'El catering prometía 5 platillos y solo entregaron 3. Faltaron los postres y las bebidas premium.',
    hostDefense: null,
    guestEvidence: [],
    hostEvidence: [],
    resolution: 'reembolso_parcial',
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    updatedAt: DateTime.now().subtract(const Duration(days: 8)),
    guestData: {'display_name': 'Laura Sánchez', 'photo_url': null},
    hostData: {'display_name': 'Roberto Díaz', 'photo_url': null},
  ),
];
