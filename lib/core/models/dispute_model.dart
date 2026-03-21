class DisputeModel {
  final String id;
  final String bookingId;
  final String guestId;
  final String hostId;
  final String type;
  final String title;
  final String description;
  final double amount;
  final String status;
  final String priority;
  final String guestReport;
  final String? hostDefense;
  final List<String> guestEvidence;
  final List<String> hostEvidence;
  final String? resolution;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? guestData;
  final Map<String, dynamic>? hostData;

  DisputeModel({
    required this.id,
    required this.bookingId,
    required this.guestId,
    required this.hostId,
    required this.type,
    required this.title,
    required this.description,
    required this.amount,
    required this.status,
    required this.priority,
    required this.guestReport,
    this.hostDefense,
    this.guestEvidence = const [],
    this.hostEvidence = const [],
    this.resolution,
    required this.createdAt,
    required this.updatedAt,
    this.guestData,
    this.hostData,
  });

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    return DisputeModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      guestId: json['guest_id'] as String,
      hostId: json['host_id'] as String,
      type: json['type'] as String? ?? 'otro',
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'abierta',
      priority: json['priority'] as String? ?? 'media',
      guestReport: json['guest_report'] as String? ?? '',
      hostDefense: json['host_defense'] as String?,
      guestEvidence: (json['guest_evidence'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      hostEvidence: (json['host_evidence'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      resolution: json['resolution'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      guestData: json['guest'] as Map<String, dynamic>?,
      hostData: json['host'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'guest_id': guestId,
      'host_id': hostId,
      'type': type,
      'title': title,
      'description': description,
      'amount': amount,
      'status': status,
      'priority': priority,
      'guest_report': guestReport,
      'host_defense': hostDefense,
      'guest_evidence': guestEvidence,
      'host_evidence': hostEvidence,
      'resolution': resolution,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'guest': guestData,
      'host': hostData,
    };
  }

  DisputeModel copyWith({
    String? id,
    String? bookingId,
    String? guestId,
    String? hostId,
    String? type,
    String? title,
    String? description,
    double? amount,
    String? status,
    String? priority,
    String? guestReport,
    String? hostDefense,
    List<String>? guestEvidence,
    List<String>? hostEvidence,
    String? resolution,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? guestData,
    Map<String, dynamic>? hostData,
  }) {
    return DisputeModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      guestId: guestId ?? this.guestId,
      hostId: hostId ?? this.hostId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      guestReport: guestReport ?? this.guestReport,
      hostDefense: hostDefense ?? this.hostDefense,
      guestEvidence: guestEvidence ?? this.guestEvidence,
      hostEvidence: hostEvidence ?? this.hostEvidence,
      resolution: resolution ?? this.resolution,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      guestData: guestData ?? this.guestData,
      hostData: hostData ?? this.hostData,
    );
  }
}
