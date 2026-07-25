// NOVA_IMMUTABLE_TRANSCRIPT_ACTION_GUARD_V1
import '../../core/actions/nova_device_action.dart';
import '../../core/ai/ai_request.dart';
import '../../core/turn/nova_turn_authority.dart';

class NovaActionIntentGuardDecision {
  final bool allowed;
  final String failureCode;
  final String message;
  final String bindingId;

  const NovaActionIntentGuardDecision({
    required this.allowed,
    required this.failureCode,
    required this.message,
    required this.bindingId,
  });

  const NovaActionIntentGuardDecision.denied({
    required String failureCode,
    required String message,
  }) : this(
          allowed: false,
          failureCode: failureCode,
          message: message,
          bindingId: '',
        );
}

class NovaActionIntentGuardService {
  static final NovaActionIntentGuardService instance =
      NovaActionIntentGuardService._();

  final Set<String> _consumedBindings = <String>{};

  NovaActionIntentGuardService._();

  NovaActionIntentGuardDecision authorize({
    required NovaDeviceActionCall call,
    required AiRequest request,
  }) {
    final action = call.action.trim().toLowerCase();
    final text = _fold(request.canonicalUserText);
    final lease = request.lease;

    if (lease == null || !request.hasCurrentLease) {
      return const NovaActionIntentGuardDecision.denied(
        failureCode: 'stale_or_missing_turn_lease',
        message: 'Telefon eylemi taze bir tur yetkisine bağlı değil.',
      );
    }
    if (!request.authority.canRequestNativeAction) {
      return const NovaActionIntentGuardDecision.denied(
        failureCode: 'typed_authority_missing',
        message: 'Telefon eylemi için tipli yerel yetki kanıtı bulunamadı.',
      );
    }
    if (!request.userConfirmedThisAction) {
      return const NovaActionIntentGuardDecision.denied(
        failureCode: 'current_action_not_confirmed',
        message: 'Bu turdaki telefon eylemi kullanıcı tarafından doğrulanmadı.',
      );
    }
    if (text.isEmpty || !_transcriptSupportsAction(text, action, call.value)) {
      return const NovaActionIntentGuardDecision.denied(
        failureCode: 'tool_call_transcript_mismatch',
        message:
            'Model araç çağrısı değiştirilemez kullanıcı transcriptiyle eşleşmedi.',
      );
    }

    final providerId = call.providerCallId.trim().isEmpty
        ? 'provider_without_call_id'
        : call.providerCallId.trim();
    final bindingId = _fingerprint(<String>[
      lease.id,
      providerId,
      action,
      call.value.trim(),
      request.canonicalUserText.trim(),
      request.authority.kind.name,
      request.authority.evidenceId,
    ].join('|'));
    if (!_consumedBindings.add(bindingId)) {
      return const NovaActionIntentGuardDecision.denied(
        failureCode: 'replayed_tool_call',
        message: 'Bu model araç çağrısı daha önce tüketildi.',
      );
    }
    if (_consumedBindings.length > 256) {
      _consumedBindings.remove(_consumedBindings.first);
    }

    return NovaActionIntentGuardDecision(
      allowed: true,
      failureCode: '',
      message: 'Araç çağrısı transcript, tur lease’i ve tipli yetkiyle eşleşti.',
      bindingId: bindingId,
    );
  }

  bool _transcriptSupportsAction(String text, String action, String value) {
    final aliases = _aliases[action] ?? const <String>[];
    if (!aliases.any(text.contains)) return false;
    if (!NovaDeviceActionCatalog.requiresValue(action)) return true;

    final foldedValue = _fold(value);
    if (foldedValue.isEmpty) return false;
    if (text.contains(foldedValue)) return true;

    final valueWords = foldedValue
        .split(' ')
        .where((word) => word.length >= 3)
        .toList(growable: false);
    final textWords = text.split(' ');
    if (valueWords.isEmpty) return false;
    return valueWords.every(
      (valueWord) => textWords.any(
        (textWord) =>
            textWord.startsWith(valueWord) || valueWord.startsWith(textWord),
      ),
    );
  }

  String _fingerprint(String input) {
    var hash = 0xcbf29ce484222325;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  String _fold(String input) => input
      .toLowerCase()
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u')
      .replaceAll(RegExp(r'[^a-z0-9+]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static const Map<String, List<String>> _aliases = <String, List<String>>{
    'answer_call': <String>['cevapla', 'ac telefonu', 'aramayi ac'],
    'reject_call': <String>['reddet', 'aramayi kapat', 'mesgule at'],
    'hang_up': <String>['kapat', 'telefonu kapat', 'aramayi bitir'],
    'mute_call': <String>['mikrofonu kapat', 'sessize al', 'mute'],
    'unmute_call': <String>['mikrofonu ac', 'sesi geri ac', 'unmute'],
    'speaker_on': <String>['hoparloru ac', 'hoparlore al'],
    'speaker_off': <String>['hoparloru kapat', 'hoparlorden cikar'],
    'toggle_hold': <String>['beklet', 'bekletmeden cikar'],
    'place_call': <String>['ara', 'telefon et', 'cagri baslat'],
    'media_next': <String>['sonraki', 'siradaki sarki'],
    'media_previous': <String>['onceki', 'onceki sarki'],
    'media_pause': <String>['duraklat', 'muzigi durdur'],
    'media_resume': <String>['devam ettir', 'muzigi ac'],
    'media_play_pause': <String>['oynat', 'duraklat'],
    'volume_up': <String>['sesi ac', 'sesini yukselt'],
    'volume_down': <String>['sesi kis', 'sesini azalt'],
    'mute_media': <String>['medyayi sessize al', 'sesi kapat'],
    'open_spotify': <String>['spotify ac', 'spotifyi ac'],
    'open_youtube_music': <String>['youtube music ac', 'muzik uygulamasini ac'],
    'back': <String>['geri don', 'geri git'],
    'home': <String>['ana ekrana don', 'ana ekrani ac'],
    'open_notifications': <String>['bildirimleri ac', 'bildirim panelini ac'],
    'open_quick_settings': <String>['hizli ayarlari ac', 'kontrol panelini ac'],
    'tap_text': <String>['dokun', 'tikla', 'bas'],
    'set_focused_text': <String>['yaz', 'metni gir'],
  };
}
