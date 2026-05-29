// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../core/teaching/taught_workflow.dart';
import '../../services/teaching/taught_workflow_service.dart';
import '../../services/teaching/teaching_mode_service.dart';

class TeachingWorkflowPage extends StatefulWidget {
  final TaughtWorkflowService workflowService;
  final TeachingModeService teachingModeService;

  const TeachingWorkflowPage({
    super.key,
    required this.workflowService,
    required this.teachingModeService,
  });

  @override
  State<TeachingWorkflowPage> createState() => _TeachingWorkflowPageState();
}

class _TeachingWorkflowPageState extends State<TeachingWorkflowPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _triggerController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _stepControllers =
      List<TextEditingController>.generate(5, (_) => TextEditingController());

  List<TaughtWorkflow> _items = const <TaughtWorkflow>[];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _triggerController.dispose();
    _descriptionController.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _restore() async {
    final items = await widget.workflowService.getAll();

    if (!mounted) return;

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _saveWorkflow() async {
    final title = _titleController.text.trim();
    final trigger = _triggerController.text.trim();
    final description = _descriptionController.text.trim();
    final steps = _stepControllers
        .map((e) => e.text.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    if (title.isEmpty || trigger.isEmpty || steps.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
    });

    await widget.teachingModeService.teachWorkflow(
      title: title,
      triggerPhrase: trigger,
      description: description,
      steps: steps,
      teachingSource: 'manual_ui',
    );

    final items = await widget.workflowService.getAll();

    if (!mounted) return;

    setState(() {
      _items = items;
      _saving = false;
      _titleController.clear();
      _triggerController.clear();
      _descriptionController.clear();
      for (final c in _stepControllers) {
        c.clear();
      }
    });
  }

  Future<void> _disableWorkflow(String id) async {
    setState(() {
      _saving = true;
    });

    await widget.teachingModeService.disableWorkflow(id);
    final items = await widget.workflowService.getAll();

    if (!mounted) return;

    setState(() {
      _items = items;
      _saving = false;
    });
  }

  Future<void> _removeWorkflow(String id) async {
    setState(() {
      _saving = true;
    });

    await widget.teachingModeService.removeWorkflow(id);
    final items = await widget.workflowService.getAll();

    if (!mounted) return;

    setState(() {
      _items = items;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Öğretim Modu'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Yeni İş Akışı Öğret',
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
                    controller: _triggerController,
                    decoration: const InputDecoration(
                      labelText: 'Tetik cümlesi',
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
                      onPressed: _saving ? null : _saveWorkflow,
                      child: const Text('İş Akışını Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._items.map(_buildItemCard),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: Text('Öğretim verisi kaydediliyor...')),
            ),
        ],
      ),
    );
  }

  Widget _buildItemCard(TaughtWorkflow item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Tetik: ${item.triggerPhrase}'),
            if (item.description.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(item.description),
            ],
            const SizedBox(height: 8),
            ...item.steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $step'),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _saving ? null : () => _disableWorkflow(item.id),
                  child: const Text('Pasifleştir'),
                ),
                TextButton(
                  onPressed: _saving ? null : () => _removeWorkflow(item.id),
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
