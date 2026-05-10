import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../models/guard_request.dart';
import '../providers/guard_request_providers.dart';
import '../widgets/guard_request_card.dart';

class GuardRequestsListScreen extends ConsumerStatefulWidget {
  const GuardRequestsListScreen({super.key});

  @override
  ConsumerState<GuardRequestsListScreen> createState() => _GuardRequestsListScreenState();
}

class _GuardRequestsListScreenState extends ConsumerState<GuardRequestsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asParentAsync = ref.watch(guardRequestsAsParentProvider);
    final asCaregiverAsync = ref.watch(guardRequestsAsCaregiverProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('Gardes'),
        actions: [
          IconButton(
            onPressed: () => context.push('/guard-requests/create'),
            icon: const Icon(LucideIcons.plus, size: 20, color: AppColors.primaryLight),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.badgeNewText,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primaryLight,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: AppTextStyles.cardTitle,
          tabs: const [
            Tab(text: 'Mes demandes'),
            Tab(text: 'Gardes reçues'),
          ],
        ),
      ),
      body: AppBackground(
        child: TabBarView(
          controller: _tab,
          children: [
            _RequestsList(asyncValue: asParentAsync, isParent: true),
            _RequestsList(asyncValue: asCaregiverAsync, isParent: false),
          ],
        ),
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({required this.asyncValue, required this.isParent});

  final AsyncValue<List<GuardRequest>> asyncValue;
  final bool isParent;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e', style: AppTextStyles.cardSubtitle)),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.glassSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.glassBorder, width: 0.5),
                  ),
                  child: const Icon(LucideIcons.calendar, size: 32, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 16),
                Text(
                  isParent ? 'Aucune demande' : 'Aucune garde reçue',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  isParent ? 'Créez votre première demande' : 'Les demandes apparaîtront ici',
                  style: AppTextStyles.cardSubtitle,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: kToolbarHeight + 80, bottom: 96),
          itemCount: requests.length,
          itemBuilder: (_, i) => GuardRequestCard(request: requests[i], isParent: isParent),
        );
      },
    );
  }
}
