import 'dart:convert';
import 'package:ehosptal_flutter_revamp/Service/API_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
 
class PatientHealthSummary extends StatefulWidget {
  final Map<String, dynamic> patient;
  const PatientHealthSummary({super.key, required this.patient});
 
  @override
  State<PatientHealthSummary> createState() => _PatientHealthSummaryState();
}
 
class _PatientHealthSummaryState extends State<PatientHealthSummary> {
  static const Color _primary = Color(0xFF3F51B5);
  final ApiService _api = ApiService();
 
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> meds = [];
  List<Map<String, dynamic>> recentRecords = [];
 
  @override
  void initState() {
    super.initState();
    _fetchHealth();
  }
 
  dynamic get _patientId => widget.patient["id"] ?? widget.patient["patientId"];
 
  Future<void> _fetchHealth() async {
    setState(() { loading = true; error = null; });
    try {
      if (_patientId == null) throw Exception("Missing patient id");
 
      final pres = await _api.getPrescriptionsByPatientId(patientId: _patientId);
      final List<Map<String, dynamic>> presList = [];
      if (pres is List) {
        for (final x in pres) { if (x is Map) presList.add(Map<String, dynamic>.from(x)); }
      } else if (pres is Map) {
        final inner = pres["result"] ?? pres["data"] ?? pres["success"];
        if (inner is List) {
          for (final x in inner) { if (x is Map) presList.add(Map<String, dynamic>.from(x)); }
        }
      }
 
      final xray  = await _api.imageRetrieveByPatientId(patientId: _patientId, recordType: "X-Ray_Chest");
      final blood = await _api.getBloodtestByPatientId(patientId: _patientId);
 
      final List<Map<String, dynamic>> records = [];
 
      Map<String, dynamic>? latestFromList(List<dynamic> items) {
        final parsed = items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        if (parsed.isEmpty) return null;
        parsed.sort((a, b) {
          final ad = DateTime.tryParse((a["RecordDate"] ?? a["test_date"] ?? a["record_time"] ?? a["date"] ?? "").toString());
          final bd = DateTime.tryParse((b["RecordDate"] ?? b["test_date"] ?? b["record_time"] ?? b["date"] ?? "").toString());
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad);
        });
        return parsed.first;
      }
 
      final latestXray  = latestFromList(xray);
      Map<String, dynamic>? latestBlood;
      if (blood is List) latestBlood = latestFromList(blood);
      else if (blood is Map) {
        final inner = blood["result"] ?? blood["data"] ?? blood["success"];
        if (inner is List) latestBlood = latestFromList(inner);
      }
 
      if (latestXray  != null) records.add({"type": "X-ray",      "body": "Chest",   "raw": latestXray});
      if (latestBlood != null) records.add({"type": "Blood Test",  "body": "General", "raw": latestBlood});
 
      setState(() { meds = presList; recentRecords = records; loading = false; });
    } catch (e) {
      setState(() { loading = false; error = e.toString(); });
    }
  }
 
  // ── Field helpers ──────────────────────────────────────────────────────────
 
  String _medName(Map<String, dynamic> m) {
    final linked = (m["medicine_name"] ?? "").toString().trim();
    if (linked.isNotEmpty) return linked;
    final desc = (m["prescription_description"] ?? "").toString().trim();
    if (desc.isNotEmpty) return desc.split(',').first.trim();
    return "Medication";
  }
 
  String _medDose(Map<String, dynamic> m) {
    final dose  = m["dose"] ?? 0;
    final unit  = (m["dose_unit"] ?? "").toString().trim();
    final freq  = (m["frequency"] ?? "").toString().trim();
    final qty   = m["quantity"] ?? 0;
    final qUnit = (m["quantity_unit"] ?? "").toString().trim();
    final parts = <String>[];
    if (dose.toString() != "0" && dose.toString().isNotEmpty)
      parts.add("$dose${unit.isNotEmpty ? " $unit" : ""}");
    if (freq.isNotEmpty) parts.add(freq);
    if (qty.toString() != "0" && qUnit.isNotEmpty) parts.add("$qty $qUnit");
    if (parts.isNotEmpty) return parts.join("  •  ");
    final desc = (m["prescription_description"] ?? "").toString();
    final i = desc.indexOf(',');
    return i != -1 ? desc.substring(i + 1).trim() : "—";
  }
 
  String _formatDate(dynamic raw) {
    if (raw == null) return "—";
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    return DateFormat("MMM d, yyyy").format(dt.toLocal());
  }
 
  String _formatRecordDate(Map<String, dynamic> raw) {
    final s = (raw["RecordDate"] ?? raw["test_date"] ?? raw["record_date"] ?? raw["record_time"] ?? raw["date"] ?? "").toString();
    final dt = DateTime.tryParse(s);
    if (dt == null) return "—";
    return DateFormat("MMM d, yyyy").format(dt.toLocal());
  }
 
  // ── Popups ─────────────────────────────────────────────────────────────────
 
  void _showMedDetail(Map<String, dynamic> m) {
    final name   = _medName(m);
    final dose   = _medDose(m);
    final doctor = "${m['doctor_FName'] ?? ''} ${m['doctor_LName'] ?? ''}".trim();
    final since  = _formatDate(m['prescription_creation_time'] ?? m['start_date']);
    final route  = (m['route'] ?? '').toString();
    final dur    = (m['duration'] ?? '').toString();
    final refill = m['refill'];
    final desc   = (m['prescription_description'] ?? '').toString();
 
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.medication_outlined, color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    if (dose != "—") Text(dose, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                )),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              const Divider(height: 24),
              if (doctor.isNotEmpty) _detailRow(Icons.person_outline,       "Prescribed by", "Dr. $doctor"),
              _detailRow(Icons.calendar_today_outlined,                      "Since",         since),
              if (route.isNotEmpty) _detailRow(Icons.route_outlined,         "Route",         route),
              if (dur.isNotEmpty)   _detailRow(Icons.timer_outlined,         "Duration",      dur),
              _detailRow(Icons.refresh,                                       "Refills left",  refill?.toString() ?? "0"),
              if (desc.isNotEmpty)  _detailRow(Icons.notes_outlined,         "Notes",         desc),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showRequestRefill();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Request Refill'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
 
  void _showRequestRefill() {
    // Build quantity map for each med
    final Map<int, int> quantities = { for (int i = 0; i < meds.length; i++) i: 1 };
    final Set<int> selected = {};
 
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(child: Text('Request Refill',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ]),
                Text('Select medications to refill',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                const Divider(height: 20),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: meds.length,
                    itemBuilder: (_, i) {
                      final m = meds[i];
                      final name = _medName(m);
                      final dose = _medDose(m);
                      final isSelected = selected.contains(i);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE8EAF6) : const Color(0xFFF5F7FB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? _primary : Colors.transparent),
                        ),
                        child: Row(children: [
                          Checkbox(
                            value: isSelected,
                            activeColor: _primary,
                            onChanged: (v) => setS(() {
                              if (v == true) selected.add(i); else selected.remove(i);
                            }),
                          ),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text(dose, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            ],
                          )),
                          // quantity stepper
                          if (isSelected) Row(children: [
                            IconButton(
                              iconSize: 18, padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              onPressed: () => setS(() => quantities[i] = (quantities[i]! - 1).clamp(1, 99)),
                              icon: const Icon(Icons.remove_circle_outline, color: _primary),
                            ),
                            Text('${quantities[i]}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            IconButton(
                              iconSize: 18, padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              onPressed: () => setS(() => quantities[i] = quantities[i]! + 1),
                              icon: const Icon(Icons.add_circle_outline, color: _primary),
                            ),
                          ]),
                        ]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text('This will be sent to your doctor(s) for approval.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selected.isEmpty ? null : () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Refill request sent for ${selected.length} medication(s)')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  void _showRecordDetail(Map<String, dynamic> record) {
    final raw    = (record["raw"] is Map) ? Map<String, dynamic>.from(record["raw"]) : <String, dynamic>{};
    final type   = record["type"].toString();
    final body   = record["body"].toString();
    final date   = _formatRecordDate(raw);
 
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(type,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              const Divider(height: 20),
              _detailRow(Icons.location_on_outlined,      "Body Part", body),
              _detailRow(Icons.calendar_today_outlined,   "Date",      date),
              // show all numeric values from blood test
              ...raw.entries
                .where((e) => e.value != null && e.value is num && e.key != 'id' && e.key != 'patient_id' && e.key != 'vitals_id')
                .map((e) => _detailRow(Icons.science_outlined, e.key, e.value.toString())),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: _primary),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
              child: Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600))),
        Expanded(child: Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
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
      const Text("Health Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Text("Failed to load health summary:\n$error", style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 10),
      ElevatedButton(onPressed: _fetchHealth, child: const Text("Retry")),
    ]);
  }
 
  Widget _content() {
    final showMeds = meds.take(4).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Health Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      const Text("Current Medication", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
 
      if (showMeds.isEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(12)),
          child: const Text("No medications found."),
        )
      else
        ...showMeds.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _medTile(m),
        )),
 
      const SizedBox(height: 12),
      Row(children: [
        TextButton.icon(
          onPressed: _showRequestRefill,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text("Request Refill"),
        ),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text("View All Medication  >")),
      ]),
 
      const Divider(height: 26),
 
      const Text("Recent Medical Records", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      _recordsTable(),
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(onPressed: () {}, child: const Text("View All Medical Records  >")),
      ),
    ]);
  }
 
  Widget _medTile(Map<String, dynamic> m) {
    return InkWell(
      onTap: () => _showMedDetail(m),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Expanded(flex: 6, child: Text(_medName(m),
              style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 10),
          Expanded(flex: 5, child: Text(_medDose(m),
              style: const TextStyle(color: Colors.black54, fontSize: 12), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right, color: Colors.black45),
        ]),
      ),
    );
  }
 
  Widget _recordsTable() {
    const TextStyle header = TextStyle(color: Colors.black54, fontWeight: FontWeight.w700);
    const TextStyle cell   = TextStyle(color: Colors.black87);
 
    Widget row(String a, String b, String c, Map<String, dynamic>? record) {
      return InkWell(
        onTap: record != null ? () => _showRecordDetail(record) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(flex: 3, child: Text(a, style: cell)),
            Expanded(flex: 3, child: Text(b, style: cell)),
            Expanded(flex: 3, child: Text(c, style: cell)),
            const Icon(Icons.chevron_right, size: 18, color: Colors.black45),
          ]),
        ),
      );
    }
 
    return Column(children: [
      Row(children: [
        Expanded(flex: 3, child: Text("Test Type", style: header)),
        Expanded(flex: 3, child: Text("Body Part", style: header)),
        Expanded(flex: 3, child: Text("Date",      style: header)),
        const SizedBox(width: 18),
      ]),
      const Divider(height: 18),
      if (recentRecords.isEmpty) ...[
        row("MRI",        "Brain",   "—", null),
        row("X-ray",      "Chest",   "—", null),
        row("Blood Test", "General", "—", null),
      ] else
        ...recentRecords.take(3).map((r) {
          final raw = (r["raw"] is Map) ? Map<String, dynamic>.from(r["raw"]) : <String, dynamic>{};
          return row(r["type"].toString(), r["body"].toString(), _formatRecordDate(raw), r);
        }),
    ]);
  }
}
 