// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals_to_create_immutables
// NOVA_API_FIRST_SETTINGS_V1
import '../api/nova_ai_provider_type.dart';
import '../api/nova_api_model_catalog.dart';

class NovaSettings {
  final double speechRate;
  final double speechPitch;
  final bool chatGptInternetEnabled;
  final bool teachingModeEnabled;
  final bool apiLearningEnabled;
  final String apiKey;
  final NovaAiProviderType activeAiProvider;
  final String activeApiModel;
  final bool apiBrainEnabled;
  final bool callHandlingEnabled;
  final bool phoneManagementEnabled;
  final bool speakerCallModeEnabled;
  final bool wakeWordEnabled;
  final double emotionLevel;
  final int humorLevel;
  final double formalityLevel;
  final bool powerScheduleEnabled;
  final String sleepStart;
  final String sleepEnd;
  final String activeVoiceProfileId;

  const NovaSettings({
    this.speechRate = 0.62,
    this.speechPitch = 1.0,
    this.chatGptInternetEnabled = true,
    this.teachingModeEnabled = true,
    this.apiLearningEnabled = true,
    this.apiKey = '',
    this.activeAiProvider = NovaAiProviderType.gemini,
    this.activeApiModel = NovaApiModelCatalog.geminiFreeTierStable,
    this.apiBrainEnabled = true,
    this.callHandlingEnabled = false,
    this.phoneManagementEnabled = false,
    this.speakerCallModeEnabled = false,
    this.wakeWordEnabled = true,
    this.emotionLevel = 0.5,
    this.humorLevel = 0,
    this.formalityLevel = 0.5,
    this.powerScheduleEnabled = false,
    this.sleepStart = '00:00',
    this.sleepEnd = '06:00',
    this.activeVoiceProfileId = '',
  });

  NovaSettings copyWith({
    double? speechRate,
    double? speechPitch,
    bool? chatGptInternetEnabled,
    bool? teachingModeEnabled,
    bool? apiLearningEnabled,
    String? apiKey,
    NovaAiProviderType? activeAiProvider,
    String? activeApiModel,
    bool? apiBrainEnabled,
    bool? callHandlingEnabled,
    bool? phoneManagementEnabled,
    bool? speakerCallModeEnabled,
    bool? wakeWordEnabled,
    double? emotionLevel,
    int? humorLevel,
    double? formalityLevel,
    bool? powerScheduleEnabled,
    String? sleepStart,
    String? sleepEnd,
    String? activeVoiceProfileId,
  }) {
    return NovaSettings(
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      chatGptInternetEnabled:
          chatGptInternetEnabled ?? this.chatGptInternetEnabled,
      teachingModeEnabled: teachingModeEnabled ?? this.teachingModeEnabled,
      apiLearningEnabled: apiLearningEnabled ?? this.apiLearningEnabled,
      apiKey: apiKey ?? this.apiKey,
      activeAiProvider: activeAiProvider ?? this.activeAiProvider,
      activeApiModel: activeApiModel ?? this.activeApiModel,
      apiBrainEnabled: apiBrainEnabled ?? this.apiBrainEnabled,
      callHandlingEnabled: callHandlingEnabled ?? this.callHandlingEnabled,
      phoneManagementEnabled:
          phoneManagementEnabled ?? this.phoneManagementEnabled,
      speakerCallModeEnabled:
          speakerCallModeEnabled ?? this.speakerCallModeEnabled,
      wakeWordEnabled: wakeWordEnabled ?? this.wakeWordEnabled,
      emotionLevel: emotionLevel ?? this.emotionLevel,
      humorLevel: humorLevel ?? this.humorLevel,
      formalityLevel: formalityLevel ?? this.formalityLevel,
      powerScheduleEnabled: powerScheduleEnabled ?? this.powerScheduleEnabled,
      sleepStart: sleepStart ?? this.sleepStart,
      sleepEnd: sleepEnd ?? this.sleepEnd,
      activeVoiceProfileId: activeVoiceProfileId ?? this.activeVoiceProfileId,
    );
  }

  Map<String, dynamic> toMap() => {
    'speechRate': speechRate,
    'speechPitch': speechPitch,
    'chatGptInternetEnabled': chatGptInternetEnabled,
    'teachingModeEnabled': teachingModeEnabled,
    'apiLearningEnabled': apiLearningEnabled,
    'apiKey': apiKey,
    'activeAiProvider': activeAiProvider.key,
    'activeApiModel': activeApiModel,
    'apiBrainEnabled': apiBrainEnabled,
    'callHandlingEnabled': callHandlingEnabled,
    'phoneManagementEnabled': phoneManagementEnabled,
    'speakerCallModeEnabled': speakerCallModeEnabled,
    'wakeWordEnabled': wakeWordEnabled,
    'emotionLevel': emotionLevel,
    'humorLevel': humorLevel,
    'formalityLevel': formalityLevel,
    'powerScheduleEnabled': powerScheduleEnabled,
    'sleepStart': sleepStart,
    'sleepEnd': sleepEnd,
    'activeVoiceProfileId': activeVoiceProfileId,
  };

  factory NovaSettings.fromMap(Map<String, dynamic> map) {
    final provider = NovaAiProviderTypeX.fromKey(
      map['activeAiProvider']?.toString() ??
          map['aiProvider']?.toString() ??
          'gemini',
    );
    final fallbackModel = NovaApiModelCatalog.defaultModelFor(provider);
    return NovaSettings(
      speechRate: (map['speechRate'] as num?)?.toDouble() ?? 0.62,
      speechPitch: (map['speechPitch'] as num?)?.toDouble() ?? 1.0,
      chatGptInternetEnabled: map['chatGptInternetEnabled'] as bool? ?? true,
      teachingModeEnabled: map['teachingModeEnabled'] as bool? ?? true,
      apiLearningEnabled: map['apiLearningEnabled'] as bool? ?? true,
      apiKey: (map['apiKey'] as String? ?? ''),
      activeAiProvider: provider,
      activeApiModel: (map['activeApiModel'] as String? ?? '').trim().isEmpty
          ? fallbackModel
          : (map['activeApiModel'] as String).trim(),
      apiBrainEnabled: map['apiBrainEnabled'] as bool? ?? true,
      callHandlingEnabled: map['callHandlingEnabled'] as bool? ?? false,
      phoneManagementEnabled: map['phoneManagementEnabled'] as bool? ?? false,
      speakerCallModeEnabled: map['speakerCallModeEnabled'] as bool? ?? false,
      wakeWordEnabled: map['wakeWordEnabled'] as bool? ?? true,
      emotionLevel: (map['emotionLevel'] as num?)?.toDouble() ?? 0.5,
      humorLevel: map['humorLevel'] as int? ?? 0,
      formalityLevel: (map['formalityLevel'] as num?)?.toDouble() ?? 0.5,
      powerScheduleEnabled: map['powerScheduleEnabled'] as bool? ?? false,
      sleepStart: (map['sleepStart'] as String? ?? '00:00'),
      sleepEnd: (map['sleepEnd'] as String? ?? '06:00'),
      activeVoiceProfileId: (map['activeVoiceProfileId'] as String? ?? ''),
    );
  }

  bool get voiceCloneListeningEnabled => false;
}
