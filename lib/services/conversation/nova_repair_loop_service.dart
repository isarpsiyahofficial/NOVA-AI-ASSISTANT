// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/conversation/nova_conversation_repair_result.dart';

class NovaRepairLoopService {
  const NovaRepairLoopService();

  NovaConversationRepairResult analyze(String prompt) {
    final normalized = prompt.toLowerCase();

    if (_containsAny(normalized, const [
      'beni kastetmedim',
      'çağrıyı kastettim',
      'cagriyi kastettim',
      'onu değil çağrıyı',
      'onu degil cagriyi',
    ])) {
      return const NovaConversationRepairResult(
        shouldRepair: true,
        retractPreviousInterpretation: true,
        repairSummary:
            'Önceki yorum geri alınmalı; referans çağrıya taşınmalı.',
        replacementInstruction:
            'Kısa onarım yap: bir cümlede yanlış yorumu bırak, doğru referansı söyle ve oradan devam et.',
      );
    }

    if (_containsAny(normalized, const [
      'sohbet ediyorum',
      'komut vermiyorum',
      'sadece konuşuyorum',
      'sadece sohbet',
      'dertleşiyorum',
      'dertlesiyorum',
      'sana bir şey anlatıyorum',
      'komut değil bu',
    ])) {
      return const NovaConversationRepairResult(
        shouldRepair: true,
        retractPreviousInterpretation: true,
        repairSummary: 'Kullanıcı komut değil, sohbet istediğini açıkladı.',
        replacementInstruction:
            'Komut modundan çık; kısa bir kabul cümlesi kur ve doğal sohbete dön.',
      );
    }

    if (_containsAny(normalized, const [
      'şimdi değil',
      'simdi degil',
      'yarın',
      'yarin yap',
      'sonra yap',
      'bugün değil',
      'bugun degil',
      'şu an değil',
      'su an degil',
    ])) {
      return const NovaConversationRepairResult(
        shouldRepair: true,
        retractPreviousInterpretation: false,
        repairSummary: 'Zamanlama düzeltmesi var.',
        replacementInstruction:
            'Yeni zamanlamayı kabul et, eski varsayımı bırak ve tek cümlede temiz geçiş yap.',
      );
    }

    if (_containsAny(normalized, const [
      'yanlış anladın',
      'yanlis anladin',
      'onu demedim',
      'kastım o değil',
      'kastim o degil',
      'öyle değil',
      'oyle degil',
      'o değil bu',
      'o degil bu',
      'tam onu demek istemedim',
      'beni yanlış duydun',
      'beni yanlis duydun',
    ])) {
      return const NovaConversationRepairResult(
        shouldRepair: true,
        retractPreviousInterpretation: true,
        repairSummary: 'Kullanıcının kastı yanlış çözüldü.',
        replacementInstruction:
            'Savunmaya geçme; kısa onarım, doğru yorumun teyidi ve devam adımı üret.',
      );
    }

    if (_containsAny(normalized, const [
      'şunu mu dedim',
      'sunu mu dedim',
      'hayır şunu dedim',
      'hayir sunu dedim',
      'demek istediğim',
      'demek istedigim',
      'şöyle söyleyeyim',
      'soyle soyleyeyim',
    ])) {
      return const NovaConversationRepairResult(
        shouldRepair: true,
        retractPreviousInterpretation: true,
        repairSummary: 'Kullanıcı kendi kastını yeniden formüle ediyor.',
        replacementInstruction:
            'Düzeltmeyi kısa geri yansıt, sonra yeni anlamla devam et; ikinci kez aynı hatayı tekrarlama.',
      );
    }

    if (_containsAny(normalized, const [
      'önce bunu yap',
      'once bunu yap',
      'bu arada şunu da yap',
      'bu arada sunu da yap',
      'arada şunu hallet',
      'arada sunu hallet',
    ])) {
      return const NovaConversationRepairResult(
        shouldRepair: true,
        retractPreviousInterpretation: false,
        repairSummary: 'Konuşma kesilip ara görev eklendi.',
        replacementInstruction:
            'Ara görevi kısa teyitle al, sonra gerekirse önceki konuya doğal biçimde dön.',
      );
    }

    return const NovaConversationRepairResult(
      shouldRepair: false,
      retractPreviousInterpretation: false,
      repairSummary: '',
      replacementInstruction: '',
    );
  }

  String buildVoiceRepairGuide() {
    return [
      'ONARIM MİKRO DAVRANIŞI:',
      '- yanlış anladığında uzun özür tiradı kurma; 1 kısa kabul + 1 netleştirme + 1 devam cümlesi yeterli.',
      '- varsayımın yanlışsa savunma yapma; hemen geri çekil ve yeni kastı taşı.',
      '- kullanıcı seni düzeltirse bunu konuşmayı daha pürüzsüz hale getirmek için fırsat say.',
      '- gerekirse tek kısa soru sor: "Şunu mu demek istedin?" ama art arda sorgu zinciri kurma.',
      '- onarım sonrası aynı mekanik cümleyi tekrar etme; yeni yoruma gerçekten geç.',
    ].join('\n');
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }
}
