// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'cloned_voice_library_service.dart';
import 'voice_clone_cleanup_command_service.dart';

class VoiceCloneCleanupService {
  final ClonedVoiceLibraryService libraryService;
  final VoiceCloneCleanupCommandService commandService;

  const VoiceCloneCleanupService({
    required this.libraryService,
    required this.commandService,
  });

  Future<int> cleanup({String rawInput = ''}) async {
    final wantsAggressive =
        rawInput.trim().isNotEmpty &&
        commandService.parse(rawInput).removeNonFavorites;
    final removedRedundant = await libraryService
        .cleanupRedundantNonFavorites();
    if (!wantsAggressive) return removedRedundant;
    final removedNonFavorites = await libraryService.cleanupNonFavorites();
    return removedRedundant + removedNonFavorites;
  }
}
