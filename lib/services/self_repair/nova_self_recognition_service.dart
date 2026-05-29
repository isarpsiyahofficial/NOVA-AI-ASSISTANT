// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_capability_descriptor.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import 'nova_capability_manifest_service.dart';
import 'nova_runtime_signal_service.dart';
import 'nova_self_repair_experience_service.dart';

class NovaSelfRecognitionService {
  final NovaRuntimeSignalService signalService;
  final NovaCapabilityManifestService manifestService;
  final NovaSelfRepairExperienceService experienceService =
      const NovaSelfRepairExperienceService();

  const NovaSelfRecognitionService({
    required this.signalService,
    required this.manifestService,
  });

  Future<List<NovaCapabilityDescriptor>> discoverCapabilities() async {
    final signals = await signalService.getAll();
    final manifest = await manifestService.loadManifest();
    final Map<String, List<NovaRuntimeSignal>> grouped =
        <String, List<NovaRuntimeSignal>>{};

    for (final signal in signals) {
      final capabilityId = _capabilityIdFor(signal);
      grouped.putIfAbsent(capabilityId, () => <NovaRuntimeSignal>[]);
      grouped[capabilityId]!.add(signal);
    }

    final List<NovaCapabilityDescriptor> descriptors = manifest
        .map(
          (entry) => NovaCapabilityDescriptor(
            capabilityId: entry.capabilityId,
            title: entry.title,
            humanSummary: entry.humanSummary,
            technicalSummary: entry.technicalSummary,
            selfRepairAllowed: entry.selfRepairAllowed,
            ownerPatchAllowed: entry.ownerPatchAllowed,
            signalCodes: entry.signalCodes,
            discoveredAt: DateTime.now(),
            inferredFromSignals: false,
          ),
        )
        .toList(growable: true);

    for (final entry in grouped.entries) {
      if (descriptors.any((e) => e.capabilityId == entry.key)) {
        continue;
      }

      final latest = entry.value.first;
      descriptors.add(
        NovaCapabilityDescriptor(
          capabilityId: entry.key,
          title: _titleFor(entry.key),
          humanSummary: _humanSummaryFor(entry.key),
          technicalSummary: 'Sinyal tabanlı güvenli keşif ile bulundu.',
          selfRepairAllowed: entry.value.any((e) => e.diagnosticCandidate),
          ownerPatchAllowed: false,
          signalCodes: entry.value
              .map((NovaRuntimeSignal e) => e.code)
              .toSet()
              .toList(growable: false),
          discoveredAt: latest.createdAt,
          inferredFromSignals: true,
        ),
      );
    }

    descriptors.sort((a, b) => a.title.compareTo(b.title));
    return descriptors;
  }

  Map<String, dynamic> buildSelfKnowledgeHints(
    String issueCode, {
    List<Map<String, dynamic>> history = const <Map<String, dynamic>>[],
  }) {
    final card = experienceService.buildCard(
      issueCode: issueCode,
      history: history,
    );
    final plan = experienceService.buildRepairPlan(
      issueCode: issueCode,
      subsystem: 'self_recognition',
      card: card,
      canSelfRepair: true,
      ownerPatchAllowed: true,
    );
    return <String, dynamic>{
      'card': <String, dynamic>{
        'issueCode': card.issueCode,
        'attempts': card.attempts,
        'successes': card.successes,
        'failures': card.failures,
        'confidence': card.confidence,
      },
      'plan': plan,
    };
  }

  String _capabilityIdFor(NovaRuntimeSignal signal) {
    switch (signal.kind) {
      case NovaRuntimeSignalKind.voiceIdentity:
      case NovaRuntimeSignalKind.authorization:
        return 'voice_identity';
      case NovaRuntimeSignalKind.stt:
        return 'speech_understanding';
      case NovaRuntimeSignalKind.tts:
        return 'speech_response';
      case NovaRuntimeSignalKind.background:
        return 'listening_runtime';
      case NovaRuntimeSignalKind.call:
      case NovaRuntimeSignalKind.callCompanion:
        return 'call_companion';
      case NovaRuntimeSignalKind.ai:
      case NovaRuntimeSignalKind.localModel:
      case NovaRuntimeSignalKind.api:
        return 'ai_response';
      case NovaRuntimeSignalKind.reminder:
        return 'reminder_runtime';
      default:
        return 'misc_${signal.kind.name}';
    }
  }

  String _titleFor(String capabilityId) {
    switch (capabilityId) {
      case 'voice_identity':
        return 'Ses Kimliği';
      case 'speech_understanding':
        return 'Konuşmayı Anlama';
      case 'speech_response':
        return 'Konuşarak Cevaplama';
      case 'listening_runtime':
        return 'Dinleme Runtime';
      case 'call_companion':
        return 'Çağrı Companion';
      case 'ai_response':
        return 'AI Cevap Üretimi';
      case 'reminder_runtime':
        return 'Hatırlatıcı Runtime';
      case 'contacts_runtime':
        return 'Kişiler ve Rehber';
      case 'dashboard_ui':
        return 'Gösterge Paneli';
      case 'debug_runtime':
        return 'Hata Ayıklama';
      case 'personality_runtime':
        return 'Kişilik ve Konuşma Tarzı';
      case 'knowledge_guides':
        return 'Bilgi Çekirdeği ve Rehberler';
      case 'power_modes':
        return 'Güç Modları';
      case 'call_instruction_runtime':
        return 'Talimatlı Çağrılar';
      case 'permissions_runtime':
        return 'İzin Zinciri';
      case 'media_control':
        return 'Medya Kontrolü';
      case 'call_systems':
        return 'Çağrı Sistemleri';
      default:
        return capabilityId.replaceAll('_', ' ').trim();
    }
  }

  String _humanSummaryFor(String capabilityId) {
    switch (capabilityId) {
      case 'voice_identity':
        return 'Ses tanıma ve yetki ayrımı.';
      case 'speech_understanding':
        return 'Konuşmayı duyma, metne çevirme ve anlama zinciri.';
      case 'speech_response':
        return 'Konuşarak cevap verme ve TTS zinciri.';
      case 'listening_runtime':
        return 'Dinleme, uyandırma ve arka plan davranışı.';
      case 'call_companion':
        return 'Çağrı sırasında devralma ve konuşma akışı.';
      case 'ai_response':
        return 'Komut işleme ve cevap üretimi.';
      case 'reminder_runtime':
        return 'Hatırlatıcı tetikleme ve konuşma akışı.';
      case 'contacts_runtime':
        return 'Rehber eşitleme, kişi ekleme ve çağrı yetki zinciri.';
      case 'dashboard_ui':
        return 'Ana panel görünümü, düğmeler ve yönlendirme akışı.';
      case 'debug_runtime':
        return 'Hata ayıklama ve derin tarama akışı.';
      case 'personality_runtime':
        return 'Kişilik, şaka dozu ve konuşma sıcaklığı ayarları.';
      case 'knowledge_guides':
        return 'Yerel bilgi çekirdeği ve rehber kaynakları.';
      case 'power_modes':
        return 'Güç modları ve planlı uyku davranışı.';
      case 'call_instruction_runtime':
        return 'Planlı ve anlık çağrı talimatları.';
      case 'permissions_runtime':
        return 'Overlay, mikrofon, bildirim ve erişilebilirlik izin akışı.';
      case 'media_control':
        return 'İzinli medya uygulamaları üzerinden yürüyen kontrol akışı.';
      case 'call_systems':
        return 'Çağrı kontrolü, companion ve devralma sistemi.';
      default:
        return 'Sinyallerden keşfedilmiş sistem alanı.';
    }
  }

  Map<String, dynamic> buildSelfKnowledgeAudit(
    String issueCode, {
    List<Map<String, dynamic>> history = const <Map<String, dynamic>>[],
  }) {
    final hints = buildSelfKnowledgeHints(issueCode, history: history);
    return <String, dynamic>{
      'issueCode': issueCode,
      'capabilityId': hints['capabilityId'] ?? '',
      'summary': hints['summary'] ?? '',
      'confidence': hints['confidence'] ?? 0.0,
      'historySize': history.length,
    };
  }

  double buildRepairReadinessScore(
    String issueCode, {
    List<Map<String, dynamic>> history = const <Map<String, dynamic>>[],
  }) {
    final hints = buildSelfKnowledgeHints(issueCode, history: history);
    final confidence = (hints['confidence'] as num?)?.toDouble() ?? 0.0;
    final hasPatch = (hints['recommendedPatch'] ?? '')
        .toString()
        .trim()
        .isNotEmpty;
    return (confidence + (hasPatch ? 0.18 : 0.0)).clamp(0.0, 1.0);
  }

  List<String> buildCapabilitySummary() {
    return const <String>[
      'ses_tanıma',
      'konuşma_anlama',
      'çağrı_companion',
      'dashboard_ui',
      'güç_modları',
      'izin_ve_güvenlik',
      'yerel_bilgi_rehberi',
      'medya_kontrol',
    ];
  }
}
