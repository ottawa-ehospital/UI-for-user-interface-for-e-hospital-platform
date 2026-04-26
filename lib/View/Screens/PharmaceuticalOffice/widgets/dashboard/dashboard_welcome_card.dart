import 'package:flutter/material.dart';

class DashboardWelcomeCard extends StatelessWidget {
  final String companyName;

  const DashboardWelcomeCard({
    super.key,
    this.companyName = 'Rexall',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E4ED8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Hello, $companyName\nWish you a wonderful day at work.',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
