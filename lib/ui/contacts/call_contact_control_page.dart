// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../core/contacts/contact_role.dart';
import '../../core/contacts/device_contact_entry.dart';
import '../../core/contacts/nova_contact.dart';
import '../../services/contacts/nova_contact_service.dart';
import '../../services/contacts/nova_device_contacts_bridge_service.dart';

class CallContactControlPage extends StatefulWidget {
  final NovaContactService contactService;
  final NovaDeviceContactsBridgeService? deviceContactsBridgeService;

  const CallContactControlPage({
    super.key,
    required this.contactService,
    this.deviceContactsBridgeService,
  });

  @override
  State<CallContactControlPage> createState() => _CallContactControlPageState();
}

class _CallContactControlPageState extends State<CallContactControlPage> {
  List<NovaContact> _contacts = const <NovaContact>[];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _syncMessage = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _customRoleController = TextEditingController();
  final TextEditingController _persistentMessageController =
      TextEditingController();

  ContactRole _selectedRole = ContactRole.friend;
  String _selectedCloseness = 'normal';

  static const Color _creamSurface = Color(0xFFFFF3EA);
  static const Color _creamCard = Color(0xFFFFF8F1);
  static const Color _creamBorder = Color(0xFFE7CFC4);
  static const Color _reactorRed = Color(0xFFED2C2E);
  static const Color _deepRed = Color(0xFF5E0A0C);

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _customRoleController.dispose();
    _persistentMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final contacts = await widget.contactService.loadContacts();
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  Future<void> _syncFromDeviceContacts() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
      _syncMessage = '';
    });

    final entries = await widget.contactService.fetchSelectableDeviceContacts();
    if (!mounted) return;

    if (entries.isEmpty) {
      setState(() {
        _isSyncing = false;
        _syncMessage =
            'Rehberden seçilebilir kişi alınamadı. İzinleri kontrol edin efendim.';
      });
      return;
    }

    final selected = await _pickDeviceContacts(entries);
    if (!mounted) return;

    if (selected == null || selected.isEmpty) {
      setState(() {
        _isSyncing = false;
        _syncMessage = 'Rehberden kişi seçimi iptal edildi.';
      });
      return;
    }

    final result = await widget.contactService.mergeSelectedDeviceContacts(
      selected,
    );
    if (!mounted) return;
    setState(() {
      _contacts = result.contacts;
      _isSyncing = false;
      _syncMessage = result.message;
    });

    final firstSelected = selected.first;
    final imported = result.contacts
        .where(
          (contact) =>
              contact.phoneNumber.trim() == firstSelected.phoneNumber.trim() ||
              contact.displayName.trim().toLowerCase() ==
                  firstSelected.displayName.trim().toLowerCase(),
        )
        .toList(growable: false);
    if (imported.isNotEmpty) {
      await _editContactCustomization(imported.first);
    }
  }

  Future<List<DeviceContactEntry>?> _pickDeviceContacts(
    List<DeviceContactEntry> entries,
  ) async {
    final selectedIds = <String>{};
    String query = '';

    return showDialog<List<DeviceContactEntry>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = entries
                .where((entry) {
                  final q = query.trim().toLowerCase();
                  if (q.isEmpty) return true;
                  return entry.displayName.toLowerCase().contains(q) ||
                      entry.phoneNumber.toLowerCase().contains(q);
                })
                .toList(growable: false);

            return AlertDialog(
              title: const Text('Rehberden kişi seç'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Ara',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setModalState(() => query = value),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 320,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          final id = entry.id.isEmpty
                              ? entry.phoneNumber
                              : entry.id;
                          final checked = selectedIds.contains(id);
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (value) {
                              setModalState(() {
                                if (value == true) {
                                  selectedIds.add(id);
                                } else {
                                  selectedIds.remove(id);
                                }
                              });
                            },
                            title: Text(entry.displayName),
                            subtitle: Text(entry.phoneNumber),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: () {
                    final selected = entries
                        .where((entry) {
                          final id = entry.id.isEmpty
                              ? entry.phoneNumber
                              : entry.id;
                          return selectedIds.contains(id);
                        })
                        .toList(growable: false);
                    Navigator.of(context).pop(selected);
                  },
                  child: const Text('Seçili Kişileri Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openAppSettingsForContacts() async {
    final bridge = widget.deviceContactsBridgeService;
    if (bridge == null) return;
    await bridge.openAppSettings();
  }

  Future<void> _addContact() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) return;
    final contact = NovaContact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      displayName: name,
      phoneNumber: phone,
      role: _selectedRole,
      customRoleLabel: _selectedRole == ContactRole.custom
          ? _customRoleController.text.trim()
          : null,
      persistentOwnerMessage: _persistentMessageController.text.trim(),
      closenessLevel: _selectedCloseness,
      isVoiceKnown: false,
      isAuthorizedToUseNova: false,
      canReceiveAutoCallHandling: false,
    );
    final updated = await widget.contactService.addContact(contact);
    if (!mounted) return;
    setState(() {
      _contacts = updated;
      _nameController.clear();
      _phoneController.clear();
      _customRoleController.clear();
      _persistentMessageController.clear();
      _selectedRole = ContactRole.friend;
      _selectedCloseness = 'normal';
      _syncMessage = 'Kişi manuel olarak eklendi.';
    });
  }

  Future<void> _toggleAuthority(
    NovaContact contact, {
    bool? allowUse,
    bool? allowCallHandling,
  }) async {
    if (contact.isProtectedIdentity && allowUse == false) return;
    final updated = contact.copyWith(
      isAuthorizedToUseNova: allowUse ?? contact.isAuthorizedToUseNova,
      canReceiveAutoCallHandling:
          allowCallHandling ?? contact.canReceiveAutoCallHandling,
    );
    final result = await widget.contactService.updateContact(updated);
    if (!mounted) return;
    setState(() {
      _contacts = result;
    });
  }

  Future<void> _changeContactRole(NovaContact contact, ContactRole role) async {
    String? customRoleLabel = contact.customRoleLabel;
    if (role == ContactRole.custom) {
      customRoleLabel = await _askCustomRelationshipLabel(
        initialValue: contact.customRoleLabel ?? contact.relationshipLabel,
      );
      if (customRoleLabel == null) {
        return;
      }
    }
    final resolvedCustomRoleLabel = (customRoleLabel ?? '').trim();
    final updated = await widget.contactService.updateContact(
      contact.copyWith(
        role: role,
        customRoleLabel: role == ContactRole.custom
            ? resolvedCustomRoleLabel
            : null,
        relationshipLabel: role == ContactRole.custom
            ? resolvedCustomRoleLabel
            : role.label,
      ),
    );
    if (!mounted) return;
    setState(() {
      _contacts = updated;
      _syncMessage = '${contact.displayName} için yakınlık rolü güncellendi.';
    });
  }

  Future<String?> _askCustomRelationshipLabel({
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Özel yakınlık yazısı'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Örn: Patronum, Kuzenim, Eniştem',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _editContactCustomization(NovaContact contact) async {
    final openingController = TextEditingController(
      text: contact.callOpeningInstruction,
    );
    final questionsController = TextEditingController(
      text: contact.expectedCallerQuestions,
    );
    final allowedController = TextEditingController(
      text: contact.allowedResponseScope,
    );
    final blockedController = TextEditingController(
      text: contact.blockedResponseScope,
    );
    final emergencyController = TextEditingController(
      text: contact.emergencyInstruction,
    );
    final whiteLieController = TextEditingController(
      text: contact.whiteLieInstruction,
    );
    final quickReplyController = TextEditingController(
      text: contact.quickReplyInstruction,
    );
    var allowEmergencyWake = contact.allowEmergencyWake;
    var autoTakeNotes = contact.autoTakeNotes;
    var allowNightAutoCall = contact.allowNightAutoCall;
    var preferSpeakerMode = contact.preferSpeakerMode;
    var allowSmallTalk = contact.allowNovaSmallTalk;

    final result = await showDialog<NovaContact>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(
                '${contact.spokenDisplayName} için çağrı özelleştirme',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Nova bu kişiyle konuşurken bu alanları hotpath/tek omurga bağlamına ekler. Yetki ve güvenlik sınırları aşılmaz.',
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: openingController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Özel açılış / karşılama',
                          hintText:
                              'Örn: Annem ararsa daha sıcak karşıla ve panik yapmamasını söyle.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: questionsController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Bu kişi ne sorabilir?',
                          hintText:
                              'Örn: Nerede olduğumu, uyanıp uyanmadığımı, acil dönüş isteyebilir.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: allowedController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Nova hangi konularda cevap verebilir?',
                          hintText:
                              'Örn: Uyuduğumu, müsait olmadığımı, not alabileceğini söyleyebilir.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: blockedController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Nova hangi konulara girmesin?',
                          hintText:
                              'Örn: Konum, özel mesajlar, finansal bilgiler, kişisel detaylar.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emergencyController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Acil durumda ne yapsın?',
                          hintText:
                              'Örn: Acil derse ısrarlı uyandırma başlat, notu öne çıkar.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: whiteLieController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Sosyal uygun cevap çizgisi',
                          hintText:
                              'Örn: Uyuyorum/duştayım/araç kullanıyorum gibi owner tarafından izinli uygun cevaplar.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: quickReplyController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText:
                              'Hazır kısa yanıt / kapat ve yanıtla metni',
                          hintText:
                              'Örn: Şu an müsait değilim, acilse Nova not alsın.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Acil durumda kullanıcıyı uyandırabilir',
                        ),
                        subtitle: const Text(
                          'Sadece kayıtlı ve çağrı yetkisi açık kişilerde geçerlidir.',
                        ),
                        value: allowEmergencyWake,
                        onChanged: (value) =>
                            setModalState(() => allowEmergencyWake = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Çağrı notu alabilir'),
                        value: autoTakeNotes,
                        onChanged: (value) =>
                            setModalState(() => autoTakeNotes = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Gece modu otomatik cevap izni'),
                        subtitle: const Text(
                          'Bu açık değilse gece modunda bile normal telefon akışı korunur.',
                        ),
                        value: allowNightAutoCall,
                        onChanged: (value) =>
                            setModalState(() => allowNightAutoCall = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hoparlör modu tercihli'),
                        value: preferSpeakerMode,
                        onChanged: (value) =>
                            setModalState(() => preferSpeakerMode = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Kısa companion sohbetine izin ver'),
                        value: allowSmallTalk,
                        onChanged: (value) =>
                            setModalState(() => allowSmallTalk = value),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      contact.copyWith(
                        callOpeningInstruction: openingController.text.trim(),
                        expectedCallerQuestions: questionsController.text
                            .trim(),
                        allowedResponseScope: allowedController.text.trim(),
                        blockedResponseScope: blockedController.text.trim(),
                        emergencyInstruction: emergencyController.text.trim(),
                        whiteLieInstruction: whiteLieController.text.trim(),
                        quickReplyInstruction: quickReplyController.text.trim(),
                        allowEmergencyWake: allowEmergencyWake,
                        autoTakeNotes: autoTakeNotes,
                        allowNightAutoCall: allowNightAutoCall,
                        preferSpeakerMode: preferSpeakerMode,
                        allowNovaSmallTalk: allowSmallTalk,
                      ),
                    );
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    openingController.dispose();
    questionsController.dispose();
    allowedController.dispose();
    blockedController.dispose();
    emergencyController.dispose();
    whiteLieController.dispose();
    quickReplyController.dispose();

    if (result == null) return;
    final updated = await widget.contactService.updateContact(result);
    if (!mounted) return;
    setState(() {
      _contacts = updated;
      _syncMessage =
          '${contact.spokenDisplayName} için çağrı özelleştirmesi güncellendi.';
    });
  }

  Future<void> _removeContact(String id) async {
    final updated = await widget.contactService.removeContact(id);
    if (!mounted) return;
    setState(() {
      _contacts = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasDeviceBridge = widget.deviceContactsBridgeService != null;
    return Scaffold(
      backgroundColor: _creamSurface,
      appBar: AppBar(
        title: const Text('Çağrı ve Companion Kişi Yönetimi'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: _deepRed,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: _creamCard,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: const BorderSide(color: _creamBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Telefon Rehberi Eşitleme',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Çağrı ve companion için ortak kişi havuzu burasıdır. Telefon rehberinden toplu değil, seçerek kişi ekleyebilir; ardından çağrı yönetimi yetkisi verebilirsiniz.',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: _reactorRed,
                                  foregroundColor: _creamCard,
                                ),
                                onPressed: !_isSyncing && hasDeviceBridge
                                    ? _syncFromDeviceContacts
                                    : null,
                                icon: const Icon(Icons.sync),
                                label: Text(
                                  _isSyncing
                                      ? 'Hazırlanıyor...'
                                      : 'Rehberden Seçerek Ekle',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _deepRed,
                            side: const BorderSide(color: _creamBorder),
                          ),
                          onPressed: hasDeviceBridge
                              ? _openAppSettingsForContacts
                              : null,
                          child: const Text('Kişi İzni / Uygulama Ayarları'),
                        ),
                        if (_syncMessage.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _syncMessage,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: _creamCard,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: const BorderSide(color: _creamBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Yeni Kişi Ekle',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Ad',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Telefon Numarası',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ContactRole>(
                          initialValue: _selectedRole,
                          items: ContactRole.values
                              .map(
                                (role) => DropdownMenuItem<ContactRole>(
                                  value: role,
                                  child: Text(role.label),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedRole = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Rol',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (_selectedRole == ContactRole.custom) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _customRoleController,
                            decoration: const InputDecoration(
                              labelText: 'Özel Rol Metni',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCloseness,
                          items: const [
                            DropdownMenuItem(
                              value: 'very_close',
                              child: Text('Yakınlık: Çok yakın'),
                            ),
                            DropdownMenuItem(
                              value: 'close',
                              child: Text('Yakınlık: Yakın'),
                            ),
                            DropdownMenuItem(
                              value: 'normal',
                              child: Text('Yakınlık: Normal'),
                            ),
                            DropdownMenuItem(
                              value: 'distant',
                              child: Text('Yakınlık: Uzak'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedCloseness = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Yakınlık derecesi',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _persistentMessageController,
                          decoration: const InputDecoration(
                            labelText: 'Kalıcı mesaj (opsiyonel)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _reactorRed,
                              foregroundColor: _creamCard,
                            ),
                            onPressed: _addContact,
                            child: const Text('Kişi Ekle'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._contacts.map(_buildContactCard),
              ],
            ),
    );
  }

  Widget _buildContactCard(NovaContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _creamCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: _creamBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    contact.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _deepRed,
                    ),
                  ),
                ),
                PopupMenuButton<ContactRole>(
                  tooltip: 'Yakınlık rolünü değiştir',
                  onSelected: (role) => _changeContactRole(contact, role),
                  itemBuilder: (context) => ContactRole.values
                      .map(
                        (role) => PopupMenuItem<ContactRole>(
                          value: role,
                          child: Text(role.label),
                        ),
                      )
                      .toList(growable: false),
                  icon: const Icon(Icons.edit_note),
                ),
                if (contact.isProtectedIdentity)
                  const Chip(
                    label: Text('Sabit yetki'),
                    avatar: Icon(Icons.verified_user, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Rol: ${contact.role.label}${contact.role == ContactRole.custom && (contact.customRoleLabel?.trim().isNotEmpty ?? false) ? ' • ${contact.customRoleLabel!.trim()}' : ''}',
            ),
            Text('Telefon: ${contact.phoneNumber}'),
            Text('Arama metni: ${contact.incomingCallText}'),
            Text('Aile hitabı: ${contact.relationshipSpeech}'),
            Text('Yakınlık: ${contact.closenessSpeech}'),
            Text('Kalıcı mesaj: ${contact.defaultPersistentOwnerMessage}'),
            Text('Özelleştirme: ${contact.customizationSummary}'),
            if (contact.callOpeningInstruction.trim().isNotEmpty)
              Text('Açılış: ${contact.callOpeningInstruction.trim()}'),
            if (contact.expectedCallerQuestions.trim().isNotEmpty)
              Text(
                'Beklenen sorular: ${contact.expectedCallerQuestions.trim()}',
              ),
            if (contact.allowedResponseScope.trim().isNotEmpty)
              Text('Cevap kapsamı: ${contact.allowedResponseScope.trim()}'),
            if (contact.blockedResponseScope.trim().isNotEmpty)
              Text('Yasak kapsam: ${contact.blockedResponseScope.trim()}'),
            if (contact.emergencyInstruction.trim().isNotEmpty)
              Text('Acil durum: ${contact.emergencyInstruction.trim()}'),
            if (contact.quickReplyInstruction.trim().isNotEmpty)
              Text('Hazır yanıt: ${contact.quickReplyInstruction.trim()}'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _deepRed,
                  side: const BorderSide(color: _creamBorder),
                ),
                onPressed: () => _editContactCustomization(contact),
                icon: const Icon(Icons.tune),
                label: const Text('Özelleştir'),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Çağrı kişisi ekranında ses yetkisi yönetilmez',
              ),
              value: contact.isAuthorizedToUseNova,
              onChanged: contact.isProtectedIdentity
                  ? null
                  : (value) => _toggleAuthority(contact, allowUse: value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Çağrı devralma yetkisi'),
              value: contact.canReceiveAutoCallHandling,
              onChanged: (value) =>
                  _toggleAuthority(contact, allowCallHandling: value),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: _reactorRed),
                onPressed: contact.isProtectedIdentity
                    ? null
                    : () => _removeContact(contact.id),
                child: Text(
                  contact.isProtectedIdentity ? 'Korunan kişi' : 'Sil',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
