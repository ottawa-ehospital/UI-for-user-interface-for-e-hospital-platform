import 'package:flutter/material.dart';
import '../widgets/dashboard/dashboard_welcome_card.dart';
import '../widgets/dashboard/dashboard_actions_carousel.dart';
import '../widgets/dashboard/dashboard_summary_card.dart';
import '../widgets/dashboard/dashboard_patient_source_card.dart';
import '../widgets/clinical_trial/clinical_trial_table_card.dart';
import 'pharmaceuticals_clinical_trial_page.dart';
import '../widgets/clinical_trial/pharmaceuticals_specific_trial_page.dart';

class PharmaceuticalsDashboardPage extends StatelessWidget {
  const PharmaceuticalsDashboardPage({super.key});

  void _openClinicalTrialList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PharmaceuticalsClinicalTrialPage(),
      ),
    );
  }

  void _openSpecificTrial(BuildContext context, int trialId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PharmaceuticalsSpecificTrialPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    const actions = [
      DashboardActionItem(name: 'Audit', completed: 8, pending: 2),
      DashboardActionItem(name: 'Invite', completed: 4, pending: 1),
      DashboardActionItem(name: 'Apply', completed: 5, pending: 3),
    ];

    const trials = [
      ClinicalTrialRowData(trialId: 1, trialName: 'Evaluation of ZE-504 for Migraine Prevention', trialStatus: 'Under Review'),
      ClinicalTrialRowData(trialId: 2, trialName: 'Double-Blind Trial of NK-505 for Rheumatoid Arthritis', trialStatus: 'Ongoing'),
      ClinicalTrialRowData(trialId: 3, trialName: 'Comparative Study of AB-606 Versus Standard Care in Type 2 Diabetes', trialStatus: 'Completed'),
      ClinicalTrialRowData(trialId: 4, trialName: 'Test Trial 4', trialStatus: 'Rejected'),
      ClinicalTrialRowData(trialId: 5, trialName: 'Test Trial 5', trialStatus: 'Ongoing'),
    ];

    final patientSource = {'Invited': 12, 'Apply': 8};

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: isMobile
              ? Column(
                  children: [
                    const DashboardWelcomeCard(),
                    const SizedBox(height: 20),
                    const DashboardActionsCarousel(items: actions),
                    const SizedBox(height: 20),
                    DashboardSummaryCard(title: 'Clinical Trial', total: 15, percent: 0, onTap: () => _openClinicalTrialList(context)),
                    const SizedBox(height: 20),
                    DashboardSummaryCard(title: 'Patients', total: 4, percent: 0, onTap: () {}),
                    const SizedBox(height: 20),
                    DashboardSummaryCard(title: 'Doctors', total: 5, percent: 0, onTap: () {}),
                    const SizedBox(height: 20),
                    DashboardPatientSourceCard(data: patientSource),
                    const SizedBox(height: 20),
                    ClinicalTrialTableCard(trials: trials, onTrialTap: (id) => _openSpecificTrial(context, id), onMoreTap: () => _openClinicalTrialList(context)),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 58,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DashboardWelcomeCard(),
                          const SizedBox(height: 20),
                          LayoutBuilder(builder: (context, constraints) {
                          if (constraints.maxWidth < 500) {
                            return Column(
                              children: [
                                DashboardSummaryCard(
                                  title: 'Clinical Trial',
                                  total: 15,
                                  percent: 0,
                                  onTap: () => _openClinicalTrialList(context),
                                ),
                                const SizedBox(height: 12),
                                DashboardSummaryCard(
                                  title: 'Patients',
                                  total: 4,
                                  percent: 0,
                                  onTap: () {},
                                ),
                                const SizedBox(height: 12),
                                DashboardSummaryCard(
                                  title: 'Doctors',
                                  total: 5,
                                  percent: 0,
                                  onTap: () {},
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: DashboardSummaryCard(
                                  title: 'Clinical Trial',
                                  total: 15,
                                  percent: 0,
                                  onTap: () => _openClinicalTrialList(context),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: DashboardSummaryCard(
                                  title: 'Patients',
                                  total: 4,
                                  percent: 0,
                                  onTap: () {},
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: DashboardSummaryCard(
                                  title: 'Doctors',
                                  total: 5,
                                  percent: 0,
                                  onTap: () {},
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                          const SizedBox(height: 20),
                          DashboardPatientSourceCard(data: patientSource),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 42,
                      child: Column(
                        children: [
                          const DashboardActionsCarousel(items: actions),
                          const SizedBox(height: 20),
                          ClinicalTrialTableCard(trials: trials, onTrialTap: (id) => _openSpecificTrial(context, id), onMoreTap: () => _openClinicalTrialList(context)),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
