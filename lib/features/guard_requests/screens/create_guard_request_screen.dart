import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../../auth/providers/auth_providers.dart';
import '../../children/models/child.dart';
import '../../children/providers/children_providers.dart';
import '../../connections/models/connection.dart';
import '../../connections/providers/connection_providers.dart';
import '../models/guard_request.dart';
import '../providers/guard_request_providers.dart';

class CreateGuardRequestScreen extends ConsumerStatefulWidget {
  const CreateGuardRequestScreen({super.key});

  @override
  ConsumerState<CreateGuardRequestScreen> createState() =>
      _CreateGuardRequestScreenState();
}

class _CreateGuardRequestScreenState
    extends ConsumerState<CreateGuardRequestScreen> {
  int _step = 0;

  // Step 1 state
  final Set<String> _selectedChildIds = {};
  DateTime _startAt = DateTime.now().add(const Duration(hours: 1));
  DateTime _endAt = DateTime.now().add(const Duration(hours: 3));
  String _location = '';
  String _notes = '';
  RecurrenceType _recurrenceType = RecurrenceType.none;

  // Step 2 state
  final List<(DateTime start, DateTime end)> _occurrences = [];

  // Step 3 state
  final Set<String> _selectedRecipients = {};

  bool _loading = false;

  GuardRequestType get _computedType =>
      GuardRequest.typeFromDuration(_startAt, _endAt);

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startAt : _endAt,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('fr'),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startAt : _endAt),
    );
    if (time == null || !mounted) return;
    final result = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startAt = result;
        if (_endAt.isBefore(_startAt)) _endAt = _startAt.add(const Duration(hours: 2));
      } else {
        _endAt = result;
      }
    });
  }

  Future<void> _pickOccurrence() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('fr'),
    );
    if (date == null || !mounted) return;
    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (startTime == null || !mounted) return;
    final endTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
    );
    if (endTime == null || !mounted) return;
    setState(() {
      _occurrences.add((
        DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute),
        DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute),
      ));
    });
  }

  Widget _buildStep1(List<Child> children) {
    final fmt = DateFormat('d MMM HH:mm', 'fr');
    final typeLabel = GuardRequest.labelFromDuration(_startAt, _endAt);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text('Enfants', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        ...children.map((c) {
          final selected = _selectedChildIds.contains(c.id);
          final name = '${c.firstName} ${c.lastName}'.trim();
          return GestureDetector(
            onTap: () => setState(() {
              if (selected) {
                _selectedChildIds.remove(c.id);
              } else {
                _selectedChildIds.add(c.id);
              }
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? AppColors.glassPurpleSurface : AppColors.glassSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.glassPurpleBorder : AppColors.glassBorder,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                    size: 20,
                    color: selected ? AppColors.primaryLight : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 12),
                  Text(name, style: AppTextStyles.cardTitle),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        Text('Dates', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        _DateTile(
          label: 'Début',
          value: fmt.format(_startAt),
          onTap: () => _pickDateTime(isStart: true),
        ),
        const SizedBox(height: 8),
        _DateTile(
          label: 'Fin',
          value: fmt.format(_endAt),
          onTap: () => _pickDateTime(isStart: false),
        ),
        if (_endAt.isAfter(_startAt)) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.glassPurpleSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.clock, size: 14, color: AppColors.badgeNewText),
                const SizedBox(width: 8),
                Text(typeLabel, style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.badgeNewText)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Récurrence', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        Row(
          children: RecurrenceType.values.map((r) {
            final selected = _recurrenceType == r;
            final label = r == RecurrenceType.none ? 'Ponctuel' : 'Récurrent';
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _recurrenceType = r),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.glassPurpleSurface : AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.glassPurpleBorder : AppColors.glassBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Text(label, style: AppTextStyles.cardTitle.copyWith(
                    color: selected ? AppColors.badgeNewText : AppColors.textPrimary,
                  )),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        TextField(
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Lieu (optionnel)'),
          onChanged: (v) => _location = v,
        ),
        const SizedBox(height: 16),
        TextField(
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Notes (optionnel)'),
          maxLines: 3,
          onChanged: (v) => _notes = v,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final fmt = DateFormat('d MMM HH:mm', 'fr');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text('Occurrences récurrentes', style: AppTextStyles.cardTitle),
        const SizedBox(height: 4),
        Text('Ajoutez les dates supplémentaires.', style: AppTextStyles.cardSubtitle),
        const SizedBox(height: 16),
        ..._occurrences.asMap().entries.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${fmt.format(e.value.$1)} → ${fmt.format(e.value.$2)}',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 16, color: AppColors.textTertiary),
                onPressed: () => setState(() => _occurrences.removeAt(e.key)),
              ),
            ],
          ),
        )),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickOccurrence,
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Ajouter une date'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final connectionsAsync = ref.watch(connectionsAsParentProvider);
    final activeConnections = connectionsAsync.valueOrNull
            ?.where((c) => c.status == ConnectionStatus.active && c.caregiverId != null)
            .toList() ??
        [];

    if (activeConnections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.users, size: 32, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('Aucun babysitter actif', style: AppTextStyles.cardTitle),
            const SizedBox(height: 4),
            Text('Invitez des proches dans Connexions.', style: AppTextStyles.cardSubtitle),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text('Envoyer à…', style: AppTextStyles.cardTitle),
        const SizedBox(height: 4),
        Text('Choisissez les babysitters à notifier.', style: AppTextStyles.cardSubtitle),
        const SizedBox(height: 16),
        ...activeConnections.map((c) {
          final uid = c.caregiverId!;
          final selected = _selectedRecipients.contains(uid);
          final userAsync = ref.watch(userByIdProvider(uid));
          final user = userAsync.valueOrNull;
          final name = user != null
              ? '${user.firstName} ${user.lastName}'.trim()
              : c.inviteEmail;

          return GestureDetector(
            onTap: () => setState(() {
              if (selected) {
                _selectedRecipients.remove(uid);
              } else {
                _selectedRecipients.add(uid);
              }
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? AppColors.glassPurpleSurface : AppColors.glassSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.glassPurpleBorder : AppColors.glassBorder,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                    size: 20,
                    color: selected ? AppColors.primaryLight : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 12),
                  Text(name, style: AppTextStyles.cardTitle),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  bool get _canProceedStep1 =>
      _selectedChildIds.isNotEmpty && _endAt.isAfter(_startAt);

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(childrenProvider);
    final children = childrenAsync.valueOrNull?.where((c) => !c.archived).toList() ?? [];

    final steps = [
      'Détails',
      if (_recurrenceType == RecurrenceType.custom) 'Occurrences',
      'Destinataires',
    ];
    final totalSteps = steps.length;
    final isLastStep = _step == totalSteps - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text(steps[_step]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / totalSteps,
            backgroundColor: AppColors.glassSurface,
            color: AppColors.primaryLight,
            minHeight: 3,
          ),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _buildCurrentStep(children),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step--),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
                          ),
                          child: const Text('Retour'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _canProceed() ? _onNext : null,
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        child: _loading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(isLastStep ? 'Envoyer' : 'Suivant'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(List<Child> children) {
    if (_step == 0) return _buildStep1(children);
    if (_recurrenceType == RecurrenceType.custom && _step == 1) return _buildStep2();
    return _buildStep3();
  }

  bool _canProceed() {
    if (_step == 0) return _canProceedStep1;
    final totalSteps = _recurrenceType == RecurrenceType.custom ? 3 : 2;
    if (_step == totalSteps - 1) return _selectedRecipients.isNotEmpty;
    return true;
  }

  Future<void> _onNext() async {
    final totalSteps = _recurrenceType == RecurrenceType.custom ? 3 : 2;
    if (_step < totalSteps - 1) {
      setState(() => _step++);
    } else {
      await _submit();
    }
  }

  Future<void> _submit() async {
    if (_selectedRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins un destinataire.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final childrenAll = ref.read(childrenProvider).valueOrNull ?? [];
      final selectedChildren = childrenAll
          .where((c) => _selectedChildIds.contains(c.id))
          .toList();

      final childIds = selectedChildren.map((c) => c.id).toList();
      final childSnapshots = selectedChildren.map((c) => ChildSnapshot(
        firstName: c.firstName,
        lastName: c.lastName,
        avatarUrl: c.avatarUrl,
        birthDate: c.birthDate,
      )).toList();

      final occurrences = _occurrences.map((o) => {
        'startAt': Timestamp.fromDate(o.$1),
        'endAt': Timestamp.fromDate(o.$2),
        'notes': null,
      }).toList();

      await ref.read(guardRequestRepositoryProvider).create(
        parentId: uid,
        childIds: childIds,
        childSnapshots: childSnapshots,
        type: _computedType,
        startAt: _startAt,
        endAt: _endAt,
        location: _location.trim().isEmpty ? null : _location.trim(),
        notes: _notes.trim().isEmpty ? null : _notes.trim(),
        recurrenceType: _recurrenceType,
        recipientIds: _selectedRecipients.toList(),
        occurrences: occurrences,
      );

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande envoyée !')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.calendar, size: 16, color: AppColors.primaryLight),
            const SizedBox(width: 10),
            Text('$label : ', style: AppTextStyles.cardSubtitle),
            Text(value, style: AppTextStyles.cardTitle),
          ],
        ),
      ),
    );
  }
}
