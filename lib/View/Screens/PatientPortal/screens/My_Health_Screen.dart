import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ehosptal_flutter_revamp/Service/API_service.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
//  MyHealthScreen — Patient portal My Health section
//
//  Sub-sections:
//    1. Medical Records — filterable by type, search, status badges
//    2. Medications     — current/past/refillable, request refill modals
// ─────────────────────────────────────────────────────────────────────────────
 
class MyHealthScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  const MyHealthScreen({super.key, required this.patient});
 
  @override
  State<MyHealthScreen> createState() => _MyHealthScreenState();
}
 
class _MyHealthScreenState extends State<MyHealthScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF3F51B5);
  static const Color _bg = Color(0xFFF5F7FB);
 
  late TabController _tabController;
 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
 
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
 
  dynamic get _patientId =>
      widget.patient['id'] ?? widget.patient['patientId'];
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Page header ───────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Patient Portal / My Health',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 4),
              const Text('My Health',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A237E))),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: _primary,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: _primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [
                  Tab(text: 'Medical Records'),
                  Tab(text: 'Medications'),
                ],
              ),
            ],
          ),
        ),
 
        // ── Tab content ───────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MedicalRecordsTab(patientId: _patientId),
              _MedicationsTab(patientId: _patientId),
            ],
          ),
        ),
      ],
    );
  }
}
 
// ═════════════════════════════════════════════════════════════════════════════
//  MEDICAL RECORDS TAB
// ═════════════════════════════════════════════════════════════════════════════
 
class _MedicalRecordsTab extends StatefulWidget {
  final dynamic patientId;
  const _MedicalRecordsTab({required this.patientId});
 
  @override
  State<_MedicalRecordsTab> createState() => _MedicalRecordsTabState();
}
 
class _MedicalRecordsTabState extends State<_MedicalRecordsTab> {
  static const Color _primary = Color(0xFF3F51B5);
  static const Color _bg = Color(0xFFF5F7FB);
 
  final ApiService _api = ApiService();
 
  bool _loading = true;
  String? _error;
 
  // raw data buckets
  List<Map<String, dynamic>> _bloodTests = [];
  Map<String, List<Map<String, dynamic>>> _imageRecords = {};
 
  // filter state
  String _activeType = 'All';
  String _searchQuery = '';
  String _bodyPartFilter = 'All Body Parts';
 
  static const List<String> _recordTypes = [
    'All', 'MRI', 'CT Scan', 'X-Ray', 'Blood Test', 'Signal Analysis'
  ];
 
  @override
  void initState() {
    super.initState();
    _loadAll();
  }
 
  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Blood tests
      final btRaw = await _api.getBloodtestByPatientId(patientId: widget.patientId);
      List<Map<String, dynamic>> btList = [];
      if (btRaw is List) btList = btRaw.whereType<Map<String, dynamic>>().toList();
      else if (btRaw is Map && btRaw['result'] is List) {
        btList = (btRaw['result'] as List).whereType<Map<String, dynamic>>().toList();
      }
 
      // Image records — fetch in parallel
      final imageTypes = ['MRI_Brain', 'X-Ray_Chest', 'CT Scan', 'Signal Analysis'];
      final futures = imageTypes.map((t) =>
          _api.imageRetrieveByPatientId(patientId: widget.patientId, recordType: t)
              .then((r) => MapEntry(t == 'MRI_Brain' ? 'MRI' : t == 'X-Ray_Chest' ? 'X-Ray' : t,r.whereType<Map<String, dynamic>>().toList()))
              .catchError((_) => MapEntry(t, <Map<String, dynamic>>[]))
      );
      final results = await Future.wait(futures);
 
      setState(() {
        _bloodTests = btList;
        _imageRecords = Map.fromEntries(results);
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }
 
  List<Map<String, dynamic>> get _allRecords {
    final List<Map<String, dynamic>> all = [];
    // Blood tests
    for (final r in _bloodTests) {
      all.add({...r, '_recordType': 'Blood Test'});
    }
    // Image records
    for (final entry in _imageRecords.entries) {
      for (final r in entry.value) {
        all.add({...r, '_recordType': entry.key});
      }
    }
    // Sort by date descending
    all.sort((a, b) {
      final ad = _parseDate(a['test_date'] ?? a['record_date'] ?? a['date'] ?? a['RecordDate']);
      final bd = _parseDate(b['test_date'] ?? b['record_date'] ?? b['date'] ?? b['RecordDate']);
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return all;
  }
 
  List<Map<String, dynamic>> get _filtered {
    return _allRecords.where((r) {
      final type = r['_recordType'] ?? '';
      if (_activeType != 'All' && type != _activeType) return false;
      if (_searchQuery.isNotEmpty) {
        final name = (r['test_name'] ?? r['record_type'] ?? r['type'] ?? '').toString().toLowerCase();
        final body = (r['body_part'] ?? r['bodyPart'] ?? r['BodyPart'] ?? '').toString().toLowerCase();
        final dr = (r['doctor_name'] ?? r['doctorName'] ?? '').toString().toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase()) &&
            !body.contains(_searchQuery.toLowerCase()) &&
            !dr.contains(_searchQuery.toLowerCase())) return false;
      }
      if (_bodyPartFilter != 'All Body Parts') {
        final body = (r['body_part'] ?? r['bodyPart'] ?? r['BodyPart'] ?? '').toString();
        if (!body.toLowerCase().contains(_bodyPartFilter.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }
 
  List<String> get _bodyParts {
    final parts = <String>{'All Body Parts'};
    for (final r in _allRecords) {
      final b = (r['body_part'] ?? r['bodyPart'] ?? r['BodyPart'] ?? '').toString().trim();
      if (b.isNotEmpty) parts.add(b);
    }
    return parts.toList();
  }
 
  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try { return DateTime.parse(raw.toString()); } catch (_) { return null; }
  }
 
  String _formatDate(dynamic raw) {
    final dt = _parseDate(raw);
    if (dt == null) return '—';
    return DateFormat('MMM d, yyyy').format(dt);
  }
 
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError();
 
    return Container(
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.folder_open_outlined, size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No records found',
                          style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                    ]),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _recordCard(_filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Medical Records',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Easily search, filter, and review your medical records—all in one place.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 16),
 
          // Search + body part filter row
          Row(children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search by test, body part, doctor...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _bodyPartFilter,
                  items: _bodyParts.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _bodyPartFilter = v!),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                ),
              ),
            ),
          ]),
 
          const SizedBox(height: 12),
 
          // Type filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _recordTypes.map((t) {
                final active = _activeType == t;
                return GestureDetector(
                  onTap: () => setState(() => _activeType = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? _primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? _primary : Colors.grey[300]!),
                    ),
                    child: Text(t,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : Colors.grey[700])),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _recordCard(Map<String, dynamic> r) {
    final type     = (r['_recordType'] ?? 'Record').toString();
    final name     = (r['test_name'] ?? r['record_type'] ?? r['type'] ?? type).toString();
    final body     = (r['body_part'] ?? r['bodyPart'] ?? r['BodyPart'] ?? '—').toString();
    final date     = _formatDate(r['test_date'] ?? r['record_date'] ?? r['date'] ?? r['RecordDate']);
    final doctor   = (r['doctor_name'] ?? r['doctorName'] ?? r['DoctorName'] ?? '').toString();
    final desc     = (r['description'] ?? r['notes'] ?? r['result_value'] ?? '').toString();
    final status   = (r['status'] ?? r['result_status'] ?? '').toString();
 
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _typeColor(type).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon(type), color: _typeColor(type), size: 22),
          ),
          const SizedBox(width: 14),
 
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  _statusBadge(status),
                ]),
                const SizedBox(height: 4),
                if (desc.isNotEmpty)
                  Text(desc,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(body, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  if (doctor.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.person_outline, size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Expanded(child: Text(doctor,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
                  ],
                ]),
              ],
            ),
          ),
          const SizedBox(width: 12),
 
          // View Report button
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: _primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: _primary.withOpacity(0.3))),
            ),
            child: const Text('View Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
 
  Widget _statusBadge(String status) {
    if (status.isEmpty) return const SizedBox.shrink();
    Color bg; Color fg;
    final s = status.toLowerCase();
    if (s.contains('normal') || s.contains('clear')) {
      bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2E7D32);
    } else if (s.contains('pending')) {
      bg = const Color(0xFFFFF8E1); fg = const Color(0xFFF57F17);
    } else if (s.contains('recommend') || s.contains('action')) {
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
 
  Color _typeColor(String type) {
    switch (type) {
      case 'MRI':            return const Color(0xFF7C4DFF);
      case 'CT Scan':        return const Color(0xFF00ACC1);
      case 'X-Ray':          return const Color(0xFF3F51B5);
      case 'Blood Test':     return const Color(0xFFE53935);
      case 'Signal Analysis':return const Color(0xFF43A047);
      default:               return const Color(0xFF78909C);
    }
  }
 
  IconData _typeIcon(String type) {
    switch (type) {
      case 'MRI':            return Icons.my_library_books_outlined;
      case 'CT Scan':        return Icons.biotech_outlined;
      case 'X-Ray':          return Icons.monitor_heart_outlined;
      case 'Blood Test':     return Icons.water_drop_outlined;
      case 'Signal Analysis':return Icons.show_chart;
      default:               return Icons.description_outlined;
    }
  }
 
  Widget _buildError() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 12),
      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
    ]));
  }
}
 
// ═════════════════════════════════════════════════════════════════════════════
//  MEDICATIONS TAB
// ═════════════════════════════════════════════════════════════════════════════
 
class _MedicationsTab extends StatefulWidget {
  final dynamic patientId;
  const _MedicationsTab({required this.patientId});
 
  @override
  State<_MedicationsTab> createState() => _MedicationsTabState();
}
 
class _MedicationsTabState extends State<_MedicationsTab> {
  static const Color _primary = Color(0xFF3F51B5);
  static const Color _bg = Color(0xFFF5F7FB);
 
  final ApiService _api = ApiService();
 
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _allMeds = [];
 
  String _activeTab = 'Current';
  String _searchQuery = '';
 
  // multi-refill selection
  final Set<int> _selectedForRefill = {};
 
  @override
  void initState() {
    super.initState();
    _loadMeds();
  }
 
  Future<void> _loadMeds() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await _api.getPrescriptionsByPatientId(patientId: widget.patientId);
      List<Map<String, dynamic>> list = [];
      if (raw is List) list = raw.whereType<Map<String, dynamic>>().toList();
      else if (raw is Map) {
        final r = raw['result'] ?? raw['data'] ?? raw['prescriptions'];
        if (r is List) list = r.whereType<Map<String, dynamic>>().toList();
      }
      setState(() { _allMeds = list; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }
 
  List<Map<String, dynamic>> get _filtered {
    return _allMeds.where((m) {
      final status = (m['status'] ?? '').toString().toLowerCase();
      bool matchTab = true;
      if (_activeTab == 'Current') matchTab = status == 'active' || status == 'current' || status.isEmpty;
      if (_activeTab == 'Past')    matchTab = status == 'completed' || status == 'expired' || status == 'discontinued';
      if (_activeTab == 'Refillable') matchTab = status == 'active' || status == 'current' || status.isEmpty;
 
      if (!matchTab) return false;
      if (_searchQuery.isNotEmpty) {
        final name = _medName(m).toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }
 
  String _medName(Map<String, dynamic> m) {
    // medicine_name is the linked drug name (e.g. "Metformin", "Amoxicillin")
    final linked = (m['medicine_name'] ?? '').toString().trim();
    if (linked.isNotEmpty) return linked;
    // fall back to first part of prescription_description before comma
    final desc = (m['prescription_description'] ?? '').toString().trim();
    if (desc.isNotEmpty) return desc.split(',').first.trim();
    return 'Unknown';
  }
 
  String _medStrength(Map<String, dynamic> m) {
    final dose = (m['dose'] ?? 0).toString().trim();
    final unit = (m['dose_unit'] ?? '').toString().trim();
    if (dose != '0' && dose.isNotEmpty && unit.isNotEmpty) return '$dose $unit';
    if (dose != '0' && dose.isNotEmpty) return dose;
    return '';
  }
 
  String _medDose(Map<String, dynamic> m) {
    final dose  = (m['dose'] ?? 0);
    final unit  = (m['dose_unit'] ?? '').toString().trim();
    final freq  = (m['frequency'] ?? '').toString().trim();
    final qty   = (m['quantity'] ?? 0);
    final qUnit = (m['quantity_unit'] ?? '').toString().trim();
 
    final parts = <String>[];
    if (dose.toString() != '0' && dose.toString().isNotEmpty)
      parts.add('$dose${unit.isNotEmpty ? " $unit" : ""}');
    if (freq.isNotEmpty) parts.add(freq);
    if (qty.toString() != '0' && qUnit.isNotEmpty) parts.add('$qty $qUnit');
 
    if (parts.isNotEmpty) return parts.join('  •  ');
 
    // fall back to description after first comma
    final desc = (m['prescription_description'] ?? '').toString();
    final i = desc.indexOf(',');
    return i != -1 ? desc.substring(i + 1).trim() : '—';
  }
 
  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try { return DateFormat('MMM d, yyyy').format(DateTime.parse(raw.toString())); }
    catch (_) { return raw.toString(); }
  }
 
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError();
 
    return Container(
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: _filtered.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.medication_outlined, size: 56, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('No medications found',
                        style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                  ]))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _medCard(_filtered[i], i),
                  ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Medications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Review your current and past medications in one place.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
              ]),
            ),
            // Request Multiple Refills button
            if (_activeTab == 'Refillable' && _selectedForRefill.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _showMultiRefillModal,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text('Request Refills (${_selectedForRefill.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => setState(() => _activeTab = 'Refillable'),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Request Multiple Refills'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ]),
          const SizedBox(height: 16),
 
          // Tabs + search
          Row(children: [
            // Tab pills
            ...['Current', 'Past', 'Refillable'].map((t) {
              final active = _activeTab == t;
              return GestureDetector(
                onTap: () => setState(() { _activeTab = t; _selectedForRefill.clear(); }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? _primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? _primary : Colors.grey[300]!),
                  ),
                  child: Text(t,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: active ? Colors.white : Colors.grey[700])),
                ),
              );
            }),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search medications...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
 
  Widget _medCard(Map<String, dynamic> m, int index) {
    final name     = _medName(m);
    final strength = _medStrength(m);
    final dose     = _medDose(m);
    final doctor   = (m['doctor_name'] ?? m['doctorName'] ?? m['prescribed_by'] ?? '').toString();
    final start    = _formatDate(m['start_date'] ?? m['prescription_creation_time'] ?? m['StartDate']);
    final end      = _formatDate(m['end_date'] ?? m['EndDate']);
    final refills  = m['refill'] ?? m['refills'] ?? m['refill_count'] ?? 0;
    final notes    = (m['prescription_description'] ?? m['notes'] ?? '').toString();
    final status   = (m['status'] ?? 'Active').toString();
    final isRefillable = _activeTab == 'Refillable';
    final isSelected = _selectedForRefill.contains(index);
 
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: _primary, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox for refillable tab
          if (isRefillable) ...[
            Checkbox(
              value: isSelected,
              activeColor: _primary,
              onChanged: (v) => setState(() {
                if (v == true) _selectedForRefill.add(index);
                else _selectedForRefill.remove(index);
              }),
            ),
            const SizedBox(width: 4),
          ],
 
          // Med icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medication_outlined, color: Color(0xFF3F51B5), size: 22),
          ),
          const SizedBox(width: 14),
 
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$name${strength.isNotEmpty ? " $strength" : ""}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        if (dose.isNotEmpty)
                          Text(dose, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  _statusBadge(status),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 16, runSpacing: 4, children: [
                  if (doctor.isNotEmpty) _infoChip(Icons.person_outline, doctor),
                  _infoChip(Icons.calendar_today_outlined, 'Since $start'),
                  if (end != '—') _infoChip(Icons.event_outlined, 'Until $end'),
                  _infoChip(Icons.refresh, 'Refills: $refills'),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 12),
 
          // Request Refill button (current/refillable)
          if (_activeTab != 'Past')
            TextButton(
              onPressed: () => _showRefillModal(m),
              style: TextButton.styleFrom(
                foregroundColor: _primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: _primary.withOpacity(0.3))),
              ),
              child: const Text('Request Refill',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
 
  Widget _infoChip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: Colors.grey[400]),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
    ]);
  }
 
  Widget _statusBadge(String status) {
    final s = status.toLowerCase();
    Color bg; Color fg;
    if (s == 'active' || s == 'current') {
      bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2E7D32);
    } else if (s == 'completed') {
      bg = const Color(0xFFE3F2FD); fg = const Color(0xFF1565C0);
    } else if (s == 'discontinued') {
      bg = const Color(0xFFFFEBEE); fg = const Color(0xFFC62828);
    } else {
      bg = const Color(0xFFF5F5F5); fg = const Color(0xFF757575);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
 
  // ── Refill Modals ──────────────────────────────────────────────────────────
 
  void _showRefillModal(Map<String, dynamic> med) {
    final name = _medName(med);
    final dose = _medDose(med);
    int quantity = 1;
 
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(child: Text('Request Refill',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  IconButton(onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close)),
                ]),
                const Divider(height: 20),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                if (dose.isNotEmpty)
                  Text(dose, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 16),
                const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children: [
                  IconButton(
                    onPressed: () => setS(() => quantity = (quantity - 1).clamp(1, 99)),
                    icon: const Icon(Icons.remove_circle_outline),
                    color: _primary,
                  ),
                  Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(
                    onPressed: () => setS(() => quantity++),
                    icon: const Icon(Icons.add_circle_outline),
                    color: _primary,
                  ),
                  Text('pack(s)', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ]),
                const SizedBox(height: 8),
                Text('This will be sent to Dr. ${med['doctor_FName'] ?? med['doctor_name'] ?? 'your doctor'} ${med['doctor_LName'] ?? ''} for approval.'.trim(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Refill request sent for $name')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
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
 
  void _showMultiRefillModal() {
    final selected = _selectedForRefill
        .map((i) => _filtered[i])
        .toList();
 
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(child: Text('Request Multiple Refills',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                IconButton(onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ]),
              const Divider(height: 20),
              Text('${selected.length} medication(s) selected',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 12),
              ...selected.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.medication_outlined, size: 16, color: Color(0xFF3F51B5)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_medName(m),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  Text(_medDose(m),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ]),
              )),
              const Divider(height: 20),
              Text('All requests will be sent to your doctors for approval.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _selectedForRefill.clear());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Refill requests submitted successfully')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
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
    );
  }
 
  Widget _buildError() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 12),
      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _loadMeds, child: const Text('Retry')),
    ]));
  }
}