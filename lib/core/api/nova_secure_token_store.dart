// NOVA_KEYSTORE_BACKED_RUNTIME_SECRETS_V1
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nova_ai_provider_type.dart';

class NovaSecureTokenStore {
  static const String _legacyApiKeyPrefsKey = 'nova_legacy_api_key_mirror';
  static const String carrierBridgeTokenName = 'carrier_bridge_control_token';
  static final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  const NovaSecureTokenStore();

  String _keyFor(NovaAiProviderType provider) => 'nova_api_key_${provider.key}';
  String _namedKey(String name) =>
      'nova_runtime_secret_${name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_')}';

  Future<String> read(NovaAiProviderType provider) async {
    final key = _keyFor(provider);
    final secure = (await _storage.read(key: key))?.trim() ?? '';
    if (secure.isNotEmpty) return secure;

    final prefs = await SharedPreferences.getInstance();
    var legacy = prefs.getString(key)?.trim() ?? '';
    if (legacy.isEmpty && provider == NovaAiProviderType.gemini) {
      legacy = prefs.getString(_legacyApiKeyPrefsKey)?.trim() ?? '';
    }
    if (legacy.isNotEmpty) {
      await _storage.write(key: key, value: legacy);
      await prefs.remove(key);
      if (provider == NovaAiProviderType.gemini) {
        await prefs.remove(_legacyApiKeyPrefsKey);
      }
    }
    return legacy;
  }

  Future<void> write(NovaAiProviderType provider, String token) async {
    final key = _keyFor(provider);
    final normalized = token.trim();
    final prefs = await SharedPreferences.getInstance();
    if (normalized.isEmpty) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: normalized);
    }
    await prefs.remove(key);
    if (provider == NovaAiProviderType.gemini) {
      await prefs.remove(_legacyApiKeyPrefsKey);
    }
  }

  Future<String> readNamed(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return '';
    final key = _namedKey(normalizedName);
    final secure = (await _storage.read(key: key))?.trim() ?? '';
    if (secure.isNotEmpty) return secure;

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(key)?.trim() ?? '';
    if (legacy.isNotEmpty) {
      await _storage.write(key: key, value: legacy);
      await prefs.remove(key);
    }
    return legacy;
  }

  Future<void> writeNamed(String name, String secret) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Secret name cannot be empty');
    }
    final key = _namedKey(normalizedName);
    final normalizedSecret = secret.trim();
    if (normalizedSecret.isEmpty) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: normalizedSecret);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
