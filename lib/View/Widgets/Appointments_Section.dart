import 'package:ehosptal_flutter_revamp/Service/API_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentsSection extends StatefulWidget {
  const AppointmentsSection({
    super.key,
    required this.doctor,
  });

  final Map<String, dynamic> doctor;

  @override
  State<AppointmentsSection> createState() => _AppointmentsSectionState();
}

class _AppointmentsSectionState extends State<AppointmentsSection> {
  final ApiService _api = ApiService();

  final TextEditingController _search = TextEditingController();
  String _query = "";

  bool _loading = true;
  String? _error;

  // ✅ Nullable to prevent any “reading year of undefined” / late init issues
  DateTime? _selectedDay;

  // ✅ Range is always computed from _selectedDay (local boundaries)
  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd = DateTime.now();

  String selectedDateLabel = "Today";

  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();

    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });

    _selectedDay = DateTime.now();
    _recomputeRangeAndLabel();

    _fetchAppointments();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ---------- Date helpers (LOCAL day boundaries) ----------

  DateTime _startOfDayLocal(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _endOfDayLocal(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final fmt = DateFormat("MMM d, yyyy");
    if (_isSameDay(day, now)) return "Today • ${fmt.format(day)}";
    return "${DateFormat("EEE").format(day)} • ${fmt.format(day)}";
  }

  void _recomputeRangeAndLabel() {
    final day = _selectedDay ?? DateTime.now();

    // ✅ local midnight -> local 23:59:59.999
    _rangeStart = _startOfDayLocal(day);
    _rangeEnd = _endOfDayLocal(day);

    selectedDateLabel = _dayLabel(day);
  }

  Future<void> _shiftDay(int deltaDays) async {
    final base = _selectedDay ?? DateTime.now();
    final next = base.add(Duration(days: deltaDays));

    setState(() {
      _selectedDay = next;
      _recomputeRangeAndLabel();
    });

    await _fetchAppointments();
  }

  // ---------- API ----------

  Future<void> _fetchAppointments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final loginData = {
        "type": "Doctor",
        "id": widget.doctor["id"],
        "name": widget.doctor["Fname"] ?? widget.doctor["name"] ?? "Doctor",
        "email": widget.doctor["EmailId"] ?? widget.doctor["email"] ?? "",
        "startInPage": "/doctor/dashboard",
      };

      // ✅ IMPORTANT: backend expects UTC ISO with Z (like curl)
      final startUtcIso = _rangeStart.toUtc().toIso8601String();
      final endUtcIso = _rangeEnd.toUtc().toIso8601String();

      // Debug to confirm it matches curl shape (e.g. 05:00:00.000Z in Montreal winter)
      debugPrint("LOCAL start=$_rangeStart end=$_rangeEnd");
      debugPrint("UTC   start=$startUtcIso");
      debugPrint("UTC   end=$endUtcIso");

      final raw = await _api.getDoctorCalendar(
        loginData: loginData,
        // keep passing DateTime if your ApiService accepts DateTime
        // but ApiService MUST encode with toUtc().toIso8601String()
        start: _rangeStart,
        end: _rangeEnd,
      );

      final mapped = raw.map(_mapApiItemToUi).toList();

      setState(() {
        _appointments = mapped;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _mapApiItemToUi(Map<String, dynamic> a) {
    final start = DateTime.tryParse(a["start"]?.toString() ?? "");
    final end = DateTime.tryParse(a["end"]?.toString() ?? "");

    final time = (start != null && end != null)
        ? "${DateFormat("h:mm a").format(start.toLocal())} – ${DateFormat("h:mm a").format(end.toLocal())}"
        : "—";

    final patientName = (a["patientName"]?.toString().trim().isNotEmpty ?? false)
        ? a["patientName"].toString()
        : (a["patient"] is Map &&
                (a["patient"]["name"]?.toString().trim().isNotEmpty ?? false))
            ? a["patient"]["name"].toString()
            : "—";

    final reason = (a["description"]?.toString().trim().isNotEmpty ?? false)
        ? a["description"].toString()
        : "—";

    final statusLabel = _statusLabelFromInt(a["status"]);

    return {
      "id": a["id"] ?? a["appointmentId"] ?? a["Id"],
      "time": time,
      "patient": patientName,
      "reason": reason,
      "signed": false,
      "billed": false,
      "status": statusLabel,
    };
  }

  String _statusLabelFromInt(dynamic v) {
    final n = int.tryParse(v?.toString() ?? "") ?? 0;
    switch (n) {
      case 0:
        return "Pending";
      case 1:
        return "Confirmed";
      case 2:
        return "In Room";
      case 3:
        return "Done";
      case 4:
        return "No Show";
      default:
        return "Pending";
    }
  }

  List<Map<String, dynamic>> get filtered {
    final q = _query;
    if (q.isEmpty) return _appointments;

    return _appointments.where((a) {
      final patient = (a["patient"]?.toString() ?? "").toLowerCase();
      final reason = (a["reason"]?.toString() ?? "").toLowerCase();
      return patient.contains(q) || reason.contains(q);
    }).toList();
  }

  // ✅ Don’t mutate `filtered[i]` (it’s derived)
  void _updateStatusAtVisibleIndex(int visibleIndex, String newStatus) {
    final visible = filtered;
    if (visibleIndex < 0 || visibleIndex >= visible.length) return;

    final visibleItem = visible[visibleIndex];
    final id = visibleItem["id"];

    setState(() {
      if (id != null) {
        final realIndex = _appointments.indexWhere((x) => x["id"] == id);
        if (realIndex != -1) _appointments[realIndex]["status"] = newStatus;
      } else {
        final realIndex = _appointments.indexWhere((x) =>
            x["time"] == visibleItem["time"] &&
            x["patient"] == visibleItem["patient"] &&
            x["reason"] == visibleItem["reason"]);
        if (realIndex != -1) _appointments[realIndex]["status"] = newStatus;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    final dateSelectorWidth = width < 420 ? 230.0 : 320.0;

    final selected = _selectedDay ?? DateTime.now();
    final isToday = _isSameDay(selected, DateTime.now());

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Flexible(
                child: Text(
                  "Appointments",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              // const SizedBox(width: 10),
              SizedBox(
                width: dateSelectorWidth,
                child: _DateSelector(
                  label: selectedDateLabel,
                  isToday: isToday,
                  onPrev: () => _shiftDay(-1),
                  onNext: () => _shiftDay(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: "Search by patient name or reason for visit here",
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
              suffixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF5F6F8),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null)
                    ? _ErrorState(message: _error!, onRetry: _fetchAppointments)
                    : (filtered.isEmpty)
                        ? const Center(child: Text("No appointments"))
                        : isMobile
                            ? _MobileList(items: filtered)
                            : _Table(
                                items: filtered,
                                onStatusChanged: _updateStatusAtVisibleIndex,
                              ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text("View all appointments"),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _DateSelector({
    required this.label,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth;
        final labelW = (maxW - 142).clamp(70.0, 220.0);

        return Row(
          children: [
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //   decoration: BoxDecoration(
            //     color: const Color(0xFFE5E7EB),
            //     borderRadius: BorderRadius.circular(999),
            //   ),
            //   child: Text(
            //     isToday ? "Today" : "Day",
            //     style: const TextStyle(color: Colors.black54, fontSize: 12.5),
            //   ),
            // ),
       
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
            ),
        
            SizedBox(
              width: labelW,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
            
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        );
      },
    );
  }
}

class _Table extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(int index, String value) onStatusChanged;

  const _Table({required this.items, required this.onStatusChanged});

  Text _cell(String text, {bool link = false}) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: link ? FontWeight.w700 : FontWeight.w500,
        color: link ? const Color(0xFF1E4ED8) : Colors.black87,
        decoration: link ? TextDecoration.underline : TextDecoration.none,
      ),
    );
  }

  Text _header(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 980),
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 14,
            horizontalMargin: 12,
            headingRowHeight: 44,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 64,
            columns: [
              DataColumn(label: _header("Time")),
              DataColumn(label: _header("Patient Name")),
              DataColumn(label: _header("Reason for Visit")),
              DataColumn(label: _header("Signed")),
              DataColumn(label: _header("Billed")),
              DataColumn(label: _header("Status")),
              const DataColumn(label: Text("")),
            ],
            rows: List.generate(items.length, (i) {
              final a = items[i];
              return DataRow(
                cells: [
                  DataCell(_cell(a["time"]?.toString() ?? "—")),
                  DataCell(_cell(a["patient"]?.toString() ?? "—", link: true)),
                  DataCell(_cell(a["reason"]?.toString() ?? "—")),
                  DataCell(_BoolIcon(value: a["signed"] == true)),
                  DataCell(_BoolIcon(value: a["billed"] == true, dollar: true)),
                  DataCell(_StatusPill(
                    value: a["status"]?.toString() ?? "Pending",
                    onChanged: (v) => onStatusChanged(i, v),
                  )),
                  const DataCell(Icon(Icons.more_horiz, size: 18)),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _MobileList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _MobileList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final a = items[i];
        return ListTile(
          title: Text(
            a["patient"]?.toString() ?? "—",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a["time"]?.toString() ?? "—",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                ),
                const SizedBox(height: 4),
                Text(
                  a["reason"]?.toString() ?? "—",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                _StatusPill(value: a["status"]?.toString() ?? "Pending", onChanged: (_) {}),
              ],
            ),
          ),
          trailing: const Icon(Icons.more_horiz),
        );
      },
    );
  }
}

class _BoolIcon extends StatelessWidget {
  final bool value;
  final bool dollar;
  const _BoolIcon({required this.value, this.dollar = false});

  @override
  Widget build(BuildContext context) {
    if (dollar) {
      return Icon(
        Icons.attach_money,
        size: 20,
        color: value ? const Color(0xFF1E4ED8) : Colors.black26,
      );
    }
    return Icon(
      Icons.edit,
      size: 18,
      color: value ? const Color(0xFF1E4ED8) : Colors.black26,
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusPill({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: const TextStyle(fontSize: 12.5, color: Colors.black87),
          items: const [
            DropdownMenuItem(value: "Pending", child: Text("Pending")),
            DropdownMenuItem(value: "Confirmed", child: Text("Confirmed")),
            DropdownMenuItem(value: "In Room", child: Text("In Room")),
            DropdownMenuItem(value: "Done", child: Text("Done")),
            DropdownMenuItem(value: "No Show", child: Text("No Show")),
          ],
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ),
    );
  }
}
