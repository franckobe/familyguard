import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/guard_request.dart';
import '../models/guard_response.dart';
import '../providers/guard_request_providers.dart';
import '../widgets/response_card.dart';

class GuardRequestDetailScreen extends ConsumerWidget {
  const GuardRequestDetailScreen({
    super.key,
    required this.requestId,
    this.request,
  });

  final String requestId;
  final GuardRequest? request;

  GuardRequest? _find(WidgetRef ref, String id) {
    return ref.watch(guardRequestsAsParentProvider).valueOrNull
        ?.firstWhere((r) => r.id == id, orElse: () => request!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final req = _find(ref, requestId) ?? request;
    if (req == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final responsesAsync = ref.watch(guardResponsesProvider(requestId));
    final responses = responsesAsync.valueOrNull ?? [];
    final fmt = DateFormat('d MMMM yyyy, HH:mm', 'fr');
    final isOpen = req.status == GuardRequestStatus.open;
    final isAccepted = req.status == GuardRequestStatus.accepted;

    final badgeStatus = switch (req.status) {
      GuardRequestStatus.open      => BadgeStatus.waiting,
      GuardRequestStatus.accepted  => BadgeStatus.accepted,
      GuardRequestStatus.done      => BadgeStatus.accepted,
      GuardRequestStatus.cancelled => BadgeStatus.declined,
      GuardRequestStatus.expired   => BadgeStatus.declined,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Demande de garde')),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(req.typeLabel, style: AppTextStyles.screenTitle),
                    ),
                    StatusBadge(status: badgeStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  req.childNamesLabel,
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 20),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(icon: LucideIcons.calendar, label: 'Début', value: fmt.format(req.startAt)),
                      const SizedBox(height: 12),
                      _InfoRow(icon: LucideIcons.calendarOff, label: 'Fin', value: fmt.format(req.endAt)),
                      if (req.location != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(icon: LucideIcons.mapPin, label: 'Lieu', value: req.location!),
                      ],
                      if (req.notes != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(icon: LucideIcons.messageSquare, label: 'Notes', value: req.notes!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Réponses', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 8),
                if (responses.isEmpty)
                  Text('En attente de réponses…', style: AppTextStyles.cardSubtitle)
                else
                  ...responses.map((r) => ResponseCard(
                    response: r,
                    isConfirmed: req.confirmedId == r.caregiverId,
                    onConfirm: (isOpen && r.status == GuardResponseStatus.accepted)
                        ? () => _confirm(context, ref, req.id, r.caregiverId)
                        : null,
                  )),
                const SizedBox(height: 24),
                if (isOpen || isAccepted)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancel(context, ref, req.id),
                      icon: const Icon(LucideIcons.x, size: 18, color: Color(0xFFF87171)),
                      label: const Text('Annuler la demande',
                          style: TextStyle(color: Color(0xFFF87171))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0x33F87171), width: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(
      BuildContext context, WidgetRef ref, String requestId, String caregiverId) async {
    try {
      await ref.read(guardRequestRepositoryProvider).confirmCaregiver(requestId, caregiverId);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Garde confirmée !')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, String requestId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la demande ?'),
        content: const Text('Les babysitters seront notifiés.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Retour')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFF87171)),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref.read(guardRequestRepositoryProvider).cancelRequest(requestId);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erreur : $e')));
        }
      }
    }
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
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 10),
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
