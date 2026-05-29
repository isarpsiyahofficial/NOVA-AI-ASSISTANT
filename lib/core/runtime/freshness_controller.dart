// NOVA_API_FIRST_FRESHNESS_CONTROLLER_V1
import '../ai/ai_response.dart';

class NovaFreshnessController {
  NovaFreshnessController._internal();
  static final NovaFreshnessController instance =
      NovaFreshnessController._internal();

  int _lastAcceptedTurn = 0;
  String _lastAcceptedToken = '';

  AiResponse stampAuthoritativeResponse({
    required AiResponse response,
    required String source,
    required String text,
  }) {
    _lastAcceptedTurn += 1;
    _lastAcceptedToken =
        'turn_${_lastAcceptedTurn}_${text.hashCode}_${DateTime.now().microsecondsSinceEpoch}';
    return response.withAuthoritativeBrainProofText(
      text,
      quickReplyOverride: response.quickReply,
      extraMetadata: <String, dynamic>{
        'freshnessTurn': _lastAcceptedTurn,
        'freshnessToken': _lastAcceptedToken,
        'freshnessSource': source,
        'freshnessAccepted': true,
        'staleSpeechBlocked': true,
      },
    );
  }

  bool isCurrent(AiResponse? response, {bool allowMissing = false}) {
    if (response == null || response.isError) return false;
    final token = response.metadata['freshnessToken']?.toString().trim() ?? '';
    if (token.isEmpty) return allowMissing;
    return token == _lastAcceptedToken;
  }
}
