import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'pharmaceuticals_dashboard_page.dart';
import 'pharmaceuticals_help_page.dart';
import 'pharmaceuticals_inventory_page.dart';
import 'pharmaceuticals_prescriptions_page.dart';
import '../widgets/view/pharmaceuticals_profile_view_page.dart';
import 'pharmaceuticals_messages_page.dart';
import 'pharmaceuticals_clinical_trial_page.dart';
import '../widgets/clinical_trial/pharmaceuticals_clinical_trial_add_page.dart';
import '../widgets/clinical_trial/pharmaceuticals_specific_trial_page.dart';
import 'pharmaceuticals_management_page.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/Login_Screen.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/CRD_Screen.dart';

const _primary = Color(0xFF1E4ED8);
const _bg = Color(0xFFF5F7FB);

class PharmaOfficeShell extends StatefulWidget {
  const PharmaOfficeShell({super.key});

  @override
  State<PharmaOfficeShell> createState() => _PharmaOfficeShellState();
}

class _PharmaOfficeShellState extends State<PharmaOfficeShell> {
  String selectedKey = 'Dashboard';

  static const _pages = [
    ('Dashboard',     Icons.dashboard),
    ('Clinical Trial', Icons.biotech_outlined),
    ('Messages',      Icons.message_outlined),
    ('Management',    Icons.account_tree_outlined),
    ('Inventory',     Icons.inventory_2_outlined),
    ('Prescriptions', Icons.description_outlined),
    ('Help',          Icons.help_outline_rounded),
    ('CRD',           Icons.hub_outlined),
  ];

  Widget _buildPage() {
    switch (selectedKey) {
      case 'Management':         return const PharmaceuticalsManagementPage();
      case 'Help':               return const PharmaceuticalsHelpPage();
      case 'CRD':                return const ClinicalReasoningDashboard();
      case 'Inventory':          return const PharmaceuticalsInventoryPage();
      case 'Prescriptions':    return const PharmaceuticalsPrescriptionsPage();
      case 'View':             return const PharmaceuticalsProfileViewPage();
      case 'Clinical Trial Add': return const PharmaceuticalsClinicalTrialAddPage();
      case 'Specific Trial':   return const PharmaceuticalsSpecificTrialPage();
      case 'Clinical Trial':   return const PharmaceuticalsClinicalTrialPage();
      case 'Messages':         return const PharmaceuticalsMessagesPage();
      case 'Dashboard':
      default:                 return const PharmaceuticalsDashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Scaffold(
          backgroundColor: _bg,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: _primary),
                  title: Image.asset('assets/ehospital_logo.png', height: 36, fit: BoxFit.contain),
                )
              : null,
          drawer: isMobile ? _buildSidebar(isDrawer: true) : null,
          body: Row(
            children: [
              if (!isMobile)
                SizedBox(width: 240, child: _buildSidebar(isDrawer: false)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top bar (desktop only)
                    if (!isMobile) _TopBar(pageTitle: selectedKey),
                    Expanded(child: _buildPage()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar({required bool isDrawer}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Image.asset(
              'assets/ehospital_logo.png',
              height: 54,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final (label, icon) in _pages)
                    _MenuItem(
                      icon: icon,
                      label: label,
                      selected: selectedKey == label,
                      onTap: () {
                        setState(() => selectedKey = label);
                        if (isDrawer) Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              if (isDrawer) Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String pageTitle;
  const _TopBar({required this.pageTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Pharmaceutical Office  /  $pageTitle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB76BFF), Color(0xFF6B7CFF)],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'AI Assistant',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          const Icon(Icons.notifications_none, color: Colors.black54),
          const SizedBox(width: 10),
          const Icon(Icons.person_outline, color: Colors.black54),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? _primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.grey, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.grey,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}