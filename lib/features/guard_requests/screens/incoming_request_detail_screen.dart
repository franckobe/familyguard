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
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/guard_request.dart';
import '../models/guard_response.dart';
import '../providers/guard_request_providers.dart';

class IncomingRequestDetailScreen extends ConsumerStatefulWidget {
  const IncomingRequestDetailScreen({
    super.key,
    required this.requestId,
    this.request,
  });

  final String requestId;
  final GuardRequest? request;

  @override
  ConsumerState<IncomingRequestDetailScreen> createState() =>
      _IncomingRequestDetailScreenState();
}

class _IncomingRequestDetailScreenState
    extends ConsumerState<IncomingRequestDetailScreen> {
  final _messageCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  GuardRequest? _find(String id) {
    return ref.watch(guardRequestsAsCaregiverProvider).valueOrNull
        ?.firstWhere((r) => r.id == id, orElse: () => widget.request!);
  }

  Future<void> _respond(GuardRequest req, GuardResponseStatus status) async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final user = ref.read(currentUserProvider).valueOrNull;
      final snapshot = CaregiverSnapshot(
        firstName: user?.firstName ?? '',
        lastName: user?.lastName ?? '',
        avatarUrl: user?.avatarUrl,
      );
      await ref.read(guardRequestRepositoryProvider).respond(
        requestId: req.id,
        caregiverId: uid,
        caregiverSnapshot: snapshot,
        status: status,
        message: _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
      );
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == GuardResponseStatus.accepted
              ? 'Demande acceptée !'
              : 'Demande refusée.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = _find(widget.requestId) ?? widget.request;
    if (req == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final fmt = DateFormat('d MMMM yyyy, HH:mm', 'fr');
    final isOpen = req.status == GuardRequestStatus.open;

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
                Text(req.typeLabel, style: AppTextStyles.screenTitle),
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
                if (isOpen) ...[
                  const SizedBox(height: 24),
                  TextField(
                    controller: _messageCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Message (optionnel)',
                      hintText: 'Ajouter un message…',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _respond(req, GuardResponseStatus.declined),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF87171),
                              side: const BorderSide(color: Color(0x33F87171), width: 0.5),
                            ),
                            child: const Text('Refuser'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () => _respond(req, GuardResponseStatus.accepted),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                            child: const Text('Accepter'),
                          ),
                        ),
                      ],
                    ),
                ] else ...[
                  const SizedBox(height: 16),
                  Text(
                    req.status == GuardRequestStatus.accepted
                        ? 'Garde confirmée — à vous de jouer !'
                        : 'Cette demande n\'est plus disponible.',
                    style: AppTextStyles.cardSubtitle,
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
