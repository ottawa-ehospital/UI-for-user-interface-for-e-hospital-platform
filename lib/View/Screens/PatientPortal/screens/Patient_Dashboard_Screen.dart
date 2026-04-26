import 'package:ehosptal_flutter_revamp/Service/API_service.dart';
import 'package:ehosptal_flutter_revamp/View/Widgets/Patient_Appointments_Overview.dart';
import 'package:ehosptal_flutter_revamp/View/Widgets/Patient_Health_Summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/PatientPortal/screens/Messaging_Screen.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/PatientPortal/screens/My_Health_Screen.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/PatientPortal/screens/Patient_Appointment_Screen.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/Login_Screen.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/CRD_Screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDashboardScreen({super.key, required this.patient});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

String _capFirst(String s) {
  final t = s.trim();
  if (t.isEmpty) return t;
  return t[0].toUpperCase() + t.substring(1);
}
class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final ApiService _api = ApiService();

  int selectedIndex = 0;
  Map<String, dynamic>? profileData;
  bool loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final id = widget.patient["id"] ?? widget.patient["patientId"];
      if (id == null) {
        setState(() {
          profileData = widget.patient;
          loadingProfile = false;
        });
        return;
      }

      final res = await _api.getPatientPortalInfoById(patientId: id);
      setState(() {
        profileData = res;
        loadingProfile = false;
      });
    } catch (_) {
      setState(() {
        profileData = widget.patient;
        loadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  title: const Text("eHospital",
                      style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
                )
              : null,
          drawer: isMobile ? _buildSidebar(primary, isDrawer: true) : null,
          body: Row(
            children: [
              if (!isMobile)
                SizedBox(width: 240, child: _buildSidebar(primary, isDrawer: false)),
              Expanded(
                child: Container(
                  color: bg,
                    padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 600 ? 12 : 24,
                    vertical: 16,
                    ),
                  child: selectedIndex == 0
                      ? (loadingProfile
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              child: _dashboardContent(isMobile: isMobile),
                            ))
                      : _placeholder(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    switch (selectedIndex) {
      case 1:
        return PatientAppointmentScreen(
          patientId: widget.patient["id"] ?? widget.patient["patientId"],
        );
      case 2:
        return MyHealthScreen(patient: widget.patient);
      case 3:
        return MessagingScreen(patient: widget.patient);
      case 4:
        return const Center(child: Text("Help (Coming Soon)"));
      case 5:
        return const ClinicalReasoningDashboard();
      default:
        return const Center(child: Text("Coming Soon"));
    }
  }

  String _capFirst(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1);
  }

  Widget _dashboardContent({required bool isMobile}) {
    final rawName = (profileData?["FName"] ??
        profileData?["Fname"] ??
        profileData?["name"] ??
        "Patient")
    .toString();

    final name = _capFirst(rawName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // top row
        Row(
          children: [
            const Expanded(
              child: Text(
                "Patient Portal  /  Dashboard",
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
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 14),
            const Icon(Icons.notifications_none, color: Colors.black54),
            const SizedBox(width: 10),
            const Icon(Icons.person_outline, color: Colors.black54),
          ],
        ),

        const SizedBox(height: 14),

        // banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E4ED8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "Hello $name,\nWelcome to the patient portal. Here you can access your medical information and more.",
            style: const TextStyle(
             color: Colors.white,
             fontWeight: FontWeight.w800,
             fontSize: 16,
             height: 1.25,
            ),
           ),
         ),

        const SizedBox(height: 16),

        // panels
        if (isMobile) ...[
          PatientAppointmentsOverview(patient: widget.patient),
          const SizedBox(height: 14),
          PatientHealthSummary(patient: widget.patient),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: PatientAppointmentsOverview(patient: widget.patient)),
              const SizedBox(width: 14),
              Expanded(child: PatientHealthSummary(patient: widget.patient)),
            ],
          ),
        ],
      ],
    );
  }

  // sidebar
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
          _menuItem(Icons.calendar_today, "Appointments", 1, isDrawer),
          _menuItem(Icons.favorite_border, "My Health", 2, isDrawer),
          _menuItem(Icons.message_outlined, "Messages", 3, isDrawer),
          _menuItem(Icons.help_outline, "Help", 4, isDrawer),
          _menuItem(Icons.hub_outlined, "CRD", 5, isDrawer),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
            child: Row(
              children: const [
                Icon(Icons.chat_bubble_outline, size: 18, color: Colors.black45),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Feedback",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black45),
                  ),
                ),
              ],
            ),
          ),

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
    const primary = Color(0xFF3F51B5);
    final selected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: selected
          ? BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: InkWell(
        onTap: () {
          setState(() => selectedIndex = index);
          if (isDrawer) Navigator.pop(context);
        },
        child: Row(
          children: [
            Icon(icon, color: selected ? primary : Colors.grey, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? primary : Colors.grey,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}