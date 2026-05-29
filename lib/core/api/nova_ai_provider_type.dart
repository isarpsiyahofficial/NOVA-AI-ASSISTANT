/* NOVA_API_PROVIDER_SELECTION_BUILD_SIM_V3 */
enum NovaAiProviderType {
  gemini,
  openai,
  qwen;

  String get key {
    switch (this) {
      case NovaAiProviderType.gemini:
        return 'gemini';
      case NovaAiProviderType.openai:
        return 'openai';
      case NovaAiProviderType.qwen:
        return 'qwen';
    }
  }

  String get label {
    switch (this) {
      case NovaAiProviderType.gemini:
        return 'Gemini';
      case NovaAiProviderType.openai:
        return 'OpenAI';
      case NovaAiProviderType.qwen:
        return 'Qwen / Alibaba Model Studio';
    }
  }

  static NovaAiProviderType fromKey(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'openai':
      case 'chatgpt':
      case 'gpt':
        return NovaAiProviderType.openai;
      case 'qwen':
      case 'alibaba':
      case 'dashscope':
      case 'modelstudio':
      case 'model_studio':
      case 'tongyi':
        return NovaAiProviderType.qwen;
      case 'gemini':
      case 'google':
      default:
        return NovaAiProviderType.gemini;
    }
  }
}

extension NovaAiProviderTypeX on NovaAiProviderType {
  static NovaAiProviderType fromKey(String? value) =>
      NovaAiProviderType.fromKey(value);
}
