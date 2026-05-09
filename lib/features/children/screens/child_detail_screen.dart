import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/child.dart';
import '../providers/children_providers.dart';

class ChildDetailScreen extends ConsumerWidget {
  const ChildDetailScreen({super.key, required this.childId});

  final String childId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Child child,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer ${child.firstName} ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(childRepositoryProvider).deleteChild(child.id);
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
    final childAsync = ref.watch(childDetailProvider(childId));

    return childAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur : $e'))),
      data: (child) {
        if (child == null) {
          return const Scaffold(
            body: Center(child: Text('Enfant introuvable')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('${child.firstName} ${child.lastName}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () =>
                    context.push('/children/${child.id}/edit', extra: child),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: child.avatarUrl != null
                      ? CachedNetworkImageProvider(child.avatarUrl!)
                      : null,
                  child: child.avatarUrl == null
                      ? Text(
                          '${child.firstName[0]}${child.lastName[0]}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  '${child.firstName} ${child.lastName}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  child.ageLabel,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                if (child.allergies != null) ...[
                  _InfoTile(label: 'Allergies', value: child.allergies!),
                  const SizedBox(height: 8),
                ],
                if (child.medicalInfo != null) ...[
                  _InfoTile(
                    label: 'Informations médicales',
                    value: child.medicalInfo!,
                  ),
                  const SizedBox(height: 8),
                ],
                if (child.notes != null) ...[
                  _InfoTile(label: 'Notes', value: child.notes!),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, ref, child),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Supprimer',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
