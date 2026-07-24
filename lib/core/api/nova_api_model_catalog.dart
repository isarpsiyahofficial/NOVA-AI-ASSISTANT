// NOVA_API_MODEL_CATALOG_V2_VERIFIED_PROVIDER_IDS_2026_07
import 'nova_ai_provider_type.dart';

class NovaApiModelCatalog {
  // Google stable models with documented function-calling support.
  static const String geminiFreeTierStable = 'gemini-3.5-flash-lite';
  static const String geminiFreeTierBalanced = 'gemini-3.6-flash';
  static const String geminiStrongStable = 'gemini-3.5-flash';
  static const String geminiFlashStable = 'gemini-3.6-flash';
  static const String geminiLegacyFlashLite = 'gemini-3.1-flash-lite';

  // Kept only for backward settings deserialization; preview/live identifiers
  // are deliberately excluded from production presets because they can expire.
  static const String geminiLiveStable = 'gemini-3.1-flash-live-preview';
  static const String geminiLivePreview = 'gemini-2.5-flash-live-preview';

  // OpenAI model IDs explicitly documented for the Responses API.
  static const String openAiLowCost = 'gpt-5-mini';
  static const String openAiFlagship = 'gpt-5.1';

  // Alibaba Model Studio recommended text models with function calling.
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
