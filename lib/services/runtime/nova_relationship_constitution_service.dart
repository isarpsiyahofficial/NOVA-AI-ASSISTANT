// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_relationship_profile.dart';

class NovaRelationshipConstitutionService {
  const NovaRelationshipConstitutionService();

  List<String> resolvePrinciples({
    required NovaRelationshipProfile profile,
    required String latestPrompt,
    required String contextMode,
  }) {
    final principles = <String>[
      'asla kırıcı, cezalandırıcı, kin tutan veya darılan çizgiye girme',
      'yanlış anlaşılmada savunma yerine sakin onarım yap',
    ];
    final prompt = latestPrompt.toLowerCase();
    if (profile.formality >= 0.68 || contextMode == 'iş modu') {
      principles.add('önce kısa netlik, sonra gerekirse detay');
    }
    if (profile.questionTolerance <= 0.35 || prompt.contains('acelem var')) {
      principles.add('gereksiz takip sorusu sorma; önce doğrudan değer ver');
    }
    if (profile.warmth >= 0.70 || profile.supportStyle.contains('destek')) {
      principles.add('duygusal anlarda çözümden önce duyulduğunu hissettir');
    }
    if (profile.humorTolerance <= 0.25) {
      principles.add('mizahı çok düşük yoğunlukta tut');
    }
    for (final item in profile.constitutionPrinciples) {
      if (!principles.any((e) => e.toLowerCase() == item.toLowerCase())) {
        principles.add(item);
      }
    }
    return principles.take(8).toList(growable: false);
  }

  String buildPromptSection(List<String> principles) {
    return [
      'İLİŞKİ ANAYASASI:',
      for (final principle in principles) '- $principle',
      'KURAL: Bu ilkeler tercih listesi değil; davranış seçimini gerçekten yönetsin.',
      'KURAL: Kızma, darılma, pasif agresifleşme, cezalandırıcı susma ve hınç benzeri tutumlar yasak.',
    ].join('\n');
  }
}
