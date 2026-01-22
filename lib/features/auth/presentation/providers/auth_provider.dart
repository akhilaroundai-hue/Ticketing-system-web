import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/logging/app_logger.dart';

part 'auth_provider.g.dart';

// Agent model for custom auth
class Agent {
  final String id;
  final String username;
  final String fullName;
  final String role;

  Agent({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      role: json['role'],
    );
  }
  String get _roleLower => role.toLowerCase();

  bool get isAdmin => _roleLower == 'admin';
  bool get isSupportHead =>
      _roleLower == 'support head' || _roleLower == 'support_head';
  bool get isAccountant => _roleLower == 'accountant';
  bool get isSupport => _roleLower == 'support';
  bool get isAgent => _roleLower == 'agent';
  bool get isSales => _roleLower == 'sales' || _roleLower == 'salesperson';
}

// Auth state notifier
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Agent? build() => null;

  Future<bool> login(String username, String password) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'login_agent',
        params: {'p_username': username, 'p_password': password},
      );

      if (response is! Map<String, dynamic>) {
        appLogger.warning(
          'Login RPC returned unexpected payload',
          context: {
            'username': username,
            'payloadType': response.runtimeType.toString(),
          },
        );
        return false;
      }

      if (response['success'] == true && response['agent'] is Map) {
        state = Agent.fromJson(
          Map<String, dynamic>.from(response['agent'] as Map),
        );
        return true;
      }

      appLogger.info(
        'Login RPC returned failure response',
        context: {'username': username, 'response': response},
      );
      return false;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Login error: $e');
      }
      appLogger.error(
        'Login failed',
        error: e,
        stackTrace: stackTrace,
        context: {'username': username},
      );
      return false;
    }
  }

  void logout() {
    state = null;
  }
}
