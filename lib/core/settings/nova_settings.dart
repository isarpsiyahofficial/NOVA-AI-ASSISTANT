// NOVA_API_FIRST_SETTINGS_V3_CARRIER_MEDIA_BRIDGE
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
  final bool carrierBridgeEnabled;
  final String carrierBridgeBaseUrl;
  final String carrierBridgeControlToken;
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
    this.carrierBridgeEnabled = false,
    this.carrierBridgeBaseUrl = '',
    this.carrierBridgeControlToken = '',
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
    bool? carrierBridgeEnabled,
    String? carrierBridgeBaseUrl,
    String? carrierBridgeControlToken,
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
      carrierBridgeEnabled:
          carrierBridgeEnabled ?? this.carrierBridgeEnabled,
      carrierBridgeBaseUrl:
          carrierBridgeBaseUrl ?? this.carrierBridgeBaseUrl,
      carrierBridgeControlToken:
          carrierBridgeControlToken ?? this.carrierBridgeControlToken,
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

  Map<String, dynamic> toMap() => <String, dynamic>{
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
        'carrierBridgeEnabled': carrierBridgeEnabled,
        'carrierBridgeBaseUrl': carrierBridgeBaseUrl,
        'carrierBridgeControlToken': carrierBridgeControlToken,
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
    final rawModel = map['activeApiModel']?.toString() ?? '';
    final migratedModel = NovaApiModelCatalog.migrateSavedModelId(
      provider,
      rawModel,
    );
    return NovaSettings(
      speechRate: (map['speechRate'] as num?)?.toDouble() ?? 0.62,
      speechPitch: (map['speechPitch'] as num?)?.toDouble() ?? 1.0,
      chatGptInternetEnabled: map['chatGptInternetEnabled'] as bool? ?? true,
      teachingModeEnabled: map['teachingModeEnabled'] as bool? ?? true,
      apiLearningEnabled: map['apiLearningEnabled'] as bool? ?? true,
      apiKey: map['apiKey']?.toString() ?? '',
      activeAiProvider: provider,
      activeApiModel: migratedModel,
      apiBrainEnabled: map['apiBrainEnabled'] as bool? ?? true,
      callHandlingEnabled: map['callHandlingEnabled'] as bool? ?? false,
      phoneManagementEnabled: map['phoneManagementEnabled'] as bool? ?? false,
      speakerCallModeEnabled: map['speakerCallModeEnabled'] as bool? ?? false,
      carrierBridgeEnabled: map['carrierBridgeEnabled'] as bool? ?? false,
      carrierBridgeBaseUrl:
          map['carrierBridgeBaseUrl']?.toString().trim() ?? '',
      carrierBridgeControlToken:
          map['carrierBridgeControlToken']?.toString().trim() ?? '',
      wakeWordEnabled: map['wakeWordEnabled'] as bool? ?? true,
      emotionLevel: (map['emotionLevel'] as num?)?.toDouble() ?? 0.5,
      humorLevel: (map['humorLevel'] as num?)?.toInt() ?? 0,
      formalityLevel: (map['formalityLevel'] as num?)?.toDouble() ?? 0.5,
      powerScheduleEnabled: map['powerScheduleEnabled'] as bool? ?? false,
      sleepStart: map['sleepStart']?.toString() ?? '00:00',
      sleepEnd: map['sleepEnd']?.toString() ?? '06:00',
      activeVoiceProfileId: map['activeVoiceProfileId']?.toString() ?? '',
    );
  }

  bool get voiceCloneListeningEnabled => false;
}
