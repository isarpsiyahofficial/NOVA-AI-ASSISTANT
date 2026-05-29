// NOVA_APK_LOCAL_ACTION_POLICY_V2
// Deterministic local policy for phone-only Nova actions. The LLM may suggest, but this policy decides what can be executed.

enum NovaActionRisk { low, medium, high, critical }

enum NovaActionDecisionType { allow, suggestOnly, requireUserApproval, block }

class NovaActionPolicyResult {
  final NovaActionRisk risk;
  final NovaActionDecisionType decision;
  final String reason;
  final bool mayExecute;
  final bool maySpeakToCaller;
  final bool requiresOwnerGesture;

  const NovaActionPolicyResult({
    required this.risk,
    required this.decision,
    required this.reason,
    required this.mayExecute,
    required this.maySpeakToCaller,
    required this.requiresOwnerGesture,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'risk': risk.name,
    'decision': decision.name,
    'reason': reason,
    'mayExecute': mayExecute,
    'maySpeakToCaller': maySpeakToCaller,
    'requiresOwnerGesture': requiresOwnerGesture,
  };
}

class NovaActionPolicy {
  const NovaActionPolicy();

  NovaActionPolicyResult evaluate({
    required String action,
    bool ownerInitiated = false,
    bool ownerVerified = false,
    bool knownContact = false,
    bool explicitlyAllowedContact = false,
    bool callActive = false,
    bool screenLocked = false,
    bool userConfirmedThisAction = false,
  }) {
    final normalized = action.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const NovaActionPolicyResult(
        risk: NovaActionRisk.low,
        decision: NovaActionDecisionType.block,
        reason: 'Boş aksiyon çalıştırılamaz.',
        mayExecute: false,
        maySpeakToCaller: false,
        requiresOwnerGesture: false,
      );
    }

    if (_isCritical(normalized)) {
      return const NovaActionPolicyResult(
        risk: NovaActionRisk.critical,
        decision: NovaActionDecisionType.block,
        reason:
            'Kimlik, şifre, ödeme, rehber sızıntısı veya bilinmeyen arayana özel bilgi verme gibi kritik aksiyonlar Nova APK içinde engellidir.',
        mayExecute: false,
        maySpeakToCaller: false,
        requiresOwnerGesture: true,
      );
    }

    if (_isHighRiskCallAction(normalized)) {
      final allowed =
          ownerVerified &&
          ownerInitiated &&
          userConfirmedThisAction &&
          knownContact &&
          explicitlyAllowedContact &&
          !screenLocked;
      return NovaActionPolicyResult(
        risk: NovaActionRisk.high,
        decision: allowed
            ? NovaActionDecisionType.allow
            : NovaActionDecisionType.requireUserApproval,
        reason: allowed
            ? 'Kişi bazlı izin ve sahip onayı mevcut; yüksek riskli çağrı aksiyonu yürütülebilir.'
            : 'Çağrı cevaplama/reddetme/arama başlatma otomatik çalışmaz; kişi bazlı izin ve ekranda sahip onayı gerekir.',
        mayExecute: allowed,
        maySpeakToCaller: false,
        requiresOwnerGesture: !allowed,
      );
    }

    if (_isMediumRisk(normalized)) {
      final allowed =
          ownerVerified && (ownerInitiated || userConfirmedThisAction);
      return NovaActionPolicyResult(
        risk: NovaActionRisk.medium,
        decision: allowed
            ? NovaActionDecisionType.allow
            : NovaActionDecisionType.requireUserApproval,
        reason: allowed
            ? 'Sahip doğrulaması mevcut; orta riskli telefon/medya/overlay aksiyonu uygulanabilir.'
            : 'Medya, güç, SMS taslağı veya overlay aksiyonu için sahip başlatması/onayı gerekir.',
        mayExecute: allowed,
        maySpeakToCaller: false,
        requiresOwnerGesture: !allowed,
      );
    }

    return const NovaActionPolicyResult(
      risk: NovaActionRisk.low,
      decision: NovaActionDecisionType.allow,
      reason: 'Düşük riskli durum okuma/öneri/arayüz aksiyonu.',
      mayExecute: true,
      maySpeakToCaller: false,
      requiresOwnerGesture: false,
    );
  }

  bool _isCritical(String value) {
    return value.contains('password') ||
        value.contains('şifre') ||
        value.contains('api_key') ||
        value.contains('token') ||
        value.contains('payment') ||
        value.contains('ödeme') ||
        value.contains('bank') ||
        value.contains('unknown_caller_private_info') ||
        value.contains('share_contact') ||
        value.contains('export_contacts') ||
        value.contains('delete_file') ||
        value.contains('shell') ||
        value.contains('cmd') ||
        value.contains('powershell');
  }

  bool _isHighRiskCallAction(String value) {
    return value.contains('answer_call') ||
        value.contains('reject_call') ||
        value.contains('disconnect_call') ||
        value.contains('start_call') ||
        value.contains('send_sms') ||
        value.contains('send_message') ||
        value.contains('speak_to_caller');
  }

  bool _isMediumRisk(String value) {
    return value.contains('media_') ||
        value.contains('volume_') ||
        value.contains('mute') ||
        value.contains('overlay') ||
        value.contains('wake') ||
        value.contains('sms_draft') ||
        value.contains('power_') ||
        value.contains('background_');
  }
}
