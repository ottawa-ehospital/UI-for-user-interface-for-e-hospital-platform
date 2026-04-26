import 'package:flutter/material.dart';
import 'management_tables.dart';

class ManagementOverallView extends StatelessWidget {
  final VoidCallback onOpenAudit;
  final VoidCallback onOpenInvitations;
  final VoidCallback onOpenApplications;

  const ManagementOverallView({
    super.key,
    required this.onOpenAudit,
    required this.onOpenInvitations,
    required this.onOpenApplications,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _ManagementSummaryCard(
                title: 'Audit',
                total: 8,
                count: 2,
                countLabel: 'Unread',
                onTap: onOpenAudit,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ManagementSummaryCard(
                title: 'Invitations',
                total: 6,
                count: 1,
                countLabel: 'Unread',
                onTap: onOpenInvitations,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ManagementSummaryCard(
                title: 'Applications',
                total: 5,
                count: 3,
                countLabel: 'Unprocessed',
                onTap: onOpenApplications,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const ManagementOverallTable(),
      ],
    );
  }
}

class _ManagementSummaryCard extends StatelessWidget {
  final String title;
  final int total;
  final int count;
  final String countLabel;
  final VoidCallback onTap;

  const _ManagementSummaryCard({
    required this.title,
    required this.total,
    required this.count,
    required this.countLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAlert = count > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onTap,
                child: const Row(
                  children: [
                    Text(
                      'Click to view details',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E4ED8),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_double_arrow_right,
                      color: Color(0xFF1E4ED8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            total.toString(),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: isAlert ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                '$count $countLabel',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
