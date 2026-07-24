// NOVA_API_PROVIDER_SELECTION_V3_NAMED_RUNTIME_SECRETS
import 'package:shared_preferences/shared_preferences.dart';

import 'nova_ai_provider_type.dart';

class NovaSecureTokenStore {
  static const String _legacyApiKeyPrefsKey = 'nova_legacy_api_key_mirror';
  static const String carrierBridgeTokenName = 'carrier_bridge_control_token';

  const NovaSecureTokenStore();

  String _keyFor(NovaAiProviderType provider) => 'nova_api_key_${provider.key}';
  String _namedKey(String name) =>
      'nova_runtime_secret_${name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_')}';

  Future<String> read(NovaAiProviderType provider) async {
    final prefs = await SharedPreferences.getInstance();
    final providerKey = prefs.getString(_keyFor(provider))?.trim() ?? '';
    if (providerKey.isNotEmpty) return providerKey;
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

  Future<String> readNamed(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return '';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_namedKey(normalizedName))?.trim() ?? '';
  }

  Future<void> writeNamed(String name, String secret) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Secret name cannot be empty');
    }
    final prefs = await SharedPreferences.getInstance();
    final key = _namedKey(normalizedName);
    final normalizedSecret = secret.trim();
    if (normalizedSecret.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, normalizedSecret);
    }
  }
}
