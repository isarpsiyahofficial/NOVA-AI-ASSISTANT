// NOVA_API_FIRST_RESPONSE_CLEANER_V1
import '../speech/nova_final_text_contract.dart';

class NovaResponseCleaner {
  const NovaResponseCleaner();

  String cleanForSpeech(String input) {
    final seal = NovaFinalTextContract.sealModelOutput(
      rawText: input,
      provider: 'response_cleaner',
      model: 'minimal_non_lexical_cleanup',
    );
    return NovaFinalTextContract.cleanModelOutput(seal).cleanText;
  }
}
