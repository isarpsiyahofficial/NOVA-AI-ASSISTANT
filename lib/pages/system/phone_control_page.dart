// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../core/phone_control/phone_control_task.dart';
import '../../services/phone_control/phone_control_execution_service.dart';
import '../../services/phone_control/phone_control_guard_service.dart';
import '../../services/phone_control/phone_control_service.dart';
import '../../services/phone_control/phone_control_task_service.dart';

class PhoneControlPage extends StatefulWidget {
  final PhoneControlService phoneControlService;
  final PhoneControlTaskService taskService;
  final PhoneControlExecutionService executionService;
  final PhoneControlGuardService guardService;

  const PhoneControlPage({
    super.key,
    required this.phoneControlService,
    required this.taskService,
    required this.executionService,
    required this.guardService,
  });

  @override
  State<PhoneControlPage> createState() => _PhoneControlPageState();
}

class _PhoneControlPageState extends State<PhoneControlPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _stepControllers =
      List<TextEditingController>.generate(5, (_) => TextEditingController());

  List<PhoneControlTask> _tasks = const <PhoneControlTask>[];
  bool _loading = true;
  bool _saving = false;
  bool _userRespondedToWarning = false;
  String _guardMessage = '';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _restore() async {
    await widget.phoneControlService.restore();
    final tasks = await widget.taskService.getAll();
    await _checkGuard();

    if (!mounted) return;

    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _checkGuard() async {
    final decision = widget.guardService.evaluate(
      state: widget.phoneControlService.state,
      timeoutMinutes: 60,
      userRespondedToWarning: _userRespondedToWarning,
    );

    if (decision.shouldWarn) {
      _guardMessage = decision.message;
      await widget.phoneControlService.markReminderSent();
      return;
    }

    if (decision.shouldAutoDisable) {
      _guardMessage = decision.message;
      await widget.phoneControlService.disable();
      return;
    }

    _guardMessage = '';
  }

  Future<void> _togglePhoneControl(bool enable) async {
    setState(() {
      _saving = true;
    });

    if (enable) {
      await widget.phoneControlService.enable();
    } else {
      await widget.phoneControlService.disable();
    }

    await _checkGuard();

    if (!mounted) return;

    setState(() {
      _saving = false;
      _userRespondedToWarning = true;
    });
  }

  Future<void> _addTask() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final steps = _stepControllers
        .map((e) => e.text.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    if (title.isEmpty || steps.isEmpty) return;

    setState(() {
      _saving = true;
    });

    await widget.taskService.addTask(
      title: title,
      description: description,
      steps: steps,
    );

    final tasks = await widget.taskService.getAll();

    if (!mounted) return;

    setState(() {
      _tasks = tasks;
      _saving = false;
      _titleController.clear();
      _descriptionController.clear();
      for (final c in _stepControllers) {
        c.clear();
      }
    });
  }

  Future<void> _runTask(PhoneControlTask task) async {
    setState(() {
      _saving = true;
    });

    final result = await widget.executionService.executeTask(task: task);
    final tasks = await widget.taskService.getAll();

    if (!mounted) return;

    setState(() {
      _tasks = tasks;
      _saving = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _removeTask(String id) async {
    setState(() {
      _saving = true;
    });

    await widget.taskService.removeTask(id);
    final tasks = await widget.taskService.getAll();

    if (!mounted) return;

    setState(() {
      _tasks = tasks;
      _saving = false;
    });
  }

  String _statusText(PhoneControlTaskStatus status) {
    switch (status) {
      case PhoneControlTaskStatus.pending:
        return 'Bekliyor';
      case PhoneControlTaskStatus.running:
        return 'Çalışıyor';
      case PhoneControlTaskStatus.completed:
        return 'Tamamlandı';
      case PhoneControlTaskStatus.failed:
        return 'Başarısız';
      case PhoneControlTaskStatus.cancelled:
        return 'İptal';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final enabled = widget.phoneControlService.isEnabled;

    return Scaffold(
      appBar: AppBar(title: const Text('Telefon Yönetimi'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Telefon Yönetimi Durumu',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: enabled,
                    onChanged: _saving ? null : _togglePhoneControl,
                    title: const Text('Telefon yönetimi aktif'),
                    subtitle: const Text(
                      'Yalnızca siz izin verdiğinizde görev çalıştırır.',
                    ),
                  ),
                  if (_guardMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _guardMessage,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'Not: Gerçek native görev yürütme köprüsü bağlı değilse görevler sahte başarı yerine dürüst biçimde başarısız görünür.',
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
                children: [
                  Text(
                    'Yeni Görev Ekle',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._stepControllers.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: 'Adım ${entry.key + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _addTask,
                      child: const Text('Görevi Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._tasks.map(_buildTaskCard),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: Text('Telefon yönetimi verisi işleniyor...'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(PhoneControlTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (task.description.trim().isNotEmpty) Text(task.description),
            const SizedBox(height: 8),
            Text('Durum: ${_statusText(task.status)}'),
            const SizedBox(height: 8),
            ...task.steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $step'),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: _saving ? null : () => _runTask(task),
                  child: const Text('Çalıştır'),
                ),
                TextButton(
                  onPressed: _saving ? null : () => _removeTask(task.id),
                  child: const Text('Sil'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
