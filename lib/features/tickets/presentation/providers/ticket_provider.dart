import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../data/repositories/supabase_ticket_repository.dart';
import '../../domain/entities/ticket.dart';

part 'ticket_provider.g.dart';

// Repository provider
@riverpod
TicketRepository ticketRepository(Ref ref) {
  return SupabaseTicketRepository(Supabase.instance.client);
}

// Filter state provider (null = all, 'Open', 'Closed')
@riverpod
class TicketFilter extends _$TicketFilter {
  @override
  String? build() => null;

  void setFilter(String? filter) {
    state = filter;
  }
}

@riverpod
class TicketSearchQuery extends _$TicketSearchQuery {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

@riverpod
class TicketPriorityFilter extends _$TicketPriorityFilter {
  @override
  String build() => 'All';

  void setFilter(String value) {
    state = value;
  }
}

@riverpod
class TicketAssigneeFilter extends _$TicketAssigneeFilter {
  @override
  String build() => 'all';

  void setAll() {
    state = 'all';
  }

  void setUnassigned() {
    state = 'unassigned';
  }

  void setMe() {
    state = 'me';
  }

  void setAgent(String agentId) {
    state = 'agent:$agentId';
  }
}

@riverpod
class TicketSort extends _$TicketSort {
  @override
  String build() => 'sla';

  void setSort(String value) {
    state = value;
  }
}

// Optimistic UI overrides (e.g. instant status updates before realtime catches up)
final ticketOptimisticStatusOverridesProvider =
    fr.NotifierProvider<_TicketOptimisticStatusOverrides, Map<String, String>>(
      _TicketOptimisticStatusOverrides.new,
    );

final ticketOptimisticAssigneeOverridesProvider =
    fr.NotifierProvider<
      _TicketOptimisticAssigneeOverrides,
      Map<String, String>
    >(_TicketOptimisticAssigneeOverrides.new);

class _TicketOptimisticStatusOverrides
    extends fr.Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => <String, String>{};

  void setOverride(String ticketId, String status) {
    state = <String, String>{...state, ticketId: status};
  }

  void clearOverride(String ticketId) {
    final next = <String, String>{...state};
    next.remove(ticketId);
    state = next;
  }
}

class _TicketOptimisticAssigneeOverrides
    extends fr.Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => <String, String>{};

  void setOverride(String ticketId, String assigneeId) {
    state = <String, String>{...state, ticketId: assigneeId};
  }

  void clearOverride(String ticketId) {
    final next = <String, String>{...state};
    next.remove(ticketId);
    state = next;
  }
}

// Tickets stream with filtering (status only; search is applied client-side)
@riverpod
Stream<List<Ticket>> ticketsStream(Ref ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  final filter = ref.watch(ticketFilterProvider);
  final overrides = ref.watch(ticketOptimisticStatusOverridesProvider);
  final assigneeOverrides = ref.watch(
    ticketOptimisticAssigneeOverridesProvider,
  );
  return repository.getTickets(statusFilter: filter).map((tickets) {
    if (overrides.isEmpty && assigneeOverrides.isEmpty) return tickets;
    return tickets.map((t) {
      final status = overrides[t.ticketId];
      final assigneeId = assigneeOverrides[t.ticketId];
      if (status == null && assigneeId == null) return t;
      return t.copyWith(
        status: status ?? t.status,
        assignedTo: assigneeId ?? t.assignedTo,
        updatedAt: DateTime.now(),
      );
    }).toList();
  });
}

// Unfiltered tickets stream (for Revenue page etc)
@riverpod
Stream<List<Ticket>> allTicketsStream(Ref ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  final overrides = ref.watch(ticketOptimisticStatusOverridesProvider);
  final assigneeOverrides = ref.watch(
    ticketOptimisticAssigneeOverridesProvider,
  );
  // Pass null to get all tickets regardless of filter
  return repository.getTickets(statusFilter: null).map((tickets) {
    if (overrides.isEmpty && assigneeOverrides.isEmpty) return tickets;
    return tickets.map((t) {
      final status = overrides[t.ticketId];
      final assigneeId = assigneeOverrides[t.ticketId];
      if (status == null && assigneeId == null) return t;
      return t.copyWith(
        status: status ?? t.status,
        assignedTo: assigneeId ?? t.assignedTo,
        updatedAt: DateTime.now(),
      );
    }).toList();
  });
}

// Get customer for a specific ticket (for AMC badge)
@riverpod
Future<Map<String, dynamic>?> ticketCustomer(Ref ref, String customerId) async {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getCustomer(customerId);
}

// Stats stream
@riverpod
Stream<Map<String, int>> ticketStats(Ref ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getTicketStats();
}

// Agents list provider
@riverpod
Future<List<Map<String, dynamic>>> agentsList(Ref ref) async {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getAgents();
}

// Get assigned agent for a ticket
@riverpod
Future<Map<String, dynamic>?> ticketAssignedAgent(
  Ref ref,
  String? agentId,
) async {
  if (agentId == null || agentId.isEmpty) return null;
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getAgent(agentId);
}

// Update ticket status
@riverpod
class TicketStatusUpdater extends _$TicketStatusUpdater {
  @override
  bool build() => false;

  Future<String?> updateStatus(String ticketId, String status) async {
    // Keep provider alive during async operation
    final link = ref.keepAlive();

    try {
      if (!ref.mounted) return 'Component not mounted';
      final currentUser = ref.read(authProvider);
      final canProcessBilling = currentUser?.isAccountant == true;
      final supabase = Supabase.instance.client;
      String? previousStatus;
      try {
        final before = await supabase
            .from('tickets')
            .select('status')
            .eq('id', ticketId)
            .single();
        previousStatus = before['status'] as String?;
      } catch (_) {}

      if (status == 'BillProcessed') {
        if (!canProcessBilling) {
          return 'Only accountants can mark tickets as billed';
        }
        if (previousStatus != 'Closed') {
          return 'Complete the ticket before billing it';
        }
      }

      if (!ref.mounted) return 'Component not mounted';
      ref
          .read(ticketOptimisticStatusOverridesProvider.notifier)
          .setOverride(ticketId, status);
      final repository = ref.read(ticketRepositoryProvider);
      final result = await repository.updateTicketStatus(ticketId, status);

      if (!ref.mounted) {
        return result.fold((l) => l.message, (r) => null);
      }

      if (result.isRight() && currentUser != null) {
        try {
          await supabase.from('audit_log').insert({
            'ticket_id': ticketId,
            'action': 'ticket_status_changed',
            'performed_by': currentUser.username,
            'payload': {
              'performed_by_id': currentUser.id,
              'performed_by_role': currentUser.role,
              'from': previousStatus,
              'to': status,
            },
          });
        } catch (_) {}
      }

      if (result.isRight() && ref.mounted) {
        ref.invalidate(ticketsStreamProvider);
        ref.invalidate(ticketStatsProvider);
        Timer(const Duration(seconds: 10), () {
          if (!ref.mounted) return;
          ref
              .read(ticketOptimisticStatusOverridesProvider.notifier)
              .clearOverride(ticketId);
        });
        return null;
      } else {
        if (ref.mounted) {
          ref
              .read(ticketOptimisticStatusOverridesProvider.notifier)
              .clearOverride(ticketId);
        }
        return result.fold((l) => l.message, (r) => null);
      }
    } finally {
      link.close();
    }
  }

  Future<bool> resolveAndBill(String ticketId, double amount) async {
    if (!ref.mounted) return false;

    // Optimistic update
    ref
        .read(ticketOptimisticStatusOverridesProvider.notifier)
        .setOverride(ticketId, 'BillRaised');

    final repository = ref.read(ticketRepositoryProvider);
    final result = await repository.resolveAndBillTicket(ticketId, amount);

    if (result.isRight() && ref.mounted) {
      ref.invalidate(ticketsStreamProvider);
      ref.invalidate(ticketStatsProvider);
      final currentUser = ref.read(authProvider);
      if (currentUser != null) {
        try {
          await Supabase.instance.client.from('audit_log').insert({
            'ticket_id': ticketId,
            'action': 'ticket_resolved_bill_raised',
            'performed_by': currentUser.username,
            'payload': {'performed_by_id': currentUser.id, 'amount': amount},
          });
        } catch (_) {}
      }

      Timer(const Duration(seconds: 10), () {
        if (!ref.mounted) return;
        ref
            .read(ticketOptimisticStatusOverridesProvider.notifier)
            .clearOverride(ticketId);
      });
    } else if (ref.mounted) {
      ref
          .read(ticketOptimisticStatusOverridesProvider.notifier)
          .clearOverride(ticketId);
    }

    return result.isRight();
  }
}

// Assign ticket to agent
@riverpod
class TicketAssigner extends _$TicketAssigner {
  @override
  bool build() => false;

  Future<bool> assignTicket(String ticketId, String assigneeId) async {
    final link = ref.keepAlive();
    final optimisticAssigneeOverrides = ref.read(
      ticketOptimisticAssigneeOverridesProvider.notifier,
    );
    final repository = ref.read(ticketRepositoryProvider);
    final currentUser = ref.read(authProvider);
    final supabase = Supabase.instance.client;
    try {
      try {
        final before = await supabase
            .from('tickets')
            .select('assigned_to')
            .eq('id', ticketId)
            .single();
        before['assigned_to'] as String?;
      } catch (_) {}

      if (!ref.mounted) return false;
      optimisticAssigneeOverrides.setOverride(ticketId, assigneeId);

      if (currentUser == null) {
        optimisticAssigneeOverrides.clearOverride(ticketId);
        return false;
      }

      final result = await repository.assignTicket(
        ticketId,
        assigneeId,
        assignedBy: currentUser.id,
      );

      if (!ref.mounted) return result.isRight();

      if (result.isRight() && ref.mounted) {
        ref.invalidate(ticketsStreamProvider);
        ref.invalidate(ticketStatsProvider);
        Timer(const Duration(seconds: 10), () {
          if (!ref.mounted) return;
          optimisticAssigneeOverrides.clearOverride(ticketId);
        });
      } else if (ref.mounted) {
        optimisticAssigneeOverrides.clearOverride(ticketId);
      }
      return result.isRight();
    } finally {
      link.close();
    }
  }
}

final ticketAssignmentHistoryProvider =
    fr.StreamProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      ticketId,
    ) {
      final supabase = Supabase.instance.client;
      return supabase
          .from('tickets')
          .stream(primaryKey: ['id'])
          .eq('id', ticketId)
          .limit(1)
          .map((rows) {
            if (rows.isEmpty) return <Map<String, dynamic>>[];
            final raw = rows.first['assignment_history'];
            if (raw is List) {
              return raw
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
            }
            return <Map<String, dynamic>>[];
          });
    });

final ticketFirstAssignedToProvider = fr.FutureProvider.family<String?, String>(
  (ref, ticketId) async {
    final supabase = Supabase.instance.client;
    try {
      final row = await supabase
          .from('tickets')
          .select('first_assigned_to')
          .eq('id', ticketId)
          .single();
      return row['first_assigned_to'] as String?;
    } catch (_) {
      return null;
    }
  },
);

// Create new ticket
@riverpod
class TicketCreator extends _$TicketCreator {
  @override
  bool build() => false;

  Future<bool> createTicket(Ticket ticket) async {
    final repository = ref.read(ticketRepositoryProvider);
    final result = await repository.createTicket(ticket);
    return result.isRight();
  }
}

// Update ticket
@riverpod
class TicketUpdater extends _$TicketUpdater {
  @override
  bool build() => false;

  Future<String?> updateTicket(Ticket ticket) async {
    final repository = ref.read(ticketRepositoryProvider);
    final result = await repository.updateTicket(ticket);

    return result.fold((l) => l.message, (r) {
      ref.invalidate(ticketsStreamProvider);
      ref.invalidate(allTicketsStreamProvider);
      return null;
    });
  }
}
