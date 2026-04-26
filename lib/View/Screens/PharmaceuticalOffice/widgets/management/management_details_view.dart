import 'package:flutter/material.dart';
import 'management_tables.dart';

class ManagementDetailsView extends StatelessWidget {
  final int tabIndex;
  final VoidCallback onBack;
  final ValueChanged<int> onTabChange;

  const ManagementDetailsView({
    super.key,
    required this.tabIndex,
    required this.onBack,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = ['Audit', 'Invitations', 'Applications'];
    final counts = [2, 1, 3];

    Widget currentTable;
    switch (tabIndex) {
      case 1:
        currentTable = const ManagementInviteTable();
        break;
      case 2:
        currentTable = const ManagementApplyTable();
        break;
      case 0:
      default:
        currentTable = const ManagementAuditTable();
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            const Text(
              'Back to overall',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: List.generate(tabs.length, (index) {
            final active = index == tabIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => onTabChange(index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFEEF4FF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF1E4ED8)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        tabs[index],
                        style: TextStyle(
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          color: active
                              ? const Color(0xFF1E4ED8)
                              : const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: counts[index] > 0
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          counts[index].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: counts[index] > 0
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        currentTable,
      ],
    );
  }
}
