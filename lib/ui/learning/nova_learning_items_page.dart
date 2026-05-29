// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../core/learning/nova_learned_item.dart';
import '../../services/learning/nova_learning_registry_service.dart';

class NovaLearnedItemsPage extends StatefulWidget {
  final NovaLearningRegistryService registryService;

  const NovaLearnedItemsPage({super.key, required this.registryService});

  @override
  State<NovaLearnedItemsPage> createState() => _NovaLearnedItemsPageState();
}

class _NovaLearnedItemsPageState extends State<NovaLearnedItemsPage> {
  List<NovaLearnedItem> _items = const <NovaLearnedItem>[];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final items = await widget.registryService.getAllLearnedItems();

    if (!mounted) return;

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _deleteItem(NovaLearnedItem item) async {
    setState(() {
      _busy = true;
    });

    await widget.registryService.deleteLearnedItem(item);
    await _restore();

    if (!mounted) return;

    setState(() {
      _busy = false;
    });
  }

  Future<void> _clearAll() async {
    setState(() {
      _busy = true;
    });

    await widget.registryService.clearAllLearnedItems();
    await _restore();

    if (!mounted) return;

    setState(() {
      _busy = false;
    });
  }

  Future<void> _confirmDeleteItem(NovaLearnedItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Öğrenileni Sil'),
        content: Text(
          '${item.title} silinirse varsayılan moda dönülecek. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _deleteItem(item);
    }
  }

  Future<void> _confirmClearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tüm Öğrenilenleri Temizle'),
        content: const Text(
          'Tüm öğrenilen davranışlar ve öğrenilen çağrı cevapları silinecek. '
          'Sistem varsayılan moda dönecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _clearAll();
    }
  }

  void _openDetail(NovaLearnedItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      item.description.trim().isEmpty
                          ? 'Açıklama yok.'
                          : item.description.trim(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (item.canDelete)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: _busy
                          ? null
                          : () async {
                              Navigator.pop(context);
                              await _confirmDeleteItem(item);
                            },
                      child: const Text('Bunu Sil'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(NovaLearnedItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(
                item.description.trim().isEmpty
                    ? 'Açıklama yok.'
                    : item.description.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kaynak: ${item.source}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _busy ? null : () => _confirmDeleteItem(item),
                    child: const Text('Sil'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğrenilenler'),
        centerTitle: true,
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _busy ? null : _confirmClearAll,
              child: const Text('Temizle'),
            ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Henüz kayıtlı öğrenilen davranış yok.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._items.map(_buildItemCard),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Center(
                      child: Text('Öğrenilen veriler güncelleniyor...'),
                    ),
                  ),
              ],
            ),
    );
  }
}
