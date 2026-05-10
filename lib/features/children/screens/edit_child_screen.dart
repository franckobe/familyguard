import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/avatar_initials.dart';
import '../models/child.dart';
import '../providers/children_providers.dart';

class EditChildScreen extends ConsumerStatefulWidget {
  const EditChildScreen({super.key, required this.child});

  final Child child;

  @override
  ConsumerState<EditChildScreen> createState() => _EditChildScreenState();
}

class _EditChildScreenState extends ConsumerState<EditChildScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _birthDateCtrl;
  late final TextEditingController _allergiesCtrl;
  late final TextEditingController _medicalInfoCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _birthDate;
  Uint8List? _newPhotoBytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.child;
    _firstNameCtrl = TextEditingController(text: c.firstName);
    _lastNameCtrl = TextEditingController(text: c.lastName);
    _birthDateCtrl = TextEditingController(
      text: DateFormat('d MMMM yyyy', 'fr').format(c.birthDate),
    );
    _allergiesCtrl = TextEditingController(text: c.allergies ?? '');
    _medicalInfoCtrl = TextEditingController(text: c.medicalInfo ?? '');
    _notesCtrl = TextEditingController(text: c.notes ?? '');
    _birthDate = c.birthDate;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _birthDateCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicalInfoCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (xFile != null) {
      final bytes = await xFile.readAsBytes();
      setState(() => _newPhotoBytes = bytes);
    }
  }

  Future<void> _pickBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(DateTime.now().year - 18),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _birthDate = date;
        _birthDateCtrl.text = DateFormat('d MMMM yyyy', 'fr').format(date);
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet enfant ?'),
        content: const Text(
          'Cette action est irréversible. Les gardes passées seront conservées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFF87171)),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _loading = true);
    try {
      await ref.read(childRepositoryProvider).deleteChild(widget.child.id);
      if (mounted) context.go('/children');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final updated = widget.child.copyWith(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        birthDate: _birthDate,
        allergies: _allergiesCtrl.text.trim().isEmpty ? null : _allergiesCtrl.text.trim(),
        medicalInfo: _medicalInfoCtrl.text.trim().isEmpty ? null : _medicalInfoCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await ref.read(childRepositoryProvider).updateChild(updated, photo: _newPhotoBytes);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatarUrl = widget.child.avatarUrl;
    final initials =
        '${widget.child.firstName.isNotEmpty ? widget.child.firstName[0] : ''}${widget.child.lastName.isNotEmpty ? widget.child.lastName[0] : ''}';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Modifier')),
      body: AppBackground(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Stack(
                        children: [
                          _newPhotoBytes != null
                              ? CircleAvatar(
                                  radius: 48,
                                  backgroundImage: MemoryImage(_newPhotoBytes!),
                                )
                              : (currentAvatarUrl != null
                                  ? CircleAvatar(
                                      radius: 48,
                                      backgroundImage: CachedNetworkImageProvider(currentAvatarUrl),
                                    )
                                  : AvatarInitials(initials: initials, size: 96)),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.bgGradientMid, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _firstNameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Prénom'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastNameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Nom'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _birthDateCtrl,
                    readOnly: true,
                    onTap: _pickBirthDate,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Date de naissance',
                      suffixIcon: Icon(LucideIcons.calendar, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _allergiesCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Allergies'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _medicalInfoCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Informations médicales'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _delete,
                      icon: const Icon(LucideIcons.trash2, size: 18, color: Color(0xFFF87171)),
                      label: const Text(
                        'Supprimer cet enfant',
                        style: TextStyle(color: Color(0xFFF87171)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0x33F87171), width: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
