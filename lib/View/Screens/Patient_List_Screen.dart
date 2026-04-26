import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:ehosptal_flutter_revamp/model/patient.dart';
import 'package:ehosptal_flutter_revamp/Service/API_service.dart';
import 'PatientProfileScreen.dart';

// If your package import ever fails (pubspec name mismatch), use these instead:
// import '../../model/patient.dart';
// import '../../Service/API_service.dart';

class PatientListScreen extends StatefulWidget {
  final dynamic doctorId;

  /// embedded=true => renders content only (for DoctorDashboardScreen)
  /// embedded=false => standalone Scaffold/AppBar page
  final bool embedded;

  const PatientListScreen({
    super.key,
    required this.doctorId,
    this.embedded = true,
  });

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;

  List<Patient> _allPatients = <Patient>[];
  List<Patient> _filtered = <Patient>[];

  int _page = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applySearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.doctorId == null) {
        throw Exception("doctorId is null. Ensure login response contains 'id'.");
      }

      final api = ApiService();
      final List<Patient> patients =
          await api.getDoctorPatientsAuthorized(doctorId: widget.doctorId);

      debugPrint("✅ Patients retrieved: ${patients.length}");

      if (!mounted) return;

      setState(() {
        _allPatients = patients;
        _filtered = List<Patient>.from(patients);
        _page = 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applySearch() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _page = 1;
      if (q.isEmpty) {
        _filtered = List<Patient>.from(_allPatients);
      } else {
        _filtered = _allPatients.where((p) {
          return p.fullName.toLowerCase().contains(q) ||
              p.id.toString().contains(q) ||
              p.phone.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  List<Patient> get _paged {
    final start = (_page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, _filtered.length);
    if (start >= _filtered.length) return <Patient>[];
    return _filtered.sublist(start, end);
  }

  int get _totalPages {
    final pages = (_filtered.length / _pageSize).ceil();
    return pages == 0 ? 1 : pages;
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return "-";
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  void _openPatientProfile(Patient p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientProfileScreen(patient: p),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3F51B5);
    const bg = Color(0xFFF5F7FB);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb row
            Row(
              children: [
                const Text(
                  "Doctor Portal  /  Patients",
                  style: TextStyle(color: Colors.black54),
                ),
                const Spacer(),
                _ActionButton(
                  label: "Refresh",
                  icon: Icons.refresh,
                  onTap: _loadPatients,
                ),
              ],
            ),
            const SizedBox(height: 10),

            const Text(
              "Your Patient List",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),

            // Main card like screenshot
            Expanded(
              child: Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                      color: Colors.black.withOpacity(0.06),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Search + action buttons row
                    // Use Wrap on smaller widths so it doesn't overflow.
                    LayoutBuilder(
                      builder: (context, c) {
                        final narrow = c.maxWidth < 1100;
                        if (narrow) {
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(width: 520, child: _SearchBox(controller: _searchController)),
                              _ActionButton(
                                label: "AI Chatbots",
                                icon: Icons.smart_toy_outlined,
                                onTap: () {},
                              ),
                              _ActionButton(
                                label: "Analytics",
                                icon: Icons.bar_chart_outlined,
                                onTap: () {},
                              ),
                              _ActionButton(
                                label: "Filter",
                                icon: Icons.filter_alt_outlined,
                                onTap: () {},
                              ),
                              _ActionButton(
                                label: "Archive",
                                icon: Icons.archive_outlined,
                                onTap: () {},
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: _SearchBox(controller: _searchController)),
                            const SizedBox(width: 12),
                            _ActionButton(
                              label: "AI Chatbots",
                              icon: Icons.smart_toy_outlined,
                              onTap: () {},
                            ),
                            const SizedBox(width: 10),
                            _ActionButton(
                              label: "Analytics",
                              icon: Icons.bar_chart_outlined,
                              onTap: () {},
                            ),
                            const SizedBox(width: 10),
                            _ActionButton(
                              label: "Filter",
                              icon: Icons.filter_alt_outlined,
                              onTap: () {},
                            ),
                            const SizedBox(width: 10),
                            _ActionButton(
                              label: "Archive",
                              icon: Icons.archive_outlined,
                              onTap: () {},
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    Expanded(child: _buildBody(isMobile, primary)),

                    const SizedBox(height: 10),

                    // Pagination footer
                    if (!_loading && _error == null)
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed:
                                _page > 1 ? () => setState(() => _page -= 1) : null,
                            icon: const Icon(Icons.chevron_left),
                            label: const Text("Previous"),
                          ),
                          const Spacer(),
                         (kIsWeb)? _PageNumbers(
                            current: _page,
                            total: _totalPages,
                            onSelect: (p) => setState(() => _page = p),
                          ): SizedBox.shrink(),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: _page < _totalPages
                                ? () => setState(() => _page += 1)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                            label: const Text("Next"),
                            style: FilledButton.styleFrom(backgroundColor: primary),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primary),
        title: const Text(
          "Your Patient List",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(padding: const EdgeInsets.all(16), child: content),
    );
  }

  Widget _buildBody(bool isMobile, Color primary) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const Icon(Icons.error_outline, size: 32, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text(
              "Failed to load patients\n$_error",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadPatients,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final rows = _paged;
    if (rows.isEmpty) {
      return const Center(
        child: Text("No patients found", style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPatients,
      child: isMobile ? _mobileList(rows, primary) : _desktopTable(rows, primary),
    );
  }

  // ✅ Desktop table styled like your screenshot (clean lines, spacing, link names)
  Widget _desktopTable(List<Patient> rows, Color primary) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: const Color(0xFFE5E7EB),
      ),
      child: LayoutBuilder(
  builder: (context, constraints) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: constraints.maxWidth),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            showCheckboxColumn: true,
            dividerThickness: 1,
            headingRowHeight: 56,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 72,
            horizontalMargin: 12,
            columnSpacing: constraints.maxWidth / 15, // 👈 dynamic spacing
            headingTextStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
            dataTextStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF111827),
            ),
            border: const TableBorder(
              horizontalInside:
                  BorderSide(color: Color(0xFFE5E7EB), width: 1),
              bottom:
                  BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            columns: const [
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Age")),
              DataColumn(label: Text("Gender")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Last Appointment")),
              DataColumn(label: Text("Last Diagnosis")),
            ],
            rows: rows.map((p) {
              return DataRow(
                cells: [
                  DataCell(
                    InkWell(
                      onTap: () => _openPatientProfile(p),
                      child: Text(
                        p.fullName,
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(p.age?.toString() ?? "-")),
                  DataCell(Text(p.gender.isEmpty ? "-" : p.gender)),
                  DataCell(
                    _StatusPillDropdown(
                      value: (p.status.isEmpty) ? "Active" : p.status,
                      onChanged: (newStatus) {
                        setState(() {
                          final idx =
                              _allPatients.indexWhere((x) => x.id == p.id);
                          if (idx != -1) {
                            _allPatients[idx] =
                                _allPatients[idx].copyWith(status: newStatus);
                          }
                          final fidx =
                              _filtered.indexWhere((x) => x.id == p.id);
                          if (fidx != -1) {
                            _filtered[fidx] =
                                _filtered[fidx].copyWith(status: newStatus);
                          }
                        });
                      },
                    ),
                  ),
                  DataCell(Text(_fmtDate(p.lastAppointment))),
                  DataCell(Text(
                      p.lastDiagnosis.isEmpty ? "-" : p.lastDiagnosis)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  },
),

    );
  }

  // ✅ Mobile fallback
  Widget _mobileList(List<Patient> rows, Color primary) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final p = rows[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          title: InkWell(
            onTap: () => _openPatientProfile(p),
            child: Text(
              p.fullName,
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Age: ${p.age?.toString() ?? "-"} • Gender: ${p.gender.isEmpty ? "-" : p.gender}"),
                const SizedBox(height: 4),
                Text("Status: ${p.status.isEmpty ? "Active" : p.status}"),
                const SizedBox(height: 4),
                Text("Last Appointment: ${_fmtDate(p.lastAppointment)}"),
                const SizedBox(height: 4),
                Text("Last Diagnosis: ${p.lastDiagnosis.isEmpty ? "-" : p.lastDiagnosis}"),
              ],
            ),
          ),
        );
      },
    );
  }
}


// ------------------- Small UI widgets -------------------

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: "Enter patient name",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3F51B5);

    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _PageNumbers extends StatelessWidget {
  final int current;
  final int total;
  final ValueChanged<int> onSelect;

  const _PageNumbers({
    required this.current,
    required this.total,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final start = (current - 3).clamp(1, total);
    final end = (start + 6).clamp(1, total);

    return Row(
      children: [
        for (int p = start; p <= end; p++)
          InkWell(
            onTap: () => onSelect(p),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: p == current ? const Color(0xFFEEF2FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$p",
                style: TextStyle(
                  fontWeight: p == current ? FontWeight.w800 : FontWeight.w600,
                  color: p == current ? const Color(0xFF3F51B5) : Colors.black54,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusPillDropdown extends StatelessWidget {
  final String value; // "Active" / "Inactive"
  final ValueChanged<String> onChanged;

  const _StatusPillDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value.toLowerCase() == "active";

    final bg = isActive ? const Color(0xFFEAF7EE) : const Color(0xFFFDECEC);
    final border = isActive ? const Color(0xFF34A853) : const Color(0xFFE53935);
    final text = isActive ? const Color(0xFF1E7A3A) : const Color(0xFFB71C1C);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
      ),
      child: Center(
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: isActive ? "Active" : "Inactive",
            isDense: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: text),
            style: TextStyle(color: text, fontWeight: FontWeight.w700),
            items: const [
              DropdownMenuItem(value: "Active", child: Text("Active")),
              DropdownMenuItem(value: "Inactive", child: Text("Inactive")),
            ],
            onChanged: (v) {
              if (v == null) return;
              onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}
