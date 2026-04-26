import 'dart:convert';
import 'package:ehosptal_flutter_revamp/Service/API_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
 
class PatientAppointmentsOverview extends StatefulWidget {
  final Map<String, dynamic> patient;
  const PatientAppointmentsOverview({super.key, required this.patient});
 
  @override
  State<PatientAppointmentsOverview> createState() => _PatientAppointmentsOverviewState();
}
 
class _PatientAppointmentsOverviewState extends State<PatientAppointmentsOverview> {
  static const Color _primary = Color(0xFF3F51B5);
  final ApiService _api = ApiService();
 
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> appts = [];
 
  @override
  void initState() {
    super.initState();
    _fetchToday();
  }
 
  DateTime _startOfDayLocal(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDayLocal(DateTime d)   => DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
 
  Map<String, dynamic> _buildLoginData() {
    return {
      "type": "Patient",
      "id": widget.patient["id"],
      "name": "${widget.patient["Fname"] ?? widget.patient["FName"] ?? widget.patient["name"] ?? "Patient"}",
      "email": widget.patient["EmailId"] ?? widget.patient["email"] ?? "",
      "startInPage": "/patient/dashboard",
    };
  }
 
  Future<void> _fetchToday() async {
    setState(() { loading = true; error = null; });
    try {
      final now   = DateTime.now();
      final start = _startOfDayLocal(now);
      final end   = _endOfDayLocal(now);
 
      final result = await _api.patientMainPageGetCalendar(
        loginData: _buildLoginData(),
        start: start,
        end: end,
        timezone: "America/Toronto",
      );
 
      setState(() { appts = result; loading = false; });
    } catch (e) {
      setState(() { loading = false; error = e.toString(); });
    }
  }
 
  // ── Helpers ────────────────────────────────────────────────────────────────
 
  String _formatStart(dynamic start) {
    try {
      final dt = DateTime.parse(start.toString()).toLocal();
      return DateFormat("MMM d, h:mm a").format(dt);
    } catch (_) { return "Time unavailable"; }
  }
 
  String _formatTimeRange(dynamic start, dynamic end) {
    try {
      final s = DateFormat("h:mm a").format(DateTime.parse(start.toString()).toLocal());
      final e = DateFormat("h:mm a").format(DateTime.parse(end.toString()).toLocal());
      return "$s – $e";
    } catch (_) { return _formatStart(start); }
  }
 
  String _doctorName(Map<String, dynamic> item) {
    final doc = item["doctor"];
    if (doc is Map) {
      final fn = (doc["Fname"] ?? doc["FName"] ?? doc["name"] ?? "").toString();
      final ln = (doc["Lname"] ?? doc["LName"] ?? "").toString();
      return "$fn $ln".trim().isNotEmpty ? "$fn $ln".trim() : "Doctor";
    }
    return (item["doctor_name"] ?? item["doctorName"] ?? "Doctor").toString();
  }
 
  String _locationLabel(Map<String, dynamic> item) {
    final isVirtual = item["isVirtual"] == true || item["Virtual"] == true;
    if (isVirtual) return "Virtual";
    final loc = item["location"] ?? item["Location"] ?? item["clinic"] ?? item["Clinic"];
    if (loc != null && loc.toString().trim().isNotEmpty) return loc.toString();
    return "uOttawa Clinic";
  }
 
  String _apptType(Map<String, dynamic> item) =>
      (item["appointment_type"] ?? item["appointmentType"] ?? item["type"] ?? "General Consultation").toString();
 
  String _apptStatus(Map<String, dynamic> item) =>
      (item["status"] ?? item["Status"] ?? "Scheduled").toString();
 
  String _doctorContact(Map<String, dynamic> item) {
    final doc = item["doctor"];
    if (doc is Map) return (doc["phone"] ?? doc["contact"] ?? "").toString();
    return "";
  }
 
  String _doctorSpecialty(Map<String, dynamic> item) {
    final doc = item["doctor"];
    if (doc is Map) return (doc["specialty"] ?? doc["Specialty"] ?? "").toString();
    return "";
  }
 
  // ── Appointment Detail Popup ───────────────────────────────────────────────
 
  void _showAppointmentDetail(Map<String, dynamic> item) {
    final doctor    = _doctorName(item);
    final specialty = _doctorSpecialty(item);
    final timeRange = _formatTimeRange(item["start"] ?? item["Start"], item["end"] ?? item["End"]);
    final location  = _locationLabel(item);
    final type      = _apptType(item);
    final status    = _apptStatus(item);
    final contact   = _doctorContact(item);
    final isVirtual = item["isVirtual"] == true || item["Virtual"] == true;
    final notes     = (item["notes"] ?? item["description"] ?? "").toString();
 
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                const Expanded(child: Text("Appointment Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              const Divider(height: 20),
 
              // Doctor
              _detailRow(Icons.person_outline, "Dr. $doctor",
                  specialty.isNotEmpty ? specialty : "Physician"),
 
              // Time
              _detailRow(Icons.access_time_outlined, timeRange, ""),
 
              // Location
              _detailRow(Icons.location_on_outlined, location, ""),
 
              // Type
              _detailRow(Icons.medical_services_outlined, type, ""),
 
              // Contact
              if (contact.isNotEmpty) _detailRow(Icons.phone_outlined, contact, ""),
 
              // Notes
              if (notes.isNotEmpty) _detailRow(Icons.notes_outlined, notes, ""),
 
              // Status
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 10),
                const Text("Status ", style: TextStyle(fontSize: 13, color: Colors.black54)),
                _statusBadge(status),
              ]),
 
              const SizedBox(height: 20),
 
              // Action buttons
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: _primary),
                      foregroundColor: _primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Edit", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                if (isVirtual) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.videocam_outlined, size: 16),
                      label: const Text("Join Video Call"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _detailRow(IconData icon, String primary, String secondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(primary, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (secondary.isNotEmpty)
              Text(secondary, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        )),
      ]),
    );
  }
 
  Widget _statusBadge(String status) {
    final s = status.toLowerCase();
    Color bg; Color fg;
    if (s.contains('approv') || s.contains('confirm') || s.contains('scheduled')) {
      bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2E7D32);
    } else if (s.contains('pending') || s.contains('wait')) {
      bg = const Color(0xFFFFF8E1); fg = const Color(0xFFF57F17);
    } else if (s.contains('cancel') || s.contains('declin')) {
      bg = const Color(0xFFFFEBEE); fg = const Color(0xFFC62828);
    } else {
      bg = const Color(0xFFE3F2FD); fg = const Color(0xFF1565C0);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(blurRadius: 30, offset: const Offset(0, 14), color: Colors.black.withOpacity(0.06))],
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null ? _errorBox() : _content(),
    );
  }
 
  Widget _errorBox() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Appointment Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Text("Failed to load appointments:\n$error", style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 10),
      ElevatedButton(onPressed: _fetchToday, child: const Text("Retry")),
    ]);
  }
 
  Widget _content() {
    final top2 = appts.take(2).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Appointment Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      const Text("Upcoming Appointments", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
 
      if (top2.isEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(12)),
          child: const Text("No upcoming appointments today."),
        )
      else
        ...top2.map((item) => _appointmentTile(item)),
 
      const SizedBox(height: 6),
      Wrap(
  alignment: WrapAlignment.spaceBetween,
  children: [
    TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add_circle_outline),
      label: const Text("Book New Appointments"),
    ),
    TextButton(
      onPressed: () {},
      child: const Text("View All Appointments  >"),
    ),
  ],
),
 
      const Divider(height: 26),
 
      const Text("Pending Referral / Task",
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(12)),
        child: const Text("Pending items will appear here."),
      ),
    ]);
  }
 
  Widget _appointmentTile(Map<String, dynamic> item) {
    final doctor  = "Dr. ${_doctorName(item)}";
    final dateText = _formatStart(item["start"] ?? item["Start"]);
    final loc     = _locationLabel(item);
 
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doctor, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.access_time, size: 14, color: Colors.black54),
              const SizedBox(width: 4),
              Text(dateText, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(width: 14),
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.black54),
              const SizedBox(width: 4),
              Expanded(child: Text(loc,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                  overflow: TextOverflow.ellipsis)),
            ]),
          ]),
        ),
        TextButton(
          onPressed: () => _showAppointmentDetail(item),
          child: const Text("View Details"),
        ),
      ]),
    );
  }
}