import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/child.dart';

class ChildCard extends StatelessWidget {
  const ChildCard({super.key, required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: child.avatarUrl != null
            ? CachedNetworkImageProvider(child.avatarUrl!)
            : null,
        child: child.avatarUrl == null
            ? Text(
                '${child.firstName[0]}${child.lastName[0]}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text('${child.firstName} ${child.lastName}'),
      subtitle: Text(child.ageLabel),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/children/${child.id}'),
    );
  }
}
