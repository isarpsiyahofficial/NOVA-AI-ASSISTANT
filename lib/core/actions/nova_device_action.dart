// NOVA_VERIFIED_DEVICE_ACTION_CONTRACT_V2_LOCAL_CONTACT_TARGETS

class NovaDeviceActionCall {
  final String action;
  final String value;
  final String providerCallId;

  const NovaDeviceActionCall({
    required this.action,
    this.value = '',
    this.providerCallId = '',
  });

  factory NovaDeviceActionCall.fromArguments(
    Map<String, dynamic> arguments, {
    String providerCallId = '',
  }) {
    return NovaDeviceActionCall(
      action: arguments['action']?.toString().trim().toLowerCase() ?? '',
      value: arguments['value']?.toString().trim() ?? '',
      providerCallId: providerCallId.trim(),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'action': action,
        'value': value,
        'providerCallId': providerCallId,
      };
}

class NovaDeviceActionResult {
  final String action;
  final bool success;
  final bool verified;
  final String message;
  final String nativeMessage;
  final String failureCode;
  final Map<String, dynamic> policy;
  final Map<String, dynamic> beforeState;
  final Map<String, dynamic> afterState;

  const NovaDeviceActionResult({
    required this.action,
    required this.success,
    required this.verified,
    required this.message,
    this.nativeMessage = '',
    this.failureCode = '',
    this.policy = const <String, dynamic>{},
    this.beforeState = const <String, dynamic>{},
    this.afterState = const <String, dynamic>{},
  });

  String get spokenOutcome {
    final safeMessage = message.trim();
    if (!success) {
      return safeMessage.isEmpty
          ? 'İşlemi telefonda yapamadım.'
          : 'İşlemi telefonda yapamadım. $safeMessage';
    }
    if (!verified) {
      return 'Komutu telefona gönderdim ancak sonucunu cihaz durumundan doğrulayamadım.';
    }
    return safeMessage.isEmpty
        ? 'İşlem telefonda tamamlandı ve doğrulandı.'
        : safeMessage;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'action': action,
        'success': success,
        'verified': verified,
        'message': message,
        'nativeMessage': nativeMessage,
        'failureCode': failureCode,
        'policy': policy,
        'beforeState': beforeState,
        'afterState': afterState,
        'spokenOutcome': spokenOutcome,
      };
}

class NovaDeviceActionCatalog {
  static const String functionName = 'execute_phone_action';

  static const List<String> supportedActions = <String>[
    'answer_call',
    'reject_call',
    'hang_up',
    'mute_call',
    'unmute_call',
    'speaker_on',
    'speaker_off',
    'toggle_hold',
    'place_call',
    'media_next',
    'media_previous',
    'media_pause',
    'media_resume',
    'media_play_pause',
    'volume_up',
    'volume_down',
    'mute_media',
    'open_spotify',
    'open_youtube_music',
    'back',
    'home',
    'open_notifications',
    'open_quick_settings',
    'tap_text',
    'set_focused_text',
  ];

  static bool isSupported(String action) =>
      supportedActions.contains(action.trim().toLowerCase());

  static bool requiresValue(String action) {
    final normalized = action.trim().toLowerCase();
    return normalized == 'place_call' ||
        normalized == 'tap_text' ||
        normalized == 'set_focused_text';
  }

  static Map<String, dynamic> jsonParameters() => <String, dynamic>{
        'type': 'object',
        'additionalProperties': false,
        'properties': <String, dynamic>{
          'action': <String, dynamic>{
            'type': 'string',
            'enum': supportedActions,
            'description':
                'Telefonda gerçekten yürütülecek tek eylem. Normal sohbet için araç çağırma.',
          },
          'value': <String, dynamic>{
            'type': 'string',
            'description':
                'place_call için kullanıcının söylediği kişi adını aynen veya açıkça söylediği numarayı gönder; numara tahmin etme. Kişi adı cihazın yerel rehberinde çözülecek. tap_text için ekrandaki hedef metin, set_focused_text için yazılacak metin. Diğer eylemlerde boş string gönder.',
          },
        },
        'required': <String>['action', 'value'],
      };

  static Map<String, dynamic> openAiTool() => <String, dynamic>{
        'type': 'function',
        'name': functionName,
        'description':
            'Kullanıcının açıkça istediği telefon, çağrı, medya veya erişilebilirlik eylemini gerçek Android katmanında yürütür. Başarıyı asla tahmin etme; sonuç uygulama tarafından doğrulanır.',
        'parameters': jsonParameters(),
        'strict': true,
      };

  static Map<String, dynamic> qwenTool() => <String, dynamic>{
        'type': 'function',
        'function': <String, dynamic>{
          'name': functionName,
          'description':
              'Kullanıcının açıkça istediği telefon eylemini gerçek Android katmanında yürütür. Araç sonucundan önce işlemin yapıldığını söyleme.',
          'parameters': jsonParameters(),
        },
      };

  static Map<String, dynamic> geminiTool() => <String, dynamic>{
        'functionDeclarations': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': functionName,
            'description':
                'Kullanıcının açıkça istediği telefon eylemini gerçek Android katmanında yürütür. Sonuç cihaz tarafından doğrulanmadan başarı iddia etme.',
            'parameters': <String, dynamic>{
              'type': 'OBJECT',
              'properties': <String, dynamic>{
                'action': <String, dynamic>{
                  'type': 'STRING',
                  'enum': supportedActions,
                  'description': 'Yürütülecek tek telefon eylemi.',
                },
                'value': <String, dynamic>{
                  'type': 'STRING',
                  'description':
                      'place_call için kişi adı veya kullanıcının açıkça söylediği numara; numara tahmin edilmez ve kişi adı cihaz rehberinde çözülür. UI eylemlerinde hedef metin; diğerlerinde boş string.',
                },
              },
              'required': <String>['action', 'value'],
            },
          },
        ],
      };
}
