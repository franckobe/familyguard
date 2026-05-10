import 'package:flutter/material.dart';
import '../models/guard_request.dart';

class GuardRequestDetailScreen extends StatelessWidget {
  const GuardRequestDetailScreen({super.key, required this.requestId, this.request});

  final String requestId;
  final GuardRequest? request;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: Text('Guard Request Detail')),
    );
  }
}
