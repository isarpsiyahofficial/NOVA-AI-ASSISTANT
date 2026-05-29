// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/learning/nova_learned_item.dart';
import '../../core/memory/memory_types.dart';
import '../behavior_control/behavior_override_service.dart';
import '../call_learning/learned_call_response_service.dart';
import '../memory/memory_service.dart';

class NovaLearningRegistryItem {
  final String id;
  final String title;
  final String detail;
  final DateTime createdAt;

  const NovaLearningRegistryItem({
    required this.id,
    required this.title,
    required this.detail,
    required this.createdAt,
  });
}

class NovaLearningRegistryService {
  final BehaviorOverrideService behaviorOverrideService;
  final LearnedCallResponseService learnedCallResponseService;
  final MemoryService memoryService;

  const NovaLearningRegistryService({
    required this.behaviorOverrideService,
    required this.learnedCallResponseService,
    this.memoryService = const MemoryService(),
  });

  Future<List<NovaLearningRegistryItem>> getAll() async {
    final overrides = await behaviorOverrideService.getAll();
    return overrides
        .map(
          (e) => NovaLearningRegistryItem(
            id: e.key,
            title: e.key,
            detail: e.instruction,
            createdAt: e.updatedAt,
          ),
        )
        .toList(growable: false);
  }

  Future<List<NovaLearnedItem>> getAllLearnedItems() async {
    final items = <NovaLearnedItem>[];

    final overrides = await getAll();
    items.addAll(
      overrides.map(
        (e) => NovaLearnedItem(
          id: e.id,
          type: NovaLearnedItemType.behaviorOverride,
          title: e.title,
          subtitle: 'Davranış öğrenimi',
          description: e.detail,
          source: 'override',
          updatedAt: e.createdAt,
          canDelete: true,
          deleteKey: e.id,
        ),
      ),
    );

    final learnedResponses = await learnedCallResponseService.getAll();
    items.addAll(
      learnedResponses.map(
        (e) => NovaLearnedItem(
          id: e.id,
          type: NovaLearnedItemType.learnedCallResponse,
          title: e.trigger,
          subtitle: 'Öğrenilmiş çağrı davranışı',
          description: e.responseText,
          source: 'call_learning',
          updatedAt: e.updatedAt,
          canDelete: true,
          deleteKey: e.id,
        ),
      ),
    );

    final memories = await memoryService.getAll();
    items.addAll(
      memories
          .where((e) => e.type == MemoryType.permanent)
          .map(
            (e) => NovaLearnedItem(
              id: e.id,
              type: NovaLearnedItemType.permanentMemory,
              title: 'Kalıcı hafıza kaydı',
              subtitle: 'Kalıcı öğrenilen bilgi',
              description: e.content,
              source: 'memory',
              updatedAt: e.createdAt,
              canDelete: true,
              deleteKey: e.id,
            ),
          ),
    );

    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<void> deleteLearnedItem(NovaLearnedItem item) async {
    if (item.type == NovaLearnedItemType.permanentMemory) {
      await memoryService.deleteById(item.deleteKey);
      return;
    }
    if (item.type == NovaLearnedItemType.learnedCallResponse) {
      await learnedCallResponseService.removeById(item.deleteKey);
      return;
    }
    if (item.deleteKey.trim().isNotEmpty) {
      await behaviorOverrideService.resetOverrideToDefault(item.deleteKey);
    }
  }

  Future<void> clearAllLearnedItems() async {
    await behaviorOverrideService.resetAllToDefault();
    await learnedCallResponseService.clearAll();
    await memoryService.deleteAllPermanent();
  }
}
