// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Ticket _$TicketFromJson(Map<String, dynamic> json) => _Ticket(
  ticketId: json['id'] as String,
  customerId: json['customer_id'] as String,
  clientTicketUuid: json['client_ticket_uuid'] as String?,
  title: json['title'] as String? ?? '',
  description: json['description'] as String?,
  screenshotUrl: json['screenshot_url'] as String?,
  category: json['category'] as String?,
  status: json['status'] as String? ?? 'New',
  priority: json['priority'] as String?,
  createdBy: json['created_by'] as String? ?? 'Unknown',
  assignedTo: json['assigned_to'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  slaDue: json['sla_due'] == null
      ? null
      : DateTime.parse(json['sla_due'] as String),
  billAmount: (json['bill_amount'] as num?)?.toDouble(),
);

Map<String, dynamic> _$TicketToJson(_Ticket instance) => <String, dynamic>{
  'id': instance.ticketId,
  'customer_id': instance.customerId,
  'client_ticket_uuid': instance.clientTicketUuid,
  'title': instance.title,
  'description': instance.description,
  'screenshot_url': instance.screenshotUrl,
  'category': instance.category,
  'status': instance.status,
  'priority': instance.priority,
  'created_by': instance.createdBy,
  'assigned_to': instance.assignedTo,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'sla_due': instance.slaDue?.toIso8601String(),
  'bill_amount': instance.billAmount,
};
