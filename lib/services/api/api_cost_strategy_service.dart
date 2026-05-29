// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/api/api_model_profile.dart';

enum ApiUsagePurpose { learning, research, fallback }

class ApiCostStrategyService {
  const ApiCostStrategyService();

  List<ApiModelProfile> get profiles => const <ApiModelProfile>[
    ApiModelProfile(
      id: 'cheap_learning_primary',
      label: 'Ucuz Öğrenme Modeli',
      costPriority: 1,
      suitableForLearning: true,
      suitableForResearch: true,
      suitableForFallback: true,
    ),
    ApiModelProfile(
      id: 'balanced_secondary',
      label: 'Dengeli İkinci Model',
      costPriority: 2,
      suitableForLearning: true,
      suitableForResearch: true,
      suitableForFallback: true,
    ),
    ApiModelProfile(
      id: 'strong_fallback',
      label: 'Güçlü Son Çare Model',
      costPriority: 3,
      suitableForLearning: true,
      suitableForResearch: true,
      suitableForFallback: true,
    ),
  ];

  ApiModelProfile chooseBest({required ApiUsagePurpose purpose}) {
    final eligible =
        profiles
            .where((profile) {
              switch (purpose) {
                case ApiUsagePurpose.learning:
                  return profile.suitableForLearning;
                case ApiUsagePurpose.research:
                  return profile.suitableForResearch;
                case ApiUsagePurpose.fallback:
                  return profile.suitableForFallback;
              }
            })
            .toList(growable: false)
          ..sort((a, b) => a.costPriority.compareTo(b.costPriority));

    if (eligible.isEmpty) {
      return const ApiModelProfile(
        id: 'cheap_learning_primary',
        label: 'Ucuz Öğrenme Modeli',
        costPriority: 1,
        suitableForLearning: true,
        suitableForResearch: true,
        suitableForFallback: true,
      );
    }

    return eligible.first;
  }

  List<ApiModelProfile> rankedForPurpose(ApiUsagePurpose purpose) {
    final eligible =
        profiles
            .where((profile) {
              switch (purpose) {
                case ApiUsagePurpose.learning:
                  return profile.suitableForLearning;
                case ApiUsagePurpose.research:
                  return profile.suitableForResearch;
                case ApiUsagePurpose.fallback:
                  return profile.suitableForFallback;
              }
            })
            .toList(growable: false)
          ..sort((a, b) => a.costPriority.compareTo(b.costPriority));

    return eligible;
  }
}
