import 'package:flutter/material.dart';

class ManagementOverallTable extends StatelessWidget {
  const ManagementOverallTable({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['Migraine Trial', 'Audit', 'Completed', '2026-03-01 10:30'],
      ['RA Trial', 'Invitations', 'In Progress', '2026-03-03 14:15'],
      ['Diabetes Trial', 'Applications', 'In Progress', '2026-03-05 09:20'],
    ];

    return _SimpleManagementTable(
      headers: const ['Trial Name', 'Action Type', 'Completion Status', 'Time'],
      rows: rows,
      statusColumnIndex: 2,
    );
  }
}

class ManagementAuditTable extends StatelessWidget {
  const ManagementAuditTable({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = [
      [
        'Migraine Trial',
        '2026-03-01',
        'Web Staff A',
        'Read',
        'Approved',
        '2026-03-03',
        'Unread'
      ],
      [
        'RA Trial',
        '2026-03-02',
        'Web Staff B',
        'Unread',
        'Pending',
        'Waiting for response',
        'Not yet received'
      ],
    ];

    return _SimpleManagementTable(
      headers: const [
        'Trial Name',
        'Submission Date',
        'Reviewer',
        'Webstaff Read Status',
        'Audit Status',
        'Audit Date',
        'Your Read Status'
      ],
      rows: rows,
      statusColumns: const [3, 4, 6],
    );
  }
}

class ManagementInviteTable extends StatelessWidget {
  const ManagementInviteTable({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = [
      [
        'Migraine Trial',
        'Alice Johnson',
        '2026-03-01',
        'Read',
        'Agreed',
        '2026-03-04',
        'Unread'
      ],
      [
        'RA Trial',
        'Bob Lee',
        '2026-03-02',
        'Unread',
        'Pending',
        'Waiting for response',
        'Response not yet received'
      ],
    ];

    return _SimpleManagementTable(
      headers: const [
        'Trial Name',
        'Recipient',
        'Invitation Date',
        'Recipient Read Status',
        'Response',
        'Response Date',
        'Your Read Status'
      ],
      rows: rows,
      statusColumns: const [3, 4, 6],
    );
  }
}

class ManagementApplyTable extends StatelessWidget {
  const ManagementApplyTable({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = [
      [
        'Migraine Trial',
        'Patient A',
        '2026-03-01',
        'Unread',
        'Pending',
        'Will update after your response',
        'You have not responded yet'
      ],
      [
        'RA Trial',
        'Patient B',
        '2026-03-02',
        'Read',
        'Agreed',
        '2026-03-05',
        'Unread'
      ],
    ];

    return _SimpleManagementTable(
      headers: const [
        'Trial Name',
        'Applicant',
        'Application Date',
        'Your Read Status',
        'Your Response',
        'Your Response Date',
        'Applicant Read Status'
      ],
      rows: rows,
      statusColumns: const [3, 4, 6],
    );
  }
}

class _SimpleManagementTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final int? statusColumnIndex;
  final List<int>? statusColumns;

  const _SimpleManagementTable({
    required this.headers,
    required this.rows,
    this.statusColumnIndex,
    this.statusColumns,
  });

  Color _bg(String value) {
    switch (value) {
      case 'Completed':
      case 'Approved':
      case 'Agreed':
      case 'Read':
        return const Color(0xFFDDF4DE);
      case 'Pending':
      case 'Under Review':
        return const Color(0xFFFFE7C2);
      case 'Unread':
      case 'Rejected':
      case 'Unprocessed':
        return const Color(0xFFFEE2E2);
      case 'In Progress':
        return const Color(0xFFDCEBFF);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _fg(String value) {
    switch (value) {
      case 'Completed':
      case 'Approved':
      case 'Agreed':
      case 'Read':
        return const Color(0xFF2E7D32);
      case 'Pending':
      case 'Under Review':
        return const Color(0xFFB26A00);
      case 'Unread':
      case 'Rejected':
      case 'Unprocessed':
        return const Color(0xFFB91C1C);
      case 'In Progress':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF374151);
    }
  }

  bool _isStatusColumn(int index) {
    if (statusColumnIndex != null) return statusColumnIndex == index;
    if (statusColumns != null) return statusColumns!.contains(index);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1E4ED8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: headers
                  .map(
                    (header) => Expanded(
                      child: Text(
                        header,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          ...List.generate(rows.length, (rowIndex) {
            final row = rows[rowIndex];
            final isEven = rowIndex % 2 == 0;

            return Container(
              color: isEven ? const Color(0xFFF9FAFB) : Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(row.length, (colIndex) {
                  final value = row[colIndex];
                  final isStatus = _isStatusColumn(colIndex);

                  return Expanded(
                    child: isStatus
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _bg(value),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                value,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _fg(value),
                                ),
                              ),
                            ),
                          )
                        : Text(
                            value,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF374151),
                            ),
                          ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}
