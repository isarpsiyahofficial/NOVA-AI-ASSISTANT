// NOVA_API_MODEL_CATALOG_V3_VERIFIED_IDS_AND_MIGRATION_2026_07
import 'nova_ai_provider_type.dart';

class NovaApiModelCatalog {
  static const String geminiFreeTierStable = 'gemini-3.5-flash-lite';
  static const String geminiFreeTierBalanced = 'gemini-3.6-flash';
  static const String geminiStrongStable = 'gemini-3.5-flash';
  static const String geminiFlashStable = 'gemini-3.6-flash';
  static const String geminiLegacyFlashLite = 'gemini-3.1-flash-lite';

  // Deserialization-only compatibility markers. Preview/live model IDs are not
  // offered as production presets because providers can retire them quickly.
  static const String geminiLiveStable = 'gemini-3.1-flash-live-preview';
  static const String geminiLivePreview = 'gemini-2.5-flash-live-preview';

  static const String openAiLowCost = 'gpt-5-mini';
  static const String openAiFlagship = 'gpt-5.1';

  static const String qwenTrialFlash = 'qwen3.6-flash';
  static const String qwenTrialPlus = 'qwen3.7-plus';
  static const String qwenStrongMax = 'qwen3.7-max';
  static const String qwen35Flash = 'qwen3.5-flash';
  static const String qwen35Plus = 'qwen3.5-plus';
  static const String qwen3Max = 'qwen3-max';

  static String defaultModelFor(NovaAiProviderType provider) {
    switch (provider) {
      case NovaAiProviderType.gemini:
        return geminiFreeTierStable;
      case NovaAiProviderType.openai:
        return openAiLowCost;
      case NovaAiProviderType.qwen:
        return qwenTrialFlash;
    }
  }

  static List<String> presetsFor(NovaAiProviderType provider) {
    switch (provider) {
      case NovaAiProviderType.gemini:
        return const <String>[
          geminiFreeTierStable,
          geminiFreeTierBalanced,
          geminiStrongStable,
          geminiLegacyFlashLite,
        ];
      case NovaAiProviderType.openai:
        return const <String>[openAiLowCost, openAiFlagship];
      case NovaAiProviderType.qwen:
        return const <String>[
          qwenTrialFlash,
          qwenTrialPlus,
          qwenStrongMax,
          qwen35Flash,
          qwen35Plus,
        ];
    }
  }

  static bool isProductionPreset(
    NovaAiProviderType provider,
    String model,
  ) => presetsFor(provider).contains(model.trim());

  static String migrateSavedModelId(
    NovaAiProviderType provider,
    String rawModel,
  ) {
    final value = rawModel.trim();
    if (value.isEmpty) return defaultModelFor(provider);

    switch (provider) {
      case NovaAiProviderType.openai:
        switch (value) {
          case 'gpt-5.4-mini':
          case 'gpt-5-mini-2025-08-07':
            return openAiLowCost;
          case 'gpt-5.5':
          case 'gpt-5':
          case 'gpt-5-2025-08-07':
            return openAiFlagship;
          default:
            return value;
        }
      case NovaAiProviderType.qwen:
        switch (value) {
          case 'qwen-flash':
            return qwenTrialFlash;
          case 'qwen-plus':
            return qwenTrialPlus;
          case 'qwen-max':
          case 'qwen3-max':
            return qwenStrongMax;
          default:
            return value;
        }
      case NovaAiProviderType.gemini:
        switch (value) {
          case 'gemini-3.1-flash-live-preview':
          case 'gemini-2.5-flash-live-preview':
          case 'gemini-2.0-flash':
          case 'gemini-2.0-flash-lite':
            return geminiFreeTierStable;
          default:
            return value;
        }
    }
  }

  static String labelFor(String model) {
    final normalized = model.trim();
    switch (normalized) {
      case geminiFreeTierStable:
        return 'Gemini 3.5 Flash-Lite — düşük gecikme/düşük maliyet';
      case geminiFreeTierBalanced:
        return 'Gemini 3.6 Flash — güncel dengeli';
      case geminiStrongStable:
        return 'Gemini 3.5 Flash — güçlü stable';
      case geminiLegacyFlashLite:
        return 'Gemini 3.1 Flash-Lite — uyumluluk';
      case openAiLowCost:
        return 'OpenAI GPT-5 mini — hızlı ve ekonomik';
      case openAiFlagship:
        return 'OpenAI GPT-5.1 — güçlü agent modeli';
      case qwenTrialFlash:
        return 'Qwen 3.6 Flash — hızlı ve ekonomik';
      case qwenTrialPlus:
        return 'Qwen 3.7 Plus — dengeli';
      case qwenStrongMax:
        return 'Qwen 3.7 Max — güçlü';
      case qwen35Flash:
        return 'Qwen 3.5 Flash — uyumluluk';
      case qwen35Plus:
        return 'Qwen 3.5 Plus — uyumluluk';
      default:
        return normalized.isEmpty ? 'Model seçilmedi' : normalized;
    }
  }
}
