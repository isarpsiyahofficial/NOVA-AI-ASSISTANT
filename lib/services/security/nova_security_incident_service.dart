// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/security/nova_native_security_snapshot.dart';
import '../../core/security/nova_security_incident.dart';
import 'nova_native_security_bridge_service.dart';

class NovaSecurityIncidentState {
  final String riskLevel;
  final String nativeKillStage;
  final String statusText;
  final String nativeMessage;
  final List<NovaSecurityIncident> incidents;
  final bool hasHighRisk;
  final bool hasCriticalRisk;
  final bool hasMediumRisk;

  const NovaSecurityIncidentState({
    required this.riskLevel,
    required this.nativeKillStage,
    required this.statusText,
    required this.nativeMessage,
    required this.incidents,
    required this.hasHighRisk,
    required this.hasCriticalRisk,
    required this.hasMediumRisk,
  });

  factory NovaSecurityIncidentState.safe() {
    return const NovaSecurityIncidentState(
      riskLevel: 'Yok',
      nativeKillStage: 'none',
      statusText: 'Güvenlik aktif. Katman 4 ve üstü şüpheli hareket bulunmadı.',
      nativeMessage: '',
      incidents: <NovaSecurityIncident>[],
      hasHighRisk: false,
      hasCriticalRisk: false,
      hasMediumRisk: false,
    );
  }
}

class NovaSecurityIncidentService {
  static const String _storageKey = 'nova_security_incidents_v1';
  static const Duration _keepDuration = Duration(hours: 48);

  final NovaNativeSecurityBridgeService nativeBridgeService;

  const NovaSecurityIncidentService({required this.nativeBridgeService});

  Future<List<NovaSecurityIncident>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.trim().isEmpty) {
        return const <NovaSecurityIncident>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <NovaSecurityIncident>[];
      }

      final items = decoded
          .whereType<Map>()
          .map(
            (e) => NovaSecurityIncident.fromMap(Map<String, dynamic>.from(e)),
          )
          .where((e) => e.id.isNotEmpty)
          .toList(growable: false);

      return _sortAndTrim(items);
    } catch (_) {
      return const <NovaSecurityIncident>[];
    }
  }

  Future<void> _save(List<NovaSecurityIncident> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        _sortAndTrim(items).map((e) => e.toMap()).toList(growable: false),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      // Sessiz fallback
    }
  }

  List<NovaSecurityIncident> _sortAndTrim(List<NovaSecurityIncident> items) {
    final sorted = items.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final now = DateTime.now();
    return sorted
        .where((e) {
          final age = now.difference(e.createdAt);
          return age <= _keepDuration;
        })
        .toList(growable: false);
  }

  String _normalizeRiskLabel(String raw) {
    final value = raw.trim().toLowerCase();

    switch (value) {
      case 'critical':
      case 'kritik':
        return 'Kritik';
      case 'high':
      case 'yüksek':
        return 'Yüksek';
      case 'medium':
      case 'orta':
        return 'Orta';
      case 'low':
      case 'düşük':
        return 'Düşük';
      case 'safe':
      case 'güvenli':
      default:
        return 'Yok';
    }
  }

  bool _isMedium(String raw) {
    final value = raw.trim().toLowerCase();
    return value == 'medium' || value == 'orta';
  }

  bool _isHigh(String raw) {
    final value = raw.trim().toLowerCase();
    return value == 'high' || value == 'yüksek';
  }

  bool _isCritical(String raw) {
    final value = raw.trim().toLowerCase();
    return value == 'critical' || value == 'kritik';
  }

  String _buildStatusText({
    required String riskLabel,
    required List<NovaSecurityIncident> incidents,
    required NovaNativeSecuritySnapshot snapshot,
  }) {
    if (incidents.isEmpty && !snapshot.hasLevel4OrHigherIncident) {
      return 'Güvenlik aktif. Katman 4 ve üstü şüpheli hareket bulunmadı.';
    }

    if (snapshot.killStage.trim().isNotEmpty &&
        snapshot.killStage.trim() != 'none') {
      return 'Containment aktif. Native kill stage: ${snapshot.killStage}';
    }

    return 'Şüpheli hareket raporu mevcut. Güncel risk seviyesi: $riskLabel.';
  }

  Future<NovaSecurityIncidentState> refreshState({
    bool vibrateIfHighRisk = false,
  }) async {
    await cleanupExpiredReports();

    final snapshot = await nativeBridgeService.getSnapshot();
    final existing = await _load();
    final List<NovaSecurityIncident> next = existing.toList(growable: true);

    final String riskLabel = _normalizeRiskLabel(snapshot.currentRiskLevel);
    final bool hasLevel4OrHigher = snapshot.hasLevel4OrHigherIncident;

    if (hasLevel4OrHigher) {
      final incident = NovaSecurityIncident(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: 'Şüpheli hareket raporu',
        description: snapshot.message.trim().isEmpty
            ? 'Katman 4 ve üzeri şüpheli hareket algılandı.'
            : snapshot.message.trim(),
        riskLevel: snapshot.currentRiskLevel.trim().isEmpty
            ? 'unknown'
            : snapshot.currentRiskLevel.trim(),
        killStage: snapshot.killStage.trim().isEmpty
            ? 'none'
            : snapshot.killStage.trim(),
        userInitiated: snapshot.userInitiated,
        modelResetSuggested: snapshot.modelResetSuggested,
        memoryResetSuggested: snapshot.memoryResetSuggested,
        createdAt: DateTime.now(),
      );

      final bool isDuplicate = next.any((e) {
        final closeInTime =
            DateTime.now().difference(e.createdAt).inMinutes.abs() <= 2;
        return e.description == incident.description &&
            e.killStage == incident.killStage &&
            e.riskLevel == incident.riskLevel &&
            closeInTime;
      });

      if (!isDuplicate) {
        next.add(incident);
      }
    }

    await _save(next);
    final incidents = await _load();

    final bool hasCritical = incidents.any((e) => _isCritical(e.riskLevel));
    final bool hasHigh =
        hasCritical || incidents.any((e) => _isHigh(e.riskLevel));
    final bool hasMedium =
        !hasHigh && incidents.any((e) => _isMedium(e.riskLevel));

    if (vibrateIfHighRisk &&
        incidents.isNotEmpty &&
        (hasHigh || snapshot.shouldVibrate)) {
      await nativeBridgeService.vibrateIfNeeded();
    }

    return NovaSecurityIncidentState(
      riskLevel: riskLabel,
      nativeKillStage: snapshot.killStage.trim().isEmpty
          ? 'none'
          : snapshot.killStage.trim(),
      statusText: _buildStatusText(
        riskLabel: riskLabel,
        incidents: incidents,
        snapshot: snapshot,
      ),
      nativeMessage: snapshot.message,
      incidents: incidents,
      hasHighRisk: hasHigh,
      hasCriticalRisk: hasCritical,
      hasMediumRisk: hasMedium,
    );
  }

  Future<void> cleanupExpiredReports() async {
    final items = await _load();
    await _save(items);
  }

  Future<List<NovaSecurityIncident>> getAllReports() async {
    await cleanupExpiredReports();
    return _load();
  }

  Future<void> clearAllReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {
      // Sessiz fallback
    }
  }
}
