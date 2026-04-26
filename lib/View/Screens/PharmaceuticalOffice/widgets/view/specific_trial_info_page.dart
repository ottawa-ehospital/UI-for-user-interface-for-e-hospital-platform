import 'package:flutter/material.dart';
import 'profile_widgets.dart';

class SpecificTrialInfoPage extends StatelessWidget {
  final bool embedded;

  const SpecificTrialInfoPage({
    super.key,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    const trialName = 'Evaluation of ZE-504 for Migraine Prevention';

    final trialDetailRows = <List<String>>[
      ['Phase', 'Phase III'],
      ['Sponsor', 'ZE Pharmaceuticals'],
      ['Condition', 'Migraine'],
      ['Status', 'Under Review'],
      ['Enrollment', '120'],
      ['Location', 'Ottawa General Hospital'],
      ['Study Type', 'Interventional'],
      ['Allocation', 'Randomized'],
    ];

    final managementInfo = <String, String>{
      'Created By': 'Rexall',
      'Assigned Reviewer': 'Web Staff A',
      'Current Status': 'Under Review',
      'Last Updated': '2026-03-11',
      'Priority': 'High',
    };

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfilePageTitle(title: trialName),
        const SizedBox(height: 26),
        const ProfileSectionTitle(title: 'Basic Information'),
        const SizedBox(height: 16),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TrialBasicInfoItem(
                title: 'Official Title',
                content:
                    'A Randomized, Double-Blind Study of ZE-504 in Patients with Chronic Migraine.',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TrialBasicInfoItem(
                title: 'Brief Summary',
                content:
                    'This study evaluates the safety and efficacy of ZE-504 for migraine prevention in adult patients.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const TrialBasicInfoItem(
          title: 'Detailed Description',
          minHeight: 140,
          content:
              'Participants will be assigned to receive ZE-504 or placebo. Outcomes include migraine frequency reduction, treatment tolerability, and overall quality-of-life improvement during the trial period.',
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(
              child: TrialBasicInfoItem(
                title: 'Start Date',
                content: '2026-04-01',
                minHeight: 90,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TrialBasicInfoItem(
                title: 'End Date',
                content: '2027-01-15',
                minHeight: 90,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProfileSectionTitle(title: 'Detailed Information'),
                  const SizedBox(height: 16),
                  ProfileTableCard(
                    headers: const ['Field', 'Value'],
                    rows: trialDetailRows,
                    height: 360,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProfileSectionTitle(title: 'Management'),
                  const SizedBox(height: 16),
                  ManagementSideCard(
                    title: 'Management Info',
                    items: buildSideCardItems(managementInfo),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    if (embedded) {
      return content;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pages / View',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9AA3B2),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: Color(0xFF1E4ED8),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Click back',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1E4ED8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
