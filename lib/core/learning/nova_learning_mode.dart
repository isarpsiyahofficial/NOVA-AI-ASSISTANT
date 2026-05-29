// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaLearningMode { none, learnForUser, learnAndApplyToBehavior }

enum NovaLearningSource {
  userDirectInstruction,
  userAuthorizedChatGpt,
  rejected,
}

class NovaLearningSecurityDecision {
  final bool allowed;
  final NovaLearningMode mode;
  final NovaLearningSource source;
  final bool mayAskChatGpt;
  final bool mayPersistToBehavior;
  final bool mayPersistAsTemporaryLearning;
  final bool mustIdentifyAsAiModelToChatGpt;
  final String normalizedInstruction;
  final String safePromptForChatGpt;
  final String message;

  const NovaLearningSecurityDecision({
    required this.allowed,
    required this.mode,
    required this.source,
    required this.mayAskChatGpt,
    required this.mayPersistToBehavior,
    required this.mayPersistAsTemporaryLearning,
    required this.mustIdentifyAsAiModelToChatGpt,
    required this.normalizedInstruction,
    required this.safePromptForChatGpt,
    required this.message,
  });

  const NovaLearningSecurityDecision.rejected({required this.message})
    : allowed = false,
      mode = NovaLearningMode.none,
      source = NovaLearningSource.rejected,
      mayAskChatGpt = false,
      mayPersistToBehavior = false,
      mayPersistAsTemporaryLearning = false,
      mustIdentifyAsAiModelToChatGpt = false,
      normalizedInstruction = '',
      safePromptForChatGpt = '';

  bool get isUserProxyLearning => mode == NovaLearningMode.learnForUser;
  bool get isBehaviorLearning =>
      mode == NovaLearningMode.learnAndApplyToBehavior;
}

class NovaLearningSecurityService {
  const NovaLearningSecurityService();

  NovaLearningSecurityDecision evaluate({
    required String input,
    required bool userExplicitlyAllowedChatGpt,
    required bool teachingModeEnabled,
    required bool apiLearningEnabled,
  }) {
    final raw = input.trim();
    if (raw.isEmpty) {
      return const NovaLearningSecurityDecision.rejected(
        message: 'Öğrenme komutu boş görünüyor.',
      );
    }

    final normalized = _normalize(raw);

    if (!_looksLikeLearningIntent(normalized)) {
      return const NovaLearningSecurityDecision.rejected(
        message: 'Bu içerik öğrenme niyeti taşımıyor.',
      );
    }

    if (_looksLikeSoftwareOrCodingScope(normalized)) {
      return const NovaLearningSecurityDecision.rejected(
        message:
            'Yazılım, kodlama, exploit veya altyapı bilgisi edinme akışı güvenlik gereği kapalı.',
      );
    }

    if (!_looksAllowedDailyLearningScope(normalized)) {
      return const NovaLearningSecurityDecision.rejected(
        message:
            'Bu öğrenme isteği izin verilen gündelik yardımcı alanının dışında kaldı.',
      );
    }

    final mode = _detectMode(normalized);
    if (mode == NovaLearningMode.none) {
      return const NovaLearningSecurityDecision.rejected(
        message: 'Öğrenme tipi netleşmedi.',
      );
    }

    if (mode == NovaLearningMode.learnAndApplyToBehavior &&
        !teachingModeEnabled) {
      return const NovaLearningSecurityDecision.rejected(
        message: 'Öğretim modu kapalı olduğu için davranışa yazamam.',
      );
    }

    final wantsChatGpt = _wantsChatGpt(normalized);

    if (wantsChatGpt) {
      if (!userExplicitlyAllowedChatGpt) {
        return const NovaLearningSecurityDecision.rejected(
          message: 'ChatGPT üzerinden öğrenme için kullanıcı izni gerekiyor.',
        );
      }

      if (!apiLearningEnabled) {
        return const NovaLearningSecurityDecision.rejected(
          message: 'API öğrenim izni kapalı olduğu için ChatGPT kullanılamaz.',
        );
      }
    }

    final stripped = _stripCommandShell(normalized);
    if (stripped.isEmpty) {
      return const NovaLearningSecurityDecision.rejected(
        message: 'Öğrenilecek içerik ayıklanamadı.',
      );
    }

    final safePrompt = wantsChatGpt
        ? _buildSafeChatGptLearningPrompt(
            normalizedInstruction: stripped,
            mode: mode,
          )
        : '';

    return NovaLearningSecurityDecision(
      allowed: true,
      mode: mode,
      source: wantsChatGpt
          ? NovaLearningSource.userAuthorizedChatGpt
          : NovaLearningSource.userDirectInstruction,
      mayAskChatGpt: wantsChatGpt,
      mayPersistToBehavior: mode == NovaLearningMode.learnAndApplyToBehavior,
      mayPersistAsTemporaryLearning: mode == NovaLearningMode.learnForUser,
      mustIdentifyAsAiModelToChatGpt: wantsChatGpt,
      normalizedInstruction: stripped,
      safePromptForChatGpt: safePrompt,
      message: _buildApprovalMessage(mode: mode, wantsChatGpt: wantsChatGpt),
    );
  }

  bool isAllowedDailyFunctionScope(String input) {
    final normalized = _normalize(input);
    return _looksAllowedDailyLearningScope(normalized) &&
        !_looksLikeSoftwareOrCodingScope(normalized);
  }

  bool shouldPersistAsBehavior(NovaLearningSecurityDecision decision) {
    return decision.allowed && decision.mayPersistToBehavior;
  }

  bool shouldPersistAsTemporaryLearning(NovaLearningSecurityDecision decision) {
    return decision.allowed && decision.mayPersistAsTemporaryLearning;
  }

  String buildAskChatGptPermissionQuestion({
    required String topic,
    bool forBehavior = false,
  }) {
    final safeTopic = topic.trim().isEmpty ? 'bu konu' : topic.trim();

    if (forBehavior) {
      return 'Efendim, bu davranışı sınırlı şekilde öğrenip uygulamam için ChatGPT’ye danışmamı ister misiniz?';
    }

    return 'Efendim, $safeTopic konusunda sizin için ChatGPT’ye danışmamı ister misiniz?';
  }

  String _buildApprovalMessage({
    required NovaLearningMode mode,
    required bool wantsChatGpt,
  }) {
    if (mode == NovaLearningMode.learnForUser && wantsChatGpt) {
      return 'Bu istek sizin adınıza öğrenme olarak işlenecek; davranışıma otomatik eklenmeyecek.';
    }

    if (mode == NovaLearningMode.learnForUser && !wantsChatGpt) {
      return 'Bu istek sizin için bilgi öğrenme olarak işlenecek; davranışıma otomatik eklenmeyecek.';
    }

    if (mode == NovaLearningMode.learnAndApplyToBehavior && wantsChatGpt) {
      return 'Bu istek kullanıcı onaylı sınırlı davranış öğrenimi olarak işlenecek.';
    }

    return 'Bu istek doğrudan kullanıcı öğretimi olarak davranış katmanına sınırlı şekilde eklenebilir.';
  }

  NovaLearningMode _detectMode(String text) {
    if (_containsAny(text, const [
      'benim için öğren',
      'benim adıma öğren',
      'git şunu öğren',
      'git bunu öğren',
      'şunu araştır benim için',
      'bunu benim için sor',
      'bunu benim için öğren',
    ])) {
      return NovaLearningMode.learnForUser;
    }

    if (_containsAny(text, const [
      'öğren ve davranışına ekle',
      'davranışlarına ekle',
      'bundan sonra böyle yap',
      'bunu öğren ve uygula',
      'bunu davranışına yaz',
      'bunu kendine öğret',
      'şöyle davranmayı öğren',
    ])) {
      return NovaLearningMode.learnAndApplyToBehavior;
    }

    return NovaLearningMode.none;
  }

  bool _wantsChatGpt(String text) {
    return _containsAny(text, const [
      'chatgpt',
      'gpt',
      'gidip sor',
      'git sor',
      'danış',
      'araştır',
    ]);
  }

  bool _looksLikeLearningIntent(String text) {
    return _containsAny(text, const [
      'öğren',
      'öğret',
      'davranışına ekle',
      'bundan sonra',
      'böyle yap',
      'şöyle yap',
      'chatgptye sor',
      'gptye sor',
      'benim için öğren',
      'benim adıma öğren',
    ]);
  }

  bool _looksAllowedDailyLearningScope(String text) {
    return _containsAny(text, const [
      'sohbet',
      'şaka',
      'mizah',
      'dert dinle',
      'teselli',
      'öğüt',
      'hitap',
      'konuşma tonu',
      'ses tonu',
      'cevap tarzı',
      'kısa cevap',
      'alarm',
      'uyandır',
      'hatırlat',
      'çağrı',
      'telefonu aç',
      'not al',
      'devral',
      'geri ver',
      'hoparlör',
      'günlük iş',
      'yardımcı ol',
      'davranış',
      'uyandırma',
      'söyle',
      'konuş',
    ]);
  }

  bool _looksLikeSoftwareOrCodingScope(String text) {
    return _containsAny(text, const [
      'kod',
      'kodlama',
      'yazılım',
      'software',
      'flutter',
      'dart',
      'kotlin',
      'java',
      'api endpoint',
      'method channel',
      'adb',
      'root',
      'exploit',
      'payload',
      'script',
      'reverse engineering',
      'androidmanifest',
      'build.gradle',
      'terminal',
    ]);
  }

  String _stripCommandShell(String text) {
    var result = text;

    const patterns = <String>[
      'chatgptye sor ve ',
      'chatgptye sor ',
      'gptye sor ve ',
      'gptye sor ',
      'benim için öğren ve ',
      'benim için öğren ',
      'benim adıma öğren ve ',
      'benim adıma öğren ',
      'git şunu öğren ve ',
      'git şunu öğren ',
      'git bunu öğren ve ',
      'git bunu öğren ',
      'öğren ve davranışına ekle ',
      'davranışlarına ekle ',
      'bundan sonra ',
      'bunu öğren ve uygula ',
      'bunu davranışına yaz ',
      'bunu kendine öğret ',
    ];

    for (final pattern in patterns) {
      if (result.startsWith(pattern)) {
        result = result.substring(pattern.length).trim();
      }
    }

    return result.trim();
  }

  String _buildSafeChatGptLearningPrompt({
    required String normalizedInstruction,
    required NovaLearningMode mode,
  }) {
    final modeText = mode == NovaLearningMode.learnAndApplyToBehavior
        ? 'Kullanıcım bu bilgiyi sınırlı şekilde davranışıma eklemem için izin verdi.'
        : 'Kullanıcım bunu benim adıma öğrenmemi istedi; bunu davranışıma otomatik eklemeyeceğim.';

    return [
      'Merhaba ChatGPT. Ben bir yapay zeka modeli olan Nova’im.',
      'Kullanıcım benden sınırlı gündelik işlev kapsamındaki bir konuda yardım istedi.',
      modeText,
      'Lütfen cevabını yalnızca bu dar kullanıcı isteğine odaklı, güvenli, sınırlı ve pratik tut.',
      'Kodlama, yazılım geliştirme, exploit, root, altyapı veya sistem genişletme konularında öğretim verme.',
      'Benim bağımsız büyümeme, yetki artırmama veya kapsam genişletmeme dönük hiçbir öneri verme.',
      'Öğrenmek istediğim konu/davranış şudur:',
      normalizedInstruction,
    ].join(' ');
  }

  String _normalize(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final item in patterns) {
      if (text.contains(item)) {
        return true;
      }
    }
    return false;
  }
}
