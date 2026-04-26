import 'package:ehosptal_flutter_revamp/View/Screens/Patient_List_Screen.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/Orchestrator_Screen.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/Orchestrator_Chat_Screen.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/Messages_Screen.dart';
import 'package:ehosptal_flutter_revamp/View/Widgets/Appointments_Section.dart';
import 'package:ehosptal_flutter_revamp/View/Widgets/Tasks_Section.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/Calendar_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/Billing_Screen.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/Login_Screen.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/CRD_Screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const DoctorDashboardScreen({super.key, required this.doctor});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int selectedIndex = 0; // 0 = Dashboard, 1 = Patients, etc.

  @override
  Widget build(BuildContext context) {
    debugPrint("DOCTOR DASHBOARD BUILD => ${DateTime.now()}");
    const primary = Color(0xFF3F51B5);
    const bg = Color(0xFFF5F7FB);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Scaffold(
          backgroundColor: bg,

          appBar: isMobile
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: primary),
                  title: const Text(
                    "eHospital",
                    style: TextStyle(color: primary),
                  ),
                )
              : null,

          drawer: isMobile ? _buildSidebar(primary, isDrawer: true) : null,

          body: Row(
            children: [
              if (!isMobile)
                SizedBox(
                  width: 240,
                  child: _buildSidebar(primary, isDrawer: false),
                ),

              Expanded(
                child: Container(
                  color: bg,
                  padding: const EdgeInsets.all(24),

                  // ✅ Only dashboard is scrollable (prevents PatientList layout issues)
                  child: selectedIndex == 0
                      ? SingleChildScrollView(
                          child: _dashboardContent(isMobile: isMobile),
                        )
                      : _buildContent(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= CONTENT SWITCHER =================
  Widget _buildContent() {
    if (selectedIndex == 0) {
      return _dashboardContent(isMobile: true);
    } else if (selectedIndex == 1) {
      return PatientListScreen(
        doctorId: widget.doctor["id"],
        embedded: true,
      );
    } else if (selectedIndex == 2) {
      return CalendarScreen(doctorId: widget.doctor['id'].toString());
    } else if (selectedIndex == 3) {
      return BillingScreen(doctorId: widget.doctor['id'].toString());
    } else if (selectedIndex == 4) {
      return MessagesScreen(doctor: widget.doctor);
    } else if (selectedIndex == 5) {
      return OrchestratorScreen(doctorId: widget.doctor['id'].toString());
    } else if (selectedIndex == 6) {
      return OrchestratorChatScreen(doctorId: widget.doctor['id'].toString());
    } else if (selectedIndex == 7) {
      return const ClinicalReasoningDashboard();
    } else {
      return const Center(child: Text("Coming Soon"));
    }
  }

  Widget _dashboardContent({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row
        Row(
          children: [
            const Expanded(
              child: Text(
                "Doctor Portal  /  Dashboard",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.black54),
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
                "AI Assistant",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 14),
            const Icon(Icons.notifications_none, color: Colors.black54),
            const SizedBox(width: 10),
            const Icon(Icons.person_outline, color: Colors.black54),
          ],
        ),

        const SizedBox(height: 14),

        // Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E4ED8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            "Hello, Doctor\nWish you a wonderful day at work.",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),

        const SizedBox(height: 16),

        // ✅ Fixed heights so Appointments/Tasks can safely use Expanded internally
        if (isMobile) ...[
          SizedBox(
            height: 560,
            child: AppointmentsSection(doctor: widget.doctor), // ✅ pass doctor
          ),
          const SizedBox(height: 14),
          const SizedBox(height: 790, child: TasksSection()),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: SizedBox(
                  height: 680,
                  child: AppointmentsSection(doctor: widget.doctor), // ✅ pass doctor
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                flex: 3,
                child: SizedBox(height: 750, child: TasksSection()),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  // ================= SIDEBAR =================
  Widget _buildSidebar(Color primary, {required bool isDrawer}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Image.asset(
              "assets/ehospital_logo.png",
              height: 54,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 30),

          _menuItem(Icons.dashboard, "Dashboard", 0, isDrawer),
          _menuItem(Icons.people, "Patients", 1, isDrawer),
          _menuItem(Icons.calendar_today, "Calendar", 2, isDrawer),
          _menuItem(Icons.receipt_long, "Billing", 3, isDrawer),
          _menuItem(Icons.message, "Messages", 4, isDrawer),
          _menuItem(Icons.smart_toy_outlined, "Clinical Analysis", 5, isDrawer),
          _menuItem(Icons.smart_toy_outlined, "Orchestrator Chat", 6, isDrawer),
          _menuItem(Icons.hub_outlined, "CRD", 7, isDrawer),

          const Spacer(),

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
            label: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, int index, bool isDrawer) {
  const blue = Color(0xFF1E4ED8);
  final selected = selectedIndex == index;

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    decoration: BoxDecoration(
      color: selected ? blue : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() => selectedIndex = index);
        if (isDrawer) Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.grey, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
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