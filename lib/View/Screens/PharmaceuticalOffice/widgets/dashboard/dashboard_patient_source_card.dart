import 'package:flutter/material.dart';

class DashboardPatientSourceCard extends StatelessWidget {
  final Map<String, num> data;

  const DashboardPatientSourceCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final invited = (data['Invited'] ?? 0).toDouble();
    final apply = (data['Apply'] ?? 0).toDouble();
    final total = invited + apply;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Source of patients for clinical trials',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E4ED8),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 280,
            child: Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 24,
                    color: const Color(0xFF1E4ED8),
                  ),
                ),
                child: Center(
                  child: Text(
                    total.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 12),
          _LegendRow(
            color: const Color(0xFF64B5F6),
            label: 'Invited',
            value: invited.toInt(),
          ),
          const SizedBox(height: 8),
          _LegendRow(
            color: const Color(0xFF1E4ED8),
            label: 'Apply',
            value: apply.toInt(),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          value.toString(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        )
      ],
    );
  }
}
