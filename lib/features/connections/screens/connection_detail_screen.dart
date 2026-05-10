import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/avatar_initials.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/connection.dart';
import '../providers/connection_providers.dart';

class ConnectionDetailScreen extends ConsumerWidget {
  const ConnectionDetailScreen({super.key, required this.connectionId});

  final String connectionId;

  Connection? _findConnection(WidgetRef ref, String id) {
    final asParent = ref.watch(connectionsAsParentProvider).valueOrNull ?? [];
    final asCaregiver = ref.watch(connectionsAsCaregiverProvider).valueOrNull ?? [];
    final all = [...asParent, ...asCaregiver];
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmAction(
    BuildContext context,
    WidgetRef ref,
    Connection connection,
    bool isParent,
  ) async {
    final title = isParent ? 'Bloquer cette connexion ?' : 'Quitter cette connexion ?';
    final body = isParent
        ? 'Le babysitter ne pourra plus recevoir vos demandes de garde.'
        : 'Vous ne recevrez plus de demandes de cette famille.';
    final newStatus = isParent ? ConnectionStatus.blocked : ConnectionStatus.declined;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFF87171)),
            child: Text(isParent ? 'Bloquer' : 'Quitter'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(connectionRepositoryProvider).updateStatus(connection.id, newStatus);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erreur : $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = _findConnection(ref, connectionId);
    if (connection == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isParent = connection.parentId == myUid;
    final otherUid = isParent ? connection.caregiverId : connection.parentId;
    final otherUserAsync = otherUid != null ? ref.watch(userByIdProvider(otherUid)) : null;
    final otherUser = otherUserAsync?.valueOrNull;

    final fullName = '${otherUser?.firstName ?? ''} ${otherUser?.lastName ?? ''}'.trim();
    final label = fullName.isNotEmpty ? fullName : connection.inviteEmail;
    final initials = fullName.isNotEmpty
        ? '${otherUser!.firstName.isNotEmpty ? otherUser.firstName[0] : ''}${otherUser.lastName.isNotEmpty ? otherUser.lastName[0] : ''}'.toUpperCase()
        : connection.inviteEmail.isNotEmpty ? connection.inviteEmail[0].toUpperCase() : '?';

    final fmt = DateFormat('d MMMM yyyy', 'fr');
    final dateLabel = switch (connection.status) {
      ConnectionStatus.active   => 'Connecté depuis le ${fmt.format(connection.updatedAt)}',
      ConnectionStatus.pending  => 'Invité le ${fmt.format(connection.createdAt)}',
      ConnectionStatus.declined => 'Refusé le ${fmt.format(connection.updatedAt)}',
      ConnectionStatus.blocked  => 'Bloqué le ${fmt.format(connection.updatedAt)}',
    };

    final badgeStatus = switch (connection.status) {
      ConnectionStatus.pending  => BadgeStatus.waiting,
      ConnectionStatus.active   => BadgeStatus.accepted,
      ConnectionStatus.declined => BadgeStatus.declined,
      ConnectionStatus.blocked  => BadgeStatus.declined,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Connexion')),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                otherUser?.avatarUrl != null
                    ? CircleAvatar(
                        radius: 56,
                        backgroundImage: NetworkImage(otherUser!.avatarUrl!),
                      )
                    : AvatarInitials(initials: initials, size: 112),
                const SizedBox(height: 16),
                Text(label, style: AppTextStyles.screenTitle, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(dateLabel, style: AppTextStyles.cardSubtitle, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                StatusBadge(status: badgeStatus),
                const SizedBox(height: 28),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        icon: LucideIcons.users,
                        label: 'Rôle',
                        value: isParent ? 'Votre babysitter' : 'Votre famille',
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: LucideIcons.mail,
                        label: 'Email',
                        value: connection.inviteEmail,
                      ),
                      if (otherUser?.phone != null) ...[
                        const SizedBox(height: 16),
                        _InfoRow(
                          icon: LucideIcons.phone,
                          label: 'Téléphone',
                          value: otherUser!.phone!,
                        ),
                      ],
                      if (connection.message != null && connection.message!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _InfoRow(
                          icon: LucideIcons.messageSquare,
                          label: 'Message',
                          value: connection.message!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (connection.status == ConnectionStatus.active ||
                    connection.status == ConnectionStatus.pending) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmAction(context, ref, connection, isParent),
                      icon: Icon(
                        isParent ? LucideIcons.ban : LucideIcons.logOut,
                        size: 18,
                        color: const Color(0xFFF87171),
                      ),
                      label: Text(
                        isParent ? 'Bloquer' : 'Quitter',
                        style: const TextStyle(color: Color(0xFFF87171)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0x33F87171), width: 0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: AppTextStyles.sectionLabel),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.cardTitle),
            ],
          ),
        ),
      ],
    );
  }
}
