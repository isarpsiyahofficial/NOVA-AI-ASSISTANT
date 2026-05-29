// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../core/self_repair/nova_system_issue.dart';
import '../../core/self_repair/nova_repair_audit_entry.dart';
import '../../services/self_repair/nova_capability_catalog_service.dart';
import '../../services/self_repair/nova_repair_trace_service.dart';
import '../../services/self_repair/nova_repair_audit_ledger_service.dart';
import '../../services/self_repair/nova_owner_blind_patch_bridge_service.dart';
import '../../services/self_repair/nova_self_repair_coordinator_service.dart';
import '../../services/self_repair/nova_self_repair_settings_service.dart';
import '../../services/self_repair/nova_debug_mode_service.dart';
import '../../services/self_repair/nova_self_diagnostic_service.dart';
import '../../services/self_repair/nova_runtime_signal_service.dart' as self_repair_signal;
import '../../services/self_repair/nova_self_recognition_service.dart';
import '../../services/self_repair/nova_capability_manifest_service.dart';
import '../../services/self_repair/nova_capability_runtime_registry_service.dart';
import '../../services/self_repair/nova_capability_probe_service.dart';

class SelfRepairControlPage extends StatefulWidget {
  final NovaSelfRepairCoordinatorService coordinatorService;
  final NovaSelfRepairSettingsService settingsService;
  final NovaRepairTraceService repairTraceService;

  const SelfRepairControlPage({
    super.key,
    required this.coordinatorService,
    required this.settingsService,
    required this.repairTraceService,
  });

  @override
  State<SelfRepairControlPage> createState() => _SelfRepairControlPageState();
}

class _SelfRepairControlPageState extends State<SelfRepairControlPage> {
  final TextEditingController _requestController = TextEditingController();
  final TextEditingController _ownerPasswordController =
      TextEditingController();
  final TextEditingController _ownerPatchController = TextEditingController();

  bool _loading = true;
  bool _running = false;
  String _status = 'Onarım paneli hazırlanıyor.';
  List<NovaSystemIssue> _issues = const <NovaSystemIssue>[];
  List<dynamic> _history = const <dynamic>[];
  List<NovaRepairAuditEntry> _auditEntries = const <NovaRepairAuditEntry>[];
  List<NovaCapabilityCatalogItem> _capabilities =
      const <NovaCapabilityCatalogItem>[];
  bool _commandEnabled = true;
  bool _manualEnabled = true;
  bool _voiceEnabled = true;
  bool _autoRepairEnabled = false;
  NovaSystemIssue? _ownerPatchIssue;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _requestController.dispose();
    _ownerPasswordController.dispose();
    _ownerPatchController.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final settings = await widget.settingsService.load();
    final issues = await widget.coordinatorService.previewIssues();
    final capabilities = await widget.coordinatorService.previewCapabilities();
    final history = await widget.repairTraceService.getAll();
    final auditEntries = await const NovaRepairAuditLedgerService().getAll();
    if (!mounted) return;
    setState(() {
      _issues = issues;
      _capabilities = capabilities;
      _history = history;
      _auditEntries = auditEntries;
      _commandEnabled = settings.commandRepairEnabled;
      _manualEnabled = settings.manualRepairEnabled;
      _voiceEnabled = settings.voiceNarrationEnabled;
      _autoRepairEnabled = settings.autoRepairSafeIssues;
      _loading = false;
      _status = issues.isEmpty
          ? 'Aktif sorun görünmüyor.'
          : 'Sorun listesi hazır.';
    });
  }

  Future<void> _runCommandRepair() async {
    setState(() {
      _running = true;
      _status = 'Komutla onarım akışı çalıştırılıyor...';
    });
    final result = await widget.coordinatorService.runFromCommand(
      _requestController.text,
    );
    await _restore();
    if (!mounted) return;
    setState(() {
      _running = false;
      _status = result.message;
    });
  }

  void _selectIssue(NovaSystemIssue issue) {
    setState(() {
      _ownerPatchIssue = issue;
      _ownerPatchController.text = issue.technicalMessage;
      _ownerPasswordController.clear();
      _status =
          '${issue.title} sorun alanı seçildi. Aşağıdaki owner-only bölümüne taşındı.';
    });
  }

  Future<void> _runManualRepairForIssue(NovaSystemIssue issue) async {
    setState(() {
      _running = true;
      _status = '${issue.title} için manuel onarım çalıştırılıyor...';
    });
    final result = await widget.coordinatorService.runManualRepair(
      requestedArea: issue.title,
    );
    await _restore();
    if (!mounted) return;
    setState(() {
      _running = false;
      _status = result.message;
    });
  }

  Future<void> _runOwnerApprovedSafeRepair(NovaSystemIssue issue) async {
    setState(() {
      _running = true;
      _status =
          '${issue.title} için sahip onaylı güvenli policy onarımı çalıştırılıyor...';
    });
    final result = await widget.coordinatorService.runManualRepair(
      requestedArea: issue.title,
      ownerApproved: true,
    );
    await _restore();
    if (!mounted) return;
    setState(() {
      _running = false;
      _status = result.message;
    });
  }

  Future<void> _runSelfRecognitionRefresh() async {
    setState(() {
      _loading = true;
      _status = 'Asistan kendini tanıyor ve yetenek özetini yeniliyor...';
    });
    await _restore();
  }

  Future<void> _runDebugScan() async {
    setState(() {
      _loading = true;
      _status = 'Derin hata ayıklama ve teşhis taraması çalışıyor...';
    });
    final debug = NovaDebugModeService(
      diagnosticService: NovaSelfDiagnosticService(
        signalService: self_repair_signal.NovaRuntimeSignalService.instance,
        recognitionService: NovaSelfRecognitionService(
          signalService: self_repair_signal.NovaRuntimeSignalService.instance,
          manifestService: NovaCapabilityManifestService(
            runtimeRegistryService:
                const NovaCapabilityRuntimeRegistryService(),
          ),
        ),
      ),
      capabilityCatalogService: NovaCapabilityCatalogService(
        recognitionService: NovaSelfRecognitionService(
          signalService: self_repair_signal.NovaRuntimeSignalService.instance,
          manifestService: NovaCapabilityManifestService(
            runtimeRegistryService:
                const NovaCapabilityRuntimeRegistryService(),
          ),
        ),
        probeService: NovaCapabilityProbeService(
          runtimeSignalService: self_repair_signal.NovaRuntimeSignalService.instance,
        ),
      ),
    );
    final result = await debug.runDeepDebug();
    final history = await widget.repairTraceService.getAll();
    final auditEntries = await const NovaRepairAuditLedgerService().getAll();
    if (!mounted) return;
    setState(() {
      _issues = result.issues;
      _capabilities = result.capabilities;
      _history = history;
      _auditEntries = auditEntries;
      _loading = false;
      _status = result.message;
    });
  }

  Future<void> _stageOwnerPatchAndRepair() async {
    setState(() {
      _running = false;
      _status =
          'Kör kod/owner patch alanı güvenli self-repair kernel tarafından kapatıldı. Artık yalnız AuditLedger/RepairGateway onaylı runtime policy repair çalışır.';
    });
  }

  String _ownerTargetAreaFor(NovaSystemIssue issue) {
    switch (issue.capabilityId.trim().toLowerCase()) {
      case 'speech_response':
        return 'speech_response';
      case 'speech_understanding':
        return 'speech_understanding';
      default:
        return 'speech_and_understanding';
    }
  }

  NovaSystemIssue? issueFallback() {
    for (final issue in _issues) {
      if (issue.canRequestOwnerPatch) return issue;
    }
    return _issues.isNotEmpty ? _issues.first : null;
  }

  Future<void> _saveSettings() async {
    final current = await widget.settingsService.load();
    await widget.settingsService.save(
      current.copyWith(
        commandRepairEnabled: _commandEnabled,
        manualRepairEnabled: _manualEnabled,
        voiceNarrationEnabled: _voiceEnabled,
        autoRepairSafeIssues: _autoRepairEnabled,
      ),
    );
    if (!mounted) return;
    setState(() => _status = 'Onarım ayarları kaydedildi.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistan Onarım Paneli')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _status,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: _commandEnabled,
                          onChanged: (v) => setState(() => _commandEnabled = v),
                          title: const Text('Komutla onarım açık'),
                        ),
                        SwitchListTile(
                          value: _manualEnabled,
                          onChanged: (v) => setState(() => _manualEnabled = v),
                          title: const Text('Manuel onarım açık'),
                        ),
                        SwitchListTile(
                          value: _voiceEnabled,
                          onChanged: (v) => setState(() => _voiceEnabled = v),
                          title: const Text('Sesli anlatım açık'),
                        ),
                        SwitchListTile(
                          value: _autoRepairEnabled,
                          onChanged: (v) =>
                              setState(() => _autoRepairEnabled = v),
                          title: const Text(
                            'Güvenli sorunlarda otomatik onarım',
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _saveSettings,
                          child: const Text('Ayarları Kaydet'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_ownerPatchIssue != null)
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Seçili Sorun Alanı'),
                          const SizedBox(height: 6),
                          SelectableText(
                            _ownerPatchIssue!.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            _ownerPatchIssue!.technicalMessage,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Asistanın Tanıdığı Sistemler'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonal(
                              onPressed: _loading || _running
                                  ? null
                                  : _runSelfRecognitionRefresh,
                              child: const Text('Kendini Tanı'),
                            ),
                            FilledButton.tonal(
                              onPressed: _loading || _running
                                  ? null
                                  : _runDebugScan,
                              child: const Text('Hata Ayıkla'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_capabilities.isEmpty)
                          const Text('Henüz güvenli işlev özeti oluşmadı.')
                        else
                          ..._capabilities.map(
                            (cap) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(cap.title),
                              subtitle: Text(
                                '${cap.humanSummary}\n${cap.technicalSummary}\nDurum: ${cap.healthSummary}',
                              ),
                              trailing: cap.selfRepairAllowed
                                  ? const Chip(label: Text('Otomatik onarım'))
                                  : const Chip(label: Text('Özet')),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Komutla Onarım'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _requestController,
                          decoration: const InputDecoration(
                            hintText:
                                'Örn: asistan dinleme işlevinde problem var kendini onar',
                            border: OutlineInputBorder(),
                          ),
                          minLines: 2,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _running ? null : _runCommandRepair,
                          child: const Text('Komutla Onarımı Başlat'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tespit Edilen Sorunlar'),
                        const SizedBox(height: 8),
                        if (_issues.isEmpty)
                          const Text('Aktif sorun görünmüyor.')
                        else
                          ..._issues.map(
                            (issue) => Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              color: _ownerPatchIssue?.issueId == issue.issueId
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : null,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _running
                                    ? null
                                    : () => _selectIssue(issue),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SelectableText(
                                        issue.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(issue.humanMessage),
                                      const SizedBox(height: 6),
                                      SelectableText(
                                        'Sorunlu kod özeti: ${issue.technicalMessage}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 6),
                                      SelectableText(
                                        'Issue ID: ${issue.issueId}\nCapability: ${issue.capabilityId}\nİlgili sinyaller: ${issue.relatedSignalIds.isEmpty ? "yok" : issue.relatedSignalIds.join(', ')}\nÖneri: ${issue.suggestedAction}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 6),
                                      ExpansionTile(
                                        tilePadding: EdgeInsets.zero,
                                        childrenPadding: EdgeInsets.zero,
                                        title: const Text(
                                          'Sorunlu alan ayrıntısı',
                                        ),
                                        subtitle: const Text(
                                          'Teknik özet ve seçili onarım alanı burada görünür',
                                        ),
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                            ),
                                            child: SelectableText(
                                              issue.technicalMessage,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          issue.canSelfHeal
                                              ? const Chip(
                                                  label: Text(
                                                    'Otomatik onarım',
                                                  ),
                                                )
                                              : const Chip(
                                                  label: Text('Sahip gerekli'),
                                                ),
                                          if (_manualEnabled)
                                            TextButton(
                                              onPressed: _running
                                                  ? null
                                                  : () =>
                                                        _runManualRepairForIssue(
                                                          issue,
                                                        ),
                                              child: const Text('Kendini Onar'),
                                            ),
                                          if (_manualEnabled)
                                            TextButton(
                                              onPressed: _running
                                                  ? null
                                                  : () =>
                                                        _runOwnerApprovedSafeRepair(
                                                          issue,
                                                        ),
                                              child: const Text(
                                                'Sahip Onaylı Güvenli Repair',
                                              ),
                                            ),
                                          TextButton(
                                            onPressed: _running
                                                ? null
                                                : () => _selectIssue(issue),
                                            child: Text(
                                              issue.canRequestOwnerPatch
                                                  ? 'Sorun Alanı Olarak Seç'
                                                  : 'Alanda İncele',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        const Text(
                          'Bu panel sistem özeti, güvenli onarım akışı ve sorun geçmişini gösterir.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kör Kod / Owner Patch Alanı Kapalı'),
                        SizedBox(height: 8),
                        Text(
                          'Bu alan güvenlik nedeniyle devre dışı bırakıldı. Nova yeni dosya oluşturamaz, script çalıştıramaz, tam dosya rewrite yapamaz ve lib/security/native kapalı kapılarına dokunamaz. Düzeltmeler yalnız deterministik RepairGateway + AuditLedger üzerinden izinli runtime policy alanlarında yapılır.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Düzeltme / Hata / Değiştirme Audit Raporları',
                        ),
                        const SizedBox(height: 8),
                        if (_auditEntries.isEmpty)
                          const Text('Audit kaydı yok.')
                        else
                          ..._auditEntries
                              .take(25)
                              .map(
                                (entry) => ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: Text(
                                    '${entry.category} • ${entry.riskLevel.isEmpty ? "risk yok" : entry.riskLevel}',
                                  ),
                                  subtitle: Text(entry.title),
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: SelectableText(
                                        'Detay: ${entry.detail}\n'
                                        'Manifest: ${entry.manifestId}\n'
                                        'Target: ${entry.targetPolicy}\n'
                                        'Eski değer: ${entry.oldValue}\n'
                                        'Yeni değer: ${entry.newValue}\n'
                                        'Security decision: ${entry.securityDecision}\n'
                                        'Validation: ${entry.validationResult}\n'
                                        'Rollback: ${entry.rollbackKey}\n'
                                        'AI yazdı mı: ${entry.aiAuthored}\n'
                                        'Owner onayı: ${entry.userApproved}\n'
                                        'Zaman: ${entry.createdAt}',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Geçmiş Onarım İzleri'),
                        const SizedBox(height: 8),
                        if (_history.isEmpty)
                          const Text('Kayıt yok.')
                        else
                          ..._history.map(
                            (entry) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${entry.issueCode} • ${entry.decisionLevel}',
                              ),
                              subtitle: Text(entry.solutionSummary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
