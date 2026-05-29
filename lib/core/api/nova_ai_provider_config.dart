// NOVA_API_PROVIDER_SELECTION_V1
import 'nova_ai_provider_type.dart';
import 'nova_api_model_catalog.dart';

class NovaAiProviderConfig {
  final NovaAiProviderType provider;
  final String apiKey;
  final String model;
  final bool enabled;

  const NovaAiProviderConfig({
    this.provider = NovaAiProviderType.gemini,
    this.apiKey = '',
    this.model = NovaApiModelCatalog.geminiFreeTierStable,
    this.enabled = true,
  });

  bool get isConfigured =>
      enabled && apiKey.trim().isNotEmpty && model.trim().isNotEmpty;

  NovaAiProviderConfig copyWith({
    NovaAiProviderType? provider,
    String? apiKey,
    String? model,
    bool? enabled,
  }) {
    return NovaAiProviderConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'provider': provider.key,
    'apiKey': '',
    'model': model,
    'enabled': enabled,
  };

  factory NovaAiProviderConfig.fromMap(Map<String, dynamic> map) {
    final provider = NovaAiProviderTypeX.fromKey(
      map['provider']?.toString() ?? 'gemini',
    );
    final fallbackModel = NovaApiModelCatalog.defaultModelFor(provider);
    return NovaAiProviderConfig(
      provider: provider,
      apiKey: map['apiKey']?.toString() ?? '',
      model: (map['model']?.toString().trim().isNotEmpty == true)
          ? map['model'].toString().trim()
          : fallbackModel,
      enabled: map['enabled'] as bool? ?? true,
    );
  }
}
