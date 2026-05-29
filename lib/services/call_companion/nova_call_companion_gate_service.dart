// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1

import '../runtime/nova_identity_runtime_service.dart';

class NovaCallCompanionGateService {
  final NovaIdentityRuntimeService identityRuntimeService;

  const NovaCallCompanionGateService({
    this.identityRuntimeService = const NovaIdentityRuntimeService(),
  });

  bool shouldActivate(String text) {
    final value = _normalize(text);
    if (value.isEmpty) return false;

    return _activationPhrases().any(value.contains);
  }

  bool shouldRespondDuringCompanion(String text) {
    final value = _normalize(text);
    if (value.isEmpty) return false;

    if (isStopCommand(value) ||
        isUserTakeoverCommand(value) ||
        isNovaTakebackCommand(value)) {
      return true;
    }

    return _directAddressPhrases().any(value.contains) ||
        _callerConversationPhrases.any(value.contains);
  }

  bool isUserTakeoverCommand(String text) {
    final value = _normalize(text);
    return _userTakeoverPhrases.any(value.contains);
  }

  bool isNovaTakebackCommand(String text) {
    final value = _normalize(text);
    return _novaTakebackPhrases().any(value.contains);
  }

  bool isCallControlActionCommand(String text) {
    final value = _normalize(text);
    if (value.isEmpty) return false;
    return _callControlActionPhrases.any(value.contains);
  }

  bool isStopCommand(String text) {
    final value = _normalize(text);
    return _stopPhrases().any(value.contains);
  }

  String _normalize(String text) => text.trim().toLowerCase();

  List<String> _activationPhrases() => <String>{
    ...identityRuntimeService.prefixedPhrases(const <String>[
      'buraya gel',
      'bize yardım et',
      'ileri talimatla ara',
      'anlik ara',
      'anlık ara',
      'yardımcı ol',
      'sohbete katıl',
      'bizimle sohbet et',
      'devral',
      'çağrıya katıl',
      'burda mısın',
      'burada mısın',
      'gel',
    ]),
    ...identityRuntimeService.prefixedPhrases(const <String>[
      'yardım et',
    ], includeBareName: false),
  }.toList(growable: false);

  static const List<String> _callerConversationPhrases = <String>[
    'alo',
    'merhaba',
    'orada mısın',
    'orda mısın',
    'beni duyuyor musun',
    'beni duyuyormusun',
    'kim bu',
    'kimsiniz',
    'not bırakayım',
    'not al',
    'acil',
    'uyandır',
    'mesaj bırak',
    'size bir şey söyleyeceğim',
  ];

  List<String> _directAddressPhrases() => <String>{
    ...identityRuntimeService.knownAliases,
    ...identityRuntimeService.prefixedPhrases(const <String>[
      'bir bak',
      'cevap ver',
      'ne dersin',
      'sen söyle',
      'buna cevap ver',
      'yardım et',
      'açıkla',
    ]),
  }.toList(growable: false);

  static const List<String> _callControlActionPhrases = <String>[
    'telefonu kapat',
    'çağrıyı kapat',
    'aramayı kapat',
    'çağrıyı reddet',
    'telefonu reddet',
    'birini ara',
    'şunu ara',
    'numarayı ara',
    'bu numarayı ara',
    'başkasını ara',
    'hoparlöre al',
    'hoparlore al',
    'hoparloru aç',
    'hoparlörü aç',
    'mikrofonu kapat',
    'mikrofonu aç',
    'sesi kapat',
    'sesi aç',
    'beklet',
    'tuşla',
    'dtmf',
    'kayda başla',
    'görüntülü ara',
    'net arama',
  ];

  static const List<String> _userTakeoverPhrases = <String>[
    'ben devralıyorum',
    'çağrıyı bana bırak',
    'ben açarım',
    'ben acarim',
    'telefonu bana ver',
    'bana bırak',
    'ben konuşacağım',
    'mikrofonu bana ver',
    'konuşmayı bana bırak',
    'ben devam edeyim',
  ];

  List<String> _novaTakebackPhrases() => identityRuntimeService.prefixedPhrases(
    const <String>['devral', 'geri al', 'sen konuş', 'yeniden devral'],
  );

  List<String> _stopPhrases() => <String>{
    ...identityRuntimeService.prefixedPhrases(const <String>['sus', 'çekil']),
    'dur',
    'kapat',
  }.toList(growable: false);

  bool shouldAskWhatToSay(String text) {
    final value = _normalize(text);
    return value.contains('ne söyleyeyim') ||
        value.contains('ne diyeyim') ||
        value.contains('nasıl cevap vereyim');
  }

  bool shouldUseFreeformReply(String text) {
    final value = _normalize(text);
    return value.contains('detay') ||
        value.contains('ayrıntı') ||
        value.contains('insan gibi') ||
        value.contains('doğal konuş');
  }
}
