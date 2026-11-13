enum LeadStatus {
  newLead,
  contacted,
  negotiation,
  dealConfirmed,
  workInProgress,
  completed,
  paymentPending,
  closed,
}

extension LeadStatusExtension on LeadStatus {
  String get displayName {
    switch (this) {
      case LeadStatus.newLead:
        return 'New Lead';
      case LeadStatus.contacted:
        return 'Contacted';
      case LeadStatus.negotiation:
        return 'Negotiation';
      case LeadStatus.dealConfirmed:
        return 'Deal Confirmed';
      case LeadStatus.workInProgress:
        return 'Work In Progress';
      case LeadStatus.completed:
        return 'Completed';
      case LeadStatus.paymentPending:
        return 'Payment Pending';
      case LeadStatus.closed:
        return 'Closed';
    }
  }
}

class Client {
  final String id;
  final String userId;
  final String clientBrandName;
  final String contactPerson;
  final String phone;
  final String whatsapp;
  final String email;
  final String instagram;
  final String companyName;
  final String projectDetails;
  final double dealAmount;
  final String paymentStatus; // Pending, Advance Paid, Fully Paid
  final DateTime? workDeadline;
  final DateTime? followUpDate;
  final LeadStatus status;
  final String notes;
  final DateTime createdAt;

  Client({
    required this.id,
    required this.userId,
    required this.clientBrandName,
    this.contactPerson = '',
    this.phone = '',
    this.whatsapp = '',
    this.email = '',
    this.instagram = '',
    this.companyName = '',
    this.projectDetails = '',
    this.dealAmount = 0.0,
    this.paymentStatus = 'Pending',
    this.workDeadline,
    this.followUpDate,
    this.status = LeadStatus.newLead,
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'client_brand_name': clientBrandName,
      'contact_person': contactPerson,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'instagram': instagram,
      'company_name': companyName,
      'project_details': projectDetails,
      'deal_amount': dealAmount,
      'payment_status': paymentStatus,
      'work_deadline': workDeadline?.toIso8601String(),
      'follow_up_date': followUpDate?.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      clientBrandName: map['client_brand_name'] ?? '',
      contactPerson: map['contact_person'] ?? '',
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      email: map['email'] ?? '',
      instagram: map['instagram'] ?? '',
      companyName: map['company_name'] ?? '',
      projectDetails: map['project_details'] ?? '',
      dealAmount: (map['deal_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: map['payment_status'] ?? 'Pending',
      workDeadline: map['work_deadline'] != null ? DateTime.parse(map['work_deadline']) : null,
      followUpDate: map['follow_up_date'] != null ? DateTime.parse(map['follow_up_date']) : null,
      status: LeadStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => LeadStatus.newLead,
      ),
      notes: map['notes'] ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
    );
  }
}

class ClientInteraction {
  final String id;
  final String clientId;
  final String interactionType; // Call, WhatsApp, Email, Meeting, Deal Proposal
  final String notes;
  final DateTime date;

  ClientInteraction({
    required this.id,
    required this.clientId,
    required this.interactionType,
    required this.notes,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'interaction_type': interactionType,
      'notes': notes,
      'date': date.toIso8601String(),
    };
  }

  factory ClientInteraction.fromMap(Map<String, dynamic> map) {
    return ClientInteraction(
      id: map['id'] ?? '',
      clientId: map['client_id'] ?? '',
      interactionType: map['interaction_type'] ?? 'Note',
      notes: map['notes'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
    );
  }
}

