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
  bool _loading = true;
  bool _busy = false;
  List<NovaLearnedItem> _items = const <NovaLearnedItem>[];

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
    setState(() => _busy = true);
    await widget.registryService.deleteLearnedItem(item);
    await _restore();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Öğrenilen kayıt silindi.')));
  }

  Future<void> _clearAll() async {
    setState(() => _busy = true);
    await widget.registryService.clearAllLearnedItems();
    await _restore();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kalıcı öğrenilen kayıtlar temizlendi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğrenilenler'),
        actions: [
          IconButton(
            onPressed: _busy || _loading || _items.isEmpty ? null : _clearAll,
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Tümünü temizle',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Kalıcı öğrenilen bir kayıt görünmüyor.\nDavranış öğrenimleri ve kalıcı hafıza kayıtları burada listelenir.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(item.description),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Kaynak: ${item.source} • ${item.updatedAt}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            if (item.canDelete)
                              IconButton(
                                onPressed: _busy
                                    ? null
                                    : () => _deleteItem(item),
                                icon: const Icon(Icons.delete_outline_rounded),
                                tooltip: 'Sil',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
