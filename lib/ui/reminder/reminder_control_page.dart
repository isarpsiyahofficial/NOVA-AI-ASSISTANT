// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../core/reminder/nova_reminder.dart';
import '../../services/reminder/nova_reminder_command_service.dart';
import '../../services/reminder/nova_reminder_service.dart';
import '../../services/reminder/nova_reminder_service.dart'
    show NovaReminderItem;

class ReminderControlPage extends StatefulWidget {
  final NovaReminderService reminderService;
  final NovaReminderCommandService reminderCommandService;

  const ReminderControlPage({
    super.key,
    required this.reminderService,
    required this.reminderCommandService,
  });

  @override
  State<ReminderControlPage> createState() => _ReminderControlPageState();
}

class _ReminderControlPageState extends State<ReminderControlPage> {
  final TextEditingController _quickCommandController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDueAt;
  bool _wakeAlarm = false;
  bool _loading = true;
  bool _saving = false;
  List<NovaReminderItem> _items = const <NovaReminderItem>[];
  String _status = '';

  @override
  void initState() {
    super.initState();
    _selectedDueAt = DateTime.now().add(const Duration(minutes: 10));
    _load();
  }

  @override
  void dispose() {
    _quickCommandController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await widget.reminderService.getAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _saveManual() async {
    final dueAt = _selectedDueAt;
    final title = _titleController.text.trim();
    if (dueAt == null || title.isEmpty) {
      setState(() {
        _status = 'Başlık ve zaman zorunludur.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _status = '';
    });

    await widget.reminderService.add(
      text: title,
      dueAt: dueAt,
      kind: _wakeAlarm ? NovaReminderKind.wakeAlarm : NovaReminderKind.reminder,
      repeatUntilAcknowledged: _wakeAlarm,
      maxActiveMinutes: _wakeAlarm ? 10 : 10,
    );

    _titleController.clear();
    _wakeAlarm = false;
    await _load();

    if (!mounted) return;
    setState(() {
      _saving = false;
      _status = 'Hatırlatıcı kaydedildi.';
    });
  }

  Future<void> _saveQuickCommand() async {
    final text = _quickCommandController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _status = 'Hızlı komut boş olamaz.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _status = '';
    });

    final result = await widget.reminderCommandService.createFromText(
      text,
      reminderService: widget.reminderService,
    );

    _quickCommandController.clear();
    await _load();

    if (!mounted) return;
    setState(() {
      _saving = false;
      _status = result.message;
    });
  }

  Future<void> _pickDueAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueAt ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDueAt ?? now),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _complete(String id) async {
    await widget.reminderService.complete(id);
    await _load();
  }

  Future<void> _cancel(String id) async {
    await widget.reminderService.cancel(id);
    await _load();
  }

  Future<void> _delete(String id) async {
    await widget.reminderService.delete(id);
    await _load();
  }

  String _formatDate(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year} ${two(value.hour)}:${two(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hatırlatıcı kontrol')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _quickCommandController,
                  decoration: const InputDecoration(
                    labelText: 'Hızlı komut',
                    hintText: 'Örn: 2 saat sonra beni uyandır',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saving ? null : _saveQuickCommand,
                  child: const Text('Hızlı komutu kaydet'),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Zaman'),
                  subtitle: Text(_formatDate(_selectedDueAt ?? DateTime.now())),
                  trailing: const Icon(Icons.schedule),
                  onTap: _pickDueAt,
                ),
                SwitchListTile(
                  value: _wakeAlarm,
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _wakeAlarm = value;
                          });
                        },
                  title: const Text('Uyanma alarmı olarak kaydet'),
                ),
                FilledButton(
                  onPressed: _saving ? null : _saveManual,
                  child: const Text('Manuel hatırlatıcı ekle'),
                ),
                if (_status.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_status),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Kayıtlı hatırlatıcılar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (_items.isEmpty)
                  const Text('Kayıtlı hatırlatıcı bulunmuyor.')
                else
                  ..._items.map(
                    (item) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('${item.kind} • ${_formatDate(item.dueAt)}'),
                            const SizedBox(height: 4),
                            Text('Durum: ${item.status.name}'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: item.completed
                                      ? null
                                      : () => _complete(item.id),
                                  child: const Text('Tamamlandı'),
                                ),
                                OutlinedButton(
                                  onPressed: item.completed
                                      ? null
                                      : () => _cancel(item.id),
                                  child: const Text('İptal'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _delete(item.id),
                                  child: const Text('Sil'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
