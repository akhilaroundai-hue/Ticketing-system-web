import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';

part 'customer_provider.g.dart';

// Get customer by ID
@riverpod
Future<Customer?> customer(Ref ref, String customerId) async {
  final repository = ref.watch(ticketRepositoryProvider);
  final customerData = await repository.getCustomer(customerId);

  if (customerData == null) return null;
  return Customer.fromJson(customerData);
}

// Get AMC stats for dashboard
@riverpod
Future<Map<String, int>> amcStats(Ref ref) async {
  try {
    final response = await Supabase.instance.client
        .from('customers')
        .select('amc_expiry_date');

    int active = 0;
    int expired = 0;
    final now = DateTime.now();

    for (var customer in response) {
      final amcDate = customer['amc_expiry_date'];
      if (amcDate != null) {
        final expiry = DateTime.parse(amcDate);
        if (expiry.isAfter(now)) {
          active++;
        } else {
          expired++;
        }
      }
    }

    return {'active': active, 'expired': expired};
  } catch (e) {
    return {'active': 0, 'expired': 0};
  }
}

// Get all customers for listing
@riverpod
Future<List<Customer>> customersList(Ref ref) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('customers')
      .select()
      .order('company_name');

  return (response as List<dynamic>)
      .map((item) => Customer.fromJson(item as Map<String, dynamic>))
      .toList();
}
