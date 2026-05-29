// NOVA_API_PROVIDER_SELECTION_V2_NO_NEW_DEPENDENCIES
import 'package:shared_preferences/shared_preferences.dart';

import 'nova_ai_provider_type.dart';

class NovaSecureTokenStore {
  static const String _legacyApiKeyPrefsKey = 'nova_legacy_api_key_mirror';

  const NovaSecureTokenStore();

  String _keyFor(NovaAiProviderType provider) => 'nova_api_key_${provider.key}';

  Future<String> read(NovaAiProviderType provider) async {
    final prefs = await SharedPreferences.getInstance();
    final providerKey = prefs.getString(_keyFor(provider))?.trim() ?? '';
    if (providerKey.isNotEmpty) return providerKey;
    // Legacy mirror is used only for the original/default Gemini slot so a
    // previous single-key install is migrated without copying a Gemini/OpenAI
    // key into Qwen or another provider by mistake.
    if (provider == NovaAiProviderType.gemini) {
      return prefs.getString(_legacyApiKeyPrefsKey)?.trim() ?? '';
    }
    return '';
  }

  Future<void> write(NovaAiProviderType provider, String token) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = token.trim();
    final providerKey = _keyFor(provider);
    if (normalized.isEmpty) {
      await prefs.remove(providerKey);
      if (provider == NovaAiProviderType.gemini) {
        await prefs.remove(_legacyApiKeyPrefsKey);
      }
      return;
    }
    await prefs.setString(providerKey, normalized);
    if (provider == NovaAiProviderType.gemini) {
      await prefs.setString(_legacyApiKeyPrefsKey, normalized);
    }
  }
}
