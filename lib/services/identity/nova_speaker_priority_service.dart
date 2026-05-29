// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/identity/nova_speaker_priority_decision.dart';

class NovaSpeakerPriorityService {
  const NovaSpeakerPriorityService();

  NovaSpeakerPriorityDecision resolve({
    required bool isOwner,
    required bool isAuthorized,
    required bool isIntroduced,
    required String speakerId,
    required String speakerName,
    int confidenceScore = 0,
    bool isCurrentConversationSpeaker = false,
    bool isRecentTrustedSpeaker = false,
  }) {
    final continuityBonus = isCurrentConversationSpeaker ? 18 : 0;
    final recentTrustedBonus = isRecentTrustedSpeaker ? 12 : 0;

    if (isOwner) {
      return NovaSpeakerPriorityDecision(
        band: NovaSpeakerPriorityBand.owner,
        speakerId: speakerId,
        speakerName: speakerName,
        score: 100 + confidenceScore + continuityBonus + recentTrustedBonus,
        shouldInterruptCurrentSpeaker: true,
      );
    }
    if (isAuthorized) {
      return NovaSpeakerPriorityDecision(
        band: NovaSpeakerPriorityBand.authorized,
        speakerId: speakerId,
        speakerName: speakerName,
        score: 70 + confidenceScore + continuityBonus + recentTrustedBonus,
        shouldInterruptCurrentSpeaker: true,
      );
    }
    if (isIntroduced) {
      return NovaSpeakerPriorityDecision(
        band: NovaSpeakerPriorityBand.introduced,
        speakerId: speakerId,
        speakerName: speakerName,
        score: 35 + confidenceScore + (isCurrentConversationSpeaker ? 10 : 0),
        shouldInterruptCurrentSpeaker: false,
      );
    }
    return NovaSpeakerPriorityDecision(
      band: NovaSpeakerPriorityBand.unknown,
      speakerId: speakerId,
      speakerName: speakerName,
      score: confidenceScore + (isCurrentConversationSpeaker ? 6 : 0),
      shouldInterruptCurrentSpeaker: false,
    );
  }
}
