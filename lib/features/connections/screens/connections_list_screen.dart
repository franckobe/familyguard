import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../providers/connection_providers.dart';
import '../widgets/connection_card.dart';

class ConnectionsListScreen extends ConsumerStatefulWidget {
  const ConnectionsListScreen({super.key});

  @override
  ConsumerState<ConnectionsListScreen> createState() => _ConnectionsListScreenState();
}

class _ConnectionsListScreenState extends ConsumerState<ConnectionsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asParentAsync = ref.watch(connectionsAsParentProvider);
    final asCaregiverAsync = ref.watch(connectionsAsCaregiverProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('Connexions'),
        actions: [
          IconButton(
            onPressed: () => context.push('/connections/invite'),
            icon: const Icon(LucideIcons.userPlus, size: 20, color: AppColors.primaryLight),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.badgeNewText,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primaryLight,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: AppTextStyles.cardTitle,
          tabs: const [
            Tab(text: 'Mes babysitters'),
            Tab(text: 'Mes familles'),
          ],
        ),
      ),
      body: AppBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            asParentAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Erreur : $e', style: AppTextStyles.cardSubtitle),
              ),
              data: (connections) {
                if (connections.isEmpty) {
                  return const _EmptyState(
                    icon: LucideIcons.userPlus,
                    message: 'Aucun babysitter',
                    subtitle: 'Invitez un proche pour commencer',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: kToolbarHeight + 80, bottom: 96),
                  itemCount: connections.length,
                  itemBuilder: (_, i) => ConnectionCard(connection: connections[i]),
                );
              },
            ),
            asCaregiverAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Erreur : $e', style: AppTextStyles.cardSubtitle),
              ),
              data: (connections) {
                if (connections.isEmpty) {
                  return const _EmptyState(
                    icon: LucideIcons.users,
                    message: 'Pas encore de famille',
                    subtitle: 'Acceptez une invitation pour apparaître ici',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: kToolbarHeight + 80, bottom: 96),
                  itemCount: connections.length,
                  itemBuilder: (_, i) => ConnectionCard(connection: connections[i]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  final IconData icon;
  final String message;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: Icon(icon, size: 32, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.cardSubtitle),
        ],
      ),
    );
  }
}
