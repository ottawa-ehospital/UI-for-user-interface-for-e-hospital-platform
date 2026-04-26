import 'package:flutter/material.dart';

class ClinicalTrialRowData {
  final int trialId;
  final String trialName;
  final String trialStatus;

  const ClinicalTrialRowData({
    required this.trialId,
    required this.trialName,
    required this.trialStatus,
  });
}

class ClinicalTrialTableCard extends StatelessWidget {
  final List<ClinicalTrialRowData> trials;
  final void Function(int trialId)? onTrialTap;
  final VoidCallback? onMoreTap;

  const ClinicalTrialTableCard({
    super.key,
    required this.trials,
    this.onTrialTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleTrials = trials.take(5).toList();

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Clinical Trial List',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E4ED8),
                  ),
                ),
              ),
              IconButton(
                onPressed: onMoreTap,
                icon: const Icon(Icons.more_horiz),
              )
            ],
          ),
          const SizedBox(height: 8),
          ...visibleTrials.map(
            (trial) => InkWell(
              onTap: () => onTrialTap?.call(trial.trialId),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFF1F1F1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        trial.trialName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ClinicalTrialsStatus(
                        status: trial.trialStatus,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClinicalTrialsStatus extends StatelessWidget {
  final String status;

  const ClinicalTrialsStatus({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(status);

    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: style.foreground,
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(String status) {
    switch (status) {
      case 'Under Review':
        return const _StatusStyle(
          foreground: Color(0xFFB26A00),
          background: Color(0xFFFFE7C2),
        );
      case 'Ongoing':
        return const _StatusStyle(
          foreground: Color(0xFF1565C0),
          background: Color(0xFFDCEBFF),
        );
      case 'Completed':
        return const _StatusStyle(
          foreground: Color(0xFF2E7D32),
          background: Color(0xFFDDF4DE),
        );
      case 'Rejected':
        return const _StatusStyle(
          foreground: Color(0xFFC62828),
          background: Color(0xFFFFE0E0),
        );
      default:
        return const _StatusStyle(
          foreground: Colors.black87,
          background: Color(0xFFE0E0E0),
        );
    }
  }
}

class _StatusStyle {
  final Color foreground;
  final Color background;

  const _StatusStyle({
    required this.foreground,
    required this.background,
  });
}
