import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../models/connection.dart';
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
    final pendingAsync = ref.watch(pendingInvitationsProvider);

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
            _CaregiverTab(
              caregiverAsync: asCaregiverAsync,
              pendingAsync: pendingAsync,
              repo: ref.read(connectionRepositoryProvider),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaregiverTab extends StatelessWidget {
  const _CaregiverTab({
    required this.caregiverAsync,
    required this.pendingAsync,
    required this.repo,
  });

  final AsyncValue<List<Connection>> caregiverAsync;
  final AsyncValue<List<Connection>> pendingAsync;
  final dynamic repo;

  @override
  Widget build(BuildContext context) {
    final pending = pendingAsync.valueOrNull ?? [];
    final active = caregiverAsync.valueOrNull ?? [];
    final loading = caregiverAsync.isLoading || pendingAsync.isLoading;

    if (loading) return const Center(child: CircularProgressIndicator());

    if (pending.isEmpty && active.isEmpty) {
      return const _EmptyState(
        icon: LucideIcons.users,
        message: 'Pas encore de famille',
        subtitle: 'Un parent doit vous inviter dans l\'app',
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: kToolbarHeight + 80, bottom: 96),
      children: [
        if (pending.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Invitations en attente', style: AppTextStyles.cardSubtitle),
          ),
          ...pending.map((c) => _PendingInviteCard(connection: c, repo: repo)),
          const SizedBox(height: 8),
        ],
        if (active.isNotEmpty) ...[
          if (pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Mes familles', style: AppTextStyles.cardSubtitle),
            ),
          ...active.map((c) => ConnectionCard(connection: c)),
        ],
      ],
    );
  }
}

class _PendingInviteCard extends ConsumerStatefulWidget {
  const _PendingInviteCard({required this.connection, required this.repo});

  final Connection connection;
  final dynamic repo;

  @override
  ConsumerState<_PendingInviteCard> createState() => _PendingInviteCardState();
}

class _PendingInviteCardState extends ConsumerState<_PendingInviteCard> {
  bool _loading = false;

  Future<void> _accept() async {
    final code = widget.connection.inviteCode;
    if (code == null) return;
    setState(() => _loading = true);
    try {
      await widget.repo.acceptInvite(code);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.connection;
    final parentAsync = ref.watch(userByIdProvider(c.parentId));
    final parentName = parentAsync.valueOrNull != null
        ? '${parentAsync.value!.firstName} ${parentAsync.value!.lastName}'.trim()
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.4), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.mail, size: 20, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parentName != null && parentName.isNotEmpty
                          ? '$parentName vous invite'
                          : 'Invitation reçue',
                      style: AppTextStyles.cardTitle,
                    ),
                    Text('via ${c.inviteEmail}', style: AppTextStyles.cardSubtitle, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _loading
              ? const Center(
                  child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: c.inviteCode != null ? _accept : null,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Accepter l\'invitation'),
                  ),
                ),
        ],
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
