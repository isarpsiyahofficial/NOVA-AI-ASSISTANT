// NOVA_API_MODEL_CATALOG_V1
import 'nova_ai_provider_type.dart';

class NovaApiModelCatalog {
  static const String geminiFreeTierStable = 'gemini-3.1-flash-lite';
  static const String geminiFreeTierBalanced = 'gemini-3.5-flash';
  static const String geminiStrongStable = 'gemini-3.5-flash';
  static const String geminiLiveStable = 'gemini-3.1-flash-live-preview';
  static const String geminiLivePreview = 'gemini-2.5-flash-live-preview';
  static const String geminiFlashStable = 'gemini-2.5-flash';
  static const String geminiLegacyFlashLite = 'gemini-2.5-flash-lite';
  static const String openAiLowCost = 'gpt-5.4-mini';
  static const String openAiFlagship = 'gpt-5.5';
  static const String qwenTrialFlash = 'qwen-flash';
  static const String qwenTrialPlus = 'qwen-plus';
  static const String qwenStrongMax = 'qwen-max';
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
          geminiFlashStable,
          geminiLegacyFlashLite,
          geminiLiveStable,
        ];
      case NovaAiProviderType.openai:
        return const <String>[openAiLowCost, openAiFlagship];
      case NovaAiProviderType.qwen:
        return const <String>[
          qwenTrialFlash,
          qwenTrialPlus,
          qwen35Flash,
          qwen35Plus,
          qwenStrongMax,
          qwen3Max,
        ];
    }
  }

  static String labelFor(String model) {
    final normalized = model.trim();
    if (normalized == geminiFreeTierStable) {
      return 'Gemini ücretsiz/düşük maliyet - 3.1 Flash-Lite';
    }
    if (normalized == geminiFreeTierBalanced ||
        normalized == geminiStrongStable) {
      return 'Gemini ücretsiz/dengeli - 3.5 Flash';
    }
    if (normalized == geminiFlashStable) {
      return 'Gemini 2.5 hızlı';
    }
    if (normalized == geminiLegacyFlashLite) {
      return 'Gemini 2.5 düşük maliyet uyumluluk';
    }
    if (normalized == geminiLiveStable) {
      return 'Gemini Live sesli önizleme';
    }
    if (normalized == openAiLowCost) {
      return 'OpenAI düşük maliyet';
    }
    if (normalized == openAiFlagship) {
      return 'OpenAI güçlü';
    }
    if (normalized == qwenTrialFlash) {
      return 'Qwen deneme/düşük maliyet - Flash';
    }
    if (normalized == qwenTrialPlus) {
      return 'Qwen deneme/dengeli - Plus';
    }
    if (normalized == qwen35Flash) {
      return 'Qwen 3.5 Flash - hızlı/ucuz';
    }
    if (normalized == qwen35Plus) {
      return 'Qwen 3.5 Plus - dengeli ücretli';
    }
    if (normalized == qwenStrongMax) {
      return 'Qwen Max - güçlü ücretli';
    }
    if (normalized == qwen3Max) {
      return 'Qwen3 Max - en güçlü ücretli';
    }
    return normalized.isEmpty ? 'Model seçilmedi' : normalized;
  }
}
