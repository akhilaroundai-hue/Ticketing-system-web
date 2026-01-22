import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'ticket_remarks_provider.g.dart';

// Stream of remarks for a ticket
@riverpod
Stream<List<Map<String, dynamic>>> ticketRemarks(Ref ref, String ticketId) {
  final supabase = Supabase.instance.client;
  return supabase
      .from('ticket_remarks')
      .stream(primaryKey: ['id'])
      .eq('ticket_id', ticketId)
      .order('created_at', ascending: false)
      .map((list) => List<Map<String, dynamic>>.from(list));
}

// Add remark to ticket
@riverpod
class TicketRemarksAdder extends _$TicketRemarksAdder {
  @override
  bool build() => false;

  Future<bool> addRemark({
    required String ticketId,
    required String agentId,
    required String remark,
    String? stage,
  }) async {
    if (!ref.mounted) return false;
    state = true;
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('ticket_remarks').insert({
        'ticket_id': ticketId,
        'agent_id': agentId,
        'remark': remark,
        'remark_type': 'text',
        'stage': stage,
      });

      if (ref.mounted) {
        ref.invalidate(ticketRemarksProvider(ticketId));
      }
      // Insert succeeded - update state only if still mounted
      if (ref.mounted) {
        state = false;
      }
      return true; // Return true since insert succeeded
    } catch (e) {
      if (ref.mounted) {
        state = false;
      }
      return false;
    }
  }
}
