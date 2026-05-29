// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_capability_manifest_entry.dart';
import 'nova_capability_runtime_registry_service.dart';

class NovaCapabilityManifestService {
  final NovaCapabilityRuntimeRegistryService? runtimeRegistryService;

  const NovaCapabilityManifestService({this.runtimeRegistryService});

  Future<List<NovaCapabilityManifestEntry>> loadManifest() async {
    final base = <NovaCapabilityManifestEntry>[
      const NovaCapabilityManifestEntry(
        capabilityId: 'voice_identity',
        title: 'Ses Kimliği',
        humanSummary: 'Sahip ve yetkili sesleri tanıma zinciri.',
        technicalSummary: 'voice identity runtime + authorization handoff',
        selfRepairAllowed: false,
        ownerPatchAllowed: false,
        tags: <String>['voice', 'identity', 'authorization'],
        signalCodes: <String>[
          'voice_identity_capture_failed',
          'voice_identity_no_match',
        ],
        restartTargets: <String>['ttsStt'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'setup_lifecycle',
        title: 'Setup Yaşam Döngüsü',
        humanSummary:
            'İlk kurulum ekranı, setup mikrofonu, TTS anlatımı ve adım ilerleme zinciri.',
        technicalSummary:
            'first run setup lifecycle + setup ASR/TTS boot bridge',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['setup', 'boot', 'diagnostic'],
        signalCodes: <String>[
          'setup_start_flow_error',
          'setup_asr_not_ready',
          'setup_asr_start_failed',
          'setup_asr_snapshot_failed',
          'setup_asr_restart_listen_failed',
          'setup_authorization_guard_wait',
          'setup_tts_speak_error',
          'setup_tts_status_error',
          'setup_boot_narration_tts_error',
          'setup_owner_voice_enroll_failed',
        ],
        restartTargets: <String>['ttsStt', 'backgroundOverlay'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'local_model_boot',
        title: 'Yerel Model Boot',
        humanSummary:
            'Setup sırasında yerel model dosyası, Brain Kernel ve mikro inference kanıt zinciri.',
        technicalSummary:
            'local model prepare + brain kernel first-token proof + setup micro response',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['setup', 'local_model', 'hotpath'],
        signalCodes: <String>[
          'setup_brain_kernel_critical',
          'setup_opening_micro_response_failed',
        ],
        restartTargets: <String>['ttsStt'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'speech_understanding',
        title: 'Konuşmayı Anlama',
        humanSummary: 'STT, dinleme ve komut çözümleme zinciri.',
        technicalSummary: 'speech capture + STT + command interpretation',
        selfRepairAllowed: true,
        ownerPatchAllowed: true,
        tags: <String>['speech', 'understanding', 'stt'],
        signalCodes: <String>[
          'stt_unavailable',
          'speech_understanding_degraded',
        ],
        restartTargets: <String>['continuousListening', 'ttsStt'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'speech_response',
        title: 'Konuşarak Cevaplama',
        humanSummary: 'TTS ve konuşma çıktısı zinciri.',
        technicalSummary: 'tts runtime + spoken response pipeline',
        selfRepairAllowed: true,
        ownerPatchAllowed: true,
        tags: <String>['speech', 'response', 'tts'],
        signalCodes: <String>['tts_unavailable', 'speech_response_degraded'],
        restartTargets: <String>['ttsStt'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'listening_runtime',
        title: 'Dinleme Runtime',
        humanSummary: 'Pasif/aktif dinleme, wake ve arka plan ses zinciri.',
        technicalSummary:
            'continuous listening + wake gating + background overlay',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['listening', 'background'],
        signalCodes: <String>[
          'background_overlay_permission_missing',
          'background_bridge_failed',
        ],
        restartTargets: <String>['continuousListening', 'backgroundOverlay'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'call_companion',
        title: 'Çağrı Companion',
        humanSummary: 'Çağrı sırasında devralma ve konuşma akışı.',
        technicalSummary:
            'call state + call control + companion runtime + TTS/STT',
        selfRepairAllowed: false,
        ownerPatchAllowed: false,
        tags: <String>['call', 'companion', 'speaker', 'mic'],
        signalCodes: <String>[
          'call_companion_start_failed',
          'call_companion_authorization_failed',
        ],
        restartTargets: <String>['companion', 'ttsStt'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'ai_response',
        title: 'AI Cevap Üretimi',
        humanSummary: 'API-first beyin ve izinli inference akışı.',
        technicalSummary: 'ai request validation + local inference route',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['ai', 'model', 'response'],
        signalCodes: <String>[
          'local_model_empty_response',
          'api_not_configured',
        ],
        restartTargets: <String>['ttsStt'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'permissions_runtime',
        title: 'İzin Zinciri',
        humanSummary:
            'Overlay, erişilebilirlik, bildirim ve mikrofon izinleri.',
        technicalSummary: 'android permissions + settings bridge',
        selfRepairAllowed: true,
        ownerPatchAllowed: true,
        tags: <String>['permissions', 'overlay', 'microphone'],
        signalCodes: <String>['background_overlay_permission_missing'],
        restartTargets: <String>['backgroundOverlay'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'media_control',
        title: 'Medya Kontrolü',
        humanSummary: 'Spotify ve YouTube Music medya kontrol zinciri.',
        technicalSummary: 'media control + phone control bridge',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['media', 'phone_control'],
        signalCodes: <String>['phone_control_restricted'],
        restartTargets: <String>['backgroundOverlay'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'call_systems',
        title: 'Çağrı Sistemleri',
        humanSummary: 'Çağrı kontrolü, companion ve talimatlı çağrı zinciri.',
        technicalSummary: 'call control + companion + instruction runtime',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['call', 'companion'],
        signalCodes: <String>['call_answer_failed'],
        restartTargets: <String>['continuousListening', 'backgroundOverlay'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'reminder_runtime',
        title: 'Hatırlatıcı Runtime',
        humanSummary: 'Vadesi gelen hatırlatıcıların çalıştırılması.',
        technicalSummary:
            'reminder runtime + due check + spoken reminder bridge',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['reminder', 'scheduler'],
        signalCodes: <String>['reminder_due_check_failed'],
        restartTargets: <String>['reminderRuntime'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'self_repair_runtime',
        title: 'Onarım Runtime',
        humanSummary: 'Kendini tanıma, teşhis, doğrulama ve onarım zinciri.',
        technicalSummary:
            'self repair coordinator + diagnostic + validation + report',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['self_repair', 'debug'],
        signalCodes: <String>[
          'self_repair_runtime_failed',
          'self_repair_validation_failed',
        ],
        restartTargets: <String>['continuousListening'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'contacts_runtime',
        title: 'Kişiler ve Rehber',
        humanSummary: 'Rehberden alma, kişi ekleme ve çağrı yetkisi zinciri.',
        technicalSummary:
            'device contacts bridge + contact storage + authority sync',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['contacts', 'call_authority'],
        signalCodes: <String>['contacts_bridge_failed', 'contacts_sync_failed'],
        restartTargets: <String>['continuousListening'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'dashboard_ui',
        title: 'Gösterge Paneli',
        humanSummary: 'Ana panel, mod düğmeleri ve etkileşim görünümü.',
        technicalSummary: 'dashboard widgets + power controls + navigation',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['dashboard', 'ui'],
        signalCodes: <String>[
          'dashboard_render_degraded',
          'dashboard_navigation_failed',
        ],
        restartTargets: <String>['backgroundOverlay'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'debug_runtime',
        title: 'Hata Ayıklama',
        humanSummary: 'Teşhis, tarama ve sistem özeti üretimi.',
        technicalSummary: 'debug mode + capability catalog + diagnostic scan',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['debug', 'diagnostic'],
        signalCodes: <String>['debug_runtime_failed', 'diagnostic_scan_failed'],
        restartTargets: <String>['continuousListening'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'personality_runtime',
        title: 'Kişilik ve Konuşma Tarzı',
        humanSummary: 'Kişilik ayarları, mizah ve konuşma sıcaklığı zinciri.',
        technicalSummary: 'personality settings + prompt guide + spoken style',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['personality', 'tts'],
        signalCodes: <String>[
          'personality_settings_failed',
          'speech_style_degraded',
        ],
        restartTargets: <String>['ttsStt'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'knowledge_guides',
        title: 'Bilgi Çekirdeği ve Rehberler',
        humanSummary: 'Yerel bilgi kütüphanesi ve rehber kaynakları.',
        technicalSummary:
            'offline knowledge library + guide sources + language packs',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['knowledge', 'guides'],
        signalCodes: <String>[
          'knowledge_library_unavailable',
          'language_pack_missing',
        ],
        restartTargets: <String>['ttsStt'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'power_modes',
        title: 'Güç Modları',
        humanSummary: 'Tam güç, tasarruf, gece, araf ve kapanış zinciri.',
        technicalSummary: 'power service + schedule + wake gating',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['power', 'schedule'],
        signalCodes: <String>[
          'power_mode_switch_failed',
          'power_schedule_failed',
        ],
        restartTargets: <String>['continuousListening', 'backgroundOverlay'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'call_instruction_runtime',
        title: 'Talimatlı Çağrılar',
        humanSummary:
            'Anlık ve planlı çağrı talimatlarının kayıt ve yürütme zinciri.',
        technicalSummary:
            'call instruction storage + parser + dashboard summary',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['call', 'instruction'],
        signalCodes: <String>[
          'call_instruction_parse_failed',
          'call_instruction_storage_failed',
        ],
        restartTargets: <String>['reminderRuntime'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'overlay_background',
        title: 'Overlay ve Arka Plan',
        humanSummary: 'Overlay görünürlüğü ve arka plan köprüleri.',
        technicalSummary:
            'overlay idle/show/hide + background sleeping/wake bridge',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['overlay', 'background'],
        signalCodes: <String>[
          'overlay_bridge_failed',
          'background_bridge_failed',
        ],
        restartTargets: <String>['backgroundOverlay'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'memory_runtime',
        title: 'Hafıza ve Konuşma Geçmişi',
        humanSummary:
            'Geçici konuşma geçmişi, kalıcı hafıza ve temizlik zinciri.',
        technicalSummary:
            'conversation session + memory storage + cleanup runtime',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['memory', 'conversation'],
        signalCodes: <String>[
          'memory_runtime_failed',
          'conversation_cleanup_failed',
        ],
        restartTargets: <String>['continuousListening'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'phone_control_runtime',
        title: 'Telefon ve Medya Yönetimi',
        humanSummary:
            'Çağrı başlatma, medya tuşları ve ekran otomasyonu zinciri.',
        technicalSummary:
            'phone control bridge + accessibility automation + telecom handoff',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['phone_control', 'media', 'telecom'],
        signalCodes: <String>[
          'phone_control_restricted',
          'dashboard_navigation_failed',
        ],
        restartTargets: <String>['backgroundOverlay'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'call_notes_runtime',
        title: 'Çağrı Notları',
        humanSummary: 'Çağrı sırasında not alma ve temizleme zinciri.',
        technicalSummary: 'call note capture + storage + retention cleanup',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['call', 'notes'],
        signalCodes: <String>['call_instruction_storage_failed'],
        restartTargets: <String>['continuousListening'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'learning_runtime',
        title: 'Öğrenme ve Davranış Katmanı',
        humanSummary:
            'Öğretilen davranışlar, uyarlamalı talimatlar ve kayıt zinciri.',
        technicalSummary:
            'adaptive instruction + learning registry + behavior overrides',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['learning', 'behavior'],
        signalCodes: <String>[
          'speech_understanding_degraded',
          'personality_settings_failed',
        ],
        restartTargets: <String>['continuousListening', 'ttsStt'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'dialogue_runtime',
        title: 'Diyalog ve Konuşma Sırası',
        humanSummary: 'Turn manager, dialogue policy ve sohbet akışı zinciri.',
        technicalSummary:
            'turn manager + dialogue policy + state machine + repair loop',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['dialogue', 'turns', 'conversation'],
        signalCodes: <String>[
          'speech_understanding_degraded',
          'local_model_empty_response',
        ],
        restartTargets: <String>['continuousListening', 'ttsStt'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'speaker_priority_runtime',
        title: 'Konuşmacı Önceliği ve Ses Sürekliliği',
        humanSummary:
            'Sesi yeniden yetki kontrolünden ziyade kimin konuştuğunu ayırma zinciri.',
        technicalSummary:
            'voice identity continuity + trusted session + speaker priority reuse',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['voice', 'priority', 'continuity'],
        signalCodes: <String>[
          'voice_identity_no_match',
          'speech_understanding_degraded',
        ],
        restartTargets: <String>['continuousListening'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'family_contacts_runtime',
        title: 'Aile Ağacı ve İlişki Modeli',
        humanSummary:
            'Anne, baba, eş, abi, abla ve kardeş gibi ilişki rol zinciri.',
        technicalSummary:
            'contacts role normalization + companion relationship speech + incoming call labels',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['contacts', 'family', 'relationship'],
        signalCodes: <String>[
          'contacts_sync_failed',
          'call_companion_start_failed',
        ],
        restartTargets: <String>['continuousListening'],
      ),
      const NovaCapabilityManifestEntry(
        capabilityId: 'self_recognition_runtime',
        title: 'Kendini Tanıma',
        humanSummary:
            'Novain sistemlerini keşfetme ve sağlık özeti çıkarma zinciri.',
        technicalSummary:
            'capability manifest + runtime registry + self recognition',
        selfRepairAllowed: true,
        ownerPatchAllowed: false,
        tags: <String>['self_recognition', 'diagnostic'],
        signalCodes: <String>['diagnostic_scan_failed', 'debug_runtime_failed'],
        restartTargets: <String>['continuousListening'],
      ),
    ];

    final registered =
        await runtimeRegistryService?.loadRegisteredCapabilities() ??
        const <NovaCapabilityManifestEntry>[];
    final merged = <String, NovaCapabilityManifestEntry>{
      for (final item in base) item.capabilityId: item,
      for (final item in registered) item.capabilityId: item,
    };
    return merged.values.toList(growable: false);
  }
}
