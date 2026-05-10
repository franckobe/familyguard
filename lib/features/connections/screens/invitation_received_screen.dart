import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/avatar_initials.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/connection_providers.dart';

class InvitationReceivedScreen extends ConsumerStatefulWidget {
  const InvitationReceivedScreen({super.key, required this.inviteCode});

  final String inviteCode;

  @override
  ConsumerState<InvitationReceivedScreen> createState() =>
      _InvitationReceivedScreenState();
}

class _InvitationReceivedScreenState
    extends ConsumerState<InvitationReceivedScreen> {
  bool _accepting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await ref
          .read(connectionRepositoryProvider)
          .acceptInvite(widget.inviteCode);
      if (mounted) context.go('/connections');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated =
        ref.watch(authStateProvider).valueOrNull != null;
    final detailsAsync =
        ref.watch(inviteDetailsProvider(widget.inviteCode));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Invitation')),
      body: AppBackground(
        child: SafeArea(
          child: detailsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.alertCircle,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Invitation invalide ou expirée',
                      style: AppTextStyles.cardTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ce lien a peut-être déjà été utilisé.',
                      style: AppTextStyles.cardSubtitle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            data: (details) {
              final parentFirstName =
                  details['parentFirstName'] as String? ?? '';
              final inviteEmail =
                  details['inviteEmail'] as String? ?? '';

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    AvatarInitials(
                      initials: parentFirstName.isNotEmpty
                          ? parentFirstName[0]
                          : '?',
                      size: 96,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$parentFirstName vous invite\nsur FamilyGuard',
                      style: AppTextStyles.screenTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DESTINATAIRE',
                            style: AppTextStyles.sectionLabel,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            inviteEmail,
                            style: AppTextStyles.cardTitle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!isAuthenticated) ...[
                      Text(
                        'Connectez-vous pour accepter l\'invitation',
                        style: AppTextStyles.cardSubtitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => context.push('/login'),
                          child: const Text('Se connecter'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('Créer un compte'),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _accepting ? null : _accept,
                          child: _accepting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Accepter l\'invitation'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
