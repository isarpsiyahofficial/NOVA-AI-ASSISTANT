// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class KnownVoiceIdentity {
  final String id;
  final String displayName;
  final String relationshipLabel;
  final String voiceId;
  final bool isVoiceKnown;
  final bool isAuthorizedToUseNova;
  final bool canReceiveAutoCallHandling;
  final bool introducedByOwner;
  final DateTime createdAt;
  final DateTime updatedAt;
  const KnownVoiceIdentity({
    required this.id,
    required this.displayName,
    required this.relationshipLabel,
    required this.voiceId,
    this.isVoiceKnown = true,
    this.isAuthorizedToUseNova = false,
    this.canReceiveAutoCallHandling = false,
    this.introducedByOwner = false,
    required this.createdAt,
    required this.updatedAt,
  });
  KnownVoiceIdentity copyWith({
    String? id,
    String? displayName,
    String? relationshipLabel,
    String? voiceId,
    bool? isVoiceKnown,
    bool? isAuthorizedToUseNova,
    bool? canReceiveAutoCallHandling,
    bool? introducedByOwner,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => KnownVoiceIdentity(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    relationshipLabel: relationshipLabel ?? this.relationshipLabel,
    voiceId: voiceId ?? this.voiceId,
    isVoiceKnown: isVoiceKnown ?? this.isVoiceKnown,
    isAuthorizedToUseNova: isAuthorizedToUseNova ?? this.isAuthorizedToUseNova,
    canReceiveAutoCallHandling:
        canReceiveAutoCallHandling ?? this.canReceiveAutoCallHandling,
    introducedByOwner: introducedByOwner ?? this.introducedByOwner,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'relationshipLabel': relationshipLabel,
    'voiceId': voiceId,
    'isVoiceKnown': isVoiceKnown,
    'isAuthorizedToUseNova': isAuthorizedToUseNova,
    'canReceiveAutoCallHandling': canReceiveAutoCallHandling,
    'introducedByOwner': introducedByOwner,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  factory KnownVoiceIdentity.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return KnownVoiceIdentity(
      id: (map['id'] as String? ?? '').trim(),
      displayName: (map['displayName'] as String? ?? '').trim(),
      relationshipLabel: (map['relationshipLabel'] as String? ?? '').trim(),
      voiceId: (map['voiceId'] as String? ?? '').trim(),
      isVoiceKnown: map['isVoiceKnown'] as bool? ?? true,
      isAuthorizedToUseNova: map['isAuthorizedToUseNova'] as bool? ?? false,
      canReceiveAutoCallHandling:
          map['canReceiveAutoCallHandling'] as bool? ?? false,
      introducedByOwner: map['introducedByOwner'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? now,
    );
  }
}

enum KnownVoiceAuthorityTier { familiar, authorized }

extension KnownVoiceIdentityX on KnownVoiceIdentity {
  KnownVoiceAuthorityTier get authorityTier => isAuthorizedToUseNova
      ? KnownVoiceAuthorityTier.authorized
      : KnownVoiceAuthorityTier.familiar;

  String get authorityLabel {
    switch (authorityTier) {
      case KnownVoiceAuthorityTier.familiar:
        return 'Tanıdık';
      case KnownVoiceAuthorityTier.authorized:
        return 'Yetkili';
    }
  }
}
