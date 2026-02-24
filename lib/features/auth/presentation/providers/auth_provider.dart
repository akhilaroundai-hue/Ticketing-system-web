import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'role': role,
    };
  }
  String get _roleLower => role.trim().toLowerCase();

  bool get isAdmin => _roleLower == 'admin';
  bool get isSupportHead =>
      _roleLower == 'support head' ||
      _roleLower == 'support_head' ||
      _roleLower == 'supporthead' ||
      _roleLower == 'support-head';
  bool get isAccountant => _roleLower == 'accountant';
  bool get isSupport => _roleLower == 'support';
  bool get isAgent => _roleLower == 'agent';
  bool get isSales => _roleLower == 'sales' || _roleLower == 'salesperson';
}

// Auth state notifier
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  static const _agentPrefsKey = 'auth.agent';
  static const _requestTimeout = Duration(seconds: 6);
  static const _overallTimeout = Duration(seconds: 10);

  @override
  Agent? build() => null;

  Future<bool> login(String username, String password) async {
    final sanitizedUsername = username.trim();
    final sanitizedPassword = password.trim();

    try {
      return await _loginInternal(
        sanitizedUsername,
        sanitizedPassword,
      ).timeout(
        _overallTimeout,
        onTimeout: () {
          appLogger.warning(
            'Login overall timed out',
            context: {'username': sanitizedUsername},
          );
          return false;
        },
      );
    } on TimeoutException catch (e, stackTrace) {
      appLogger.error(
        'Login timed out',
        error: e,
        stackTrace: stackTrace,
        context: {'username': sanitizedUsername},
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
        context: {'username': sanitizedUsername},
      );
      return false;
    }
  }

  Future<bool> _loginInternal(String username, String password) async {
    final client = Supabase.instance.client;

    // Fast-path: direct table lookup is faster than RPC and avoids server-side function latency.
    Map<String, dynamic>? agentRow;
    try {
      agentRow = await client
          .from('agents')
          .select('id, username, full_name, role')
          .eq('username', username)
          .eq('password', password)
          .limit(1)
          .maybeSingle()
          .timeout(_requestTimeout);
    } on TimeoutException catch (_) {
      appLogger.warning(
        'Direct agent lookup timed out; skipping RPC fallback',
        context: {'username': username},
      );
      return false;
    }

    if (agentRow != null) {
      state = Agent.fromJson(agentRow);
      await _persistAgent(state!);
      return true;
    }

    final response = await client
        .rpc(
          'login_agent',
          params: {
            'p_username': username,
            'p_password': password,
          },
        )
        .timeout(_requestTimeout);

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
      await _persistAgent(state!);
      return true;
    }

    appLogger.info(
      'Login RPC returned failure response',
      context: {'username': username, 'response': response},
    );
    return false;
  }

  void logout() {
    state = null;
    _clearPersistedAgent();
  }

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serializedAgent = prefs.getString(_agentPrefsKey);
      if (serializedAgent == null) {
        return;
      }

      final decoded = jsonDecode(serializedAgent);
      if (decoded is! Map<String, dynamic>) {
        await prefs.remove(_agentPrefsKey);
        return;
      }
      state = Agent.fromJson(decoded);
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to restore persisted session',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _persistAgent(Agent agent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_agentPrefsKey, jsonEncode(agent.toJson()));
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to persist agent session',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _clearPersistedAgent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_agentPrefsKey);
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to clear persisted agent session',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
