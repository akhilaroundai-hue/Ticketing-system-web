import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

// Freezed uses JsonKey on constructor parameters; ignore analyzer complaining
// about invalid annotation targets and enum naming style.
// ignore_for_file: invalid_annotation_target, constant_identifier_names

part 'ticket.freezed.dart';
part 'ticket.g.dart';

// Using simple string enums for JSON compatibility without custom converters for now
enum TicketStatus {
  New,
  Open,
  InProgress,
  OnHold,
  WaitingForCustomer,
  Resolved,
  Closed,
  Reopened,
  BillRaised,
  BillProcessed,
}

enum TicketPriority { Low, Medium, High, Urgent }

@freezed
abstract class Ticket with _$Ticket {
  const factory Ticket({
    @JsonKey(name: 'id') required String ticketId,
    @JsonKey(name: 'customer_id') required String customerId,
    @JsonKey(name: 'client_ticket_uuid') String? clientTicketUuid,
    @JsonKey(name: 'title') @Default('') String title,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'screenshot_url') String? screenshotUrl,
    @JsonKey(name: 'category') String? category,
    @JsonKey(name: 'status') @Default('New') String status,
    @JsonKey(name: 'priority') String? priority,
    @JsonKey(name: 'created_by') @Default('Unknown') String createdBy,
    @JsonKey(name: 'assigned_to') String? assignedTo,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'sla_due') DateTime? slaDue,
    @JsonKey(name: 'bill_amount') double? billAmount,
  }) = _Ticket;

  factory Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);
}
 