import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_initials.dart';
import '../providers/children_providers.dart';

class AddChildBottomSheet extends ConsumerStatefulWidget {
  const AddChildBottomSheet({super.key});

  @override
  ConsumerState<AddChildBottomSheet> createState() =>
      _AddChildBottomSheetState();
}

class _AddChildBottomSheetState extends ConsumerState<AddChildBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medicalInfoCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _birthDate;
  Uint8List? _photoBytes;
  bool _loading = false;
  bool _showOptional = false;

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
      setState(() => _photoBytes = bytes);
    }
  }

  Future<void> _pickBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date de naissance')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final user = ref.read(authStateProvider).valueOrNull!;
      await ref.read(childRepositoryProvider).addChild(
        parentId: user.uid,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        birthDate: _birthDate!,
        allergies: _allergiesCtrl.text.trim().isEmpty ? null : _allergiesCtrl.text.trim(),
        medicalInfo: _medicalInfoCtrl.text.trim().isEmpty ? null : _medicalInfoCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        photo: _photoBytes,
      );
      if (mounted) Navigator.of(context).pop();
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
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final initials = '${firstName.isNotEmpty ? firstName[0] : '?'}${lastName.isNotEmpty ? lastName[0] : ''}';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      _photoBytes != null
                          ? CircleAvatar(
                              radius: 40,
                              backgroundImage: MemoryImage(_photoBytes!),
                            )
                          : AvatarInitials(initials: initials, size: 80),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF1A0040), width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _firstNameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Prénom *'),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Nom *'),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthDateCtrl,
                readOnly: true,
                onTap: _pickBirthDate,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Date de naissance *',
                  suffixIcon: Icon(LucideIcons.calendar, size: 18, color: AppColors.textSecondary),
                ),
                validator: (_) => _birthDate == null ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _showOptional = !_showOptional),
                child: Text(
                  _showOptional ? 'Masquer les détails' : 'Ajouter des détails (allergies, notes…)',
                ),
              ),
              if (_showOptional) ...[
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
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Ajouter'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
