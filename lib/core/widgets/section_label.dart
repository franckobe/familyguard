import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text.toUpperCase(), style: AppTextStyles.sectionLabel),
    );
  }
}
