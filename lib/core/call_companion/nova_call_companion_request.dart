// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaCallCompanionRequest {
  final String liveConversation;
  final String phoneNumber;
  final bool allowApi;
  final bool isUserApproved;
  final bool isUserInitiated;
  final bool requestedByVoice;
  final bool allowTakeover;
  final bool allowHandoffBack;
  final String requestOrigin;

  const NovaCallCompanionRequest({
    required this.liveConversation,
    required this.phoneNumber,
    this.allowApi = false,
    this.isUserApproved = false,
    this.isUserInitiated = true,
    this.requestedByVoice = true,
    this.allowTakeover = true,
    this.allowHandoffBack = true,
    this.requestOrigin = 'call_companion',
  });

  NovaCallCompanionRequest copyWith({
    String? liveConversation,
    String? phoneNumber,
    bool? allowApi,
    bool? isUserApproved,
    bool? isUserInitiated,
    bool? requestedByVoice,
    bool? allowTakeover,
    bool? allowHandoffBack,
    String? requestOrigin,
  }) {
    return NovaCallCompanionRequest(
      liveConversation: liveConversation ?? this.liveConversation,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      allowApi: allowApi ?? this.allowApi,
      isUserApproved: isUserApproved ?? this.isUserApproved,
      isUserInitiated: isUserInitiated ?? this.isUserInitiated,
      requestedByVoice: requestedByVoice ?? this.requestedByVoice,
      allowTakeover: allowTakeover ?? this.allowTakeover,
      allowHandoffBack: allowHandoffBack ?? this.allowHandoffBack,
      requestOrigin: requestOrigin ?? this.requestOrigin,
    );
  }

  bool get hasUsableConversation => liveConversation.trim().isNotEmpty;
  bool get hasPhoneNumber => phoneNumber.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'liveConversation': liveConversation,
      'phoneNumber': phoneNumber,
      'allowApi': allowApi,
      'isUserApproved': isUserApproved,
      'isUserInitiated': isUserInitiated,
      'requestedByVoice': requestedByVoice,
      'allowTakeover': allowTakeover,
      'allowHandoffBack': allowHandoffBack,
      'requestOrigin': requestOrigin,
    };
  }

  factory NovaCallCompanionRequest.fromMap(Map<String, dynamic> map) {
    return NovaCallCompanionRequest(
      liveConversation: (map['liveConversation'] as String? ?? '').trim(),
      phoneNumber: (map['phoneNumber'] as String? ?? '').trim(),
      allowApi: map['allowApi'] as bool? ?? false,
      isUserApproved: map['isUserApproved'] as bool? ?? false,
      isUserInitiated: map['isUserInitiated'] as bool? ?? true,
      requestedByVoice: map['requestedByVoice'] as bool? ?? true,
      allowTakeover: map['allowTakeover'] as bool? ?? true,
      allowHandoffBack: map['allowHandoffBack'] as bool? ?? true,
      requestOrigin: (map['requestOrigin'] as String? ?? 'call_companion')
          .trim(),
    );
  }
}
