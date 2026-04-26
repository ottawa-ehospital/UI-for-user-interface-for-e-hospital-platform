import 'package:flutter/material.dart';
import '../widgets/management/management_overall_view.dart';
import '../widgets/management/management_details_view.dart';

class PharmaceuticalsManagementPage extends StatefulWidget {
  const PharmaceuticalsManagementPage({super.key});

  @override
  State<PharmaceuticalsManagementPage> createState() =>
      _PharmaceuticalsManagementPageState();
}

class _PharmaceuticalsManagementPageState
    extends State<PharmaceuticalsManagementPage> {
  bool showDetails = false;
  int tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            showDetails ? 'Pages / Management / Details' : 'Pages / Management',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9AA3B2),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
            child: showDetails
                ? ManagementDetailsView(
                    tabIndex: tabIndex,
                    onBack: () {
                      setState(() {
                        showDetails = false;
                        tabIndex = 0;
                      });
                    },
                    onTabChange: (index) {
                      setState(() {
                        tabIndex = index;
                      });
                    },
                  )
                : ManagementOverallView(
                    onOpenAudit: () {
                      setState(() {
                        showDetails = true;
                        tabIndex = 0;
                      });
                    },
                    onOpenInvitations: () {
                      setState(() {
                        showDetails = true;
                        tabIndex = 1;
                      });
                    },
                    onOpenApplications: () {
                      setState(() {
                        showDetails = true;
                        tabIndex = 2;
                      });
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
