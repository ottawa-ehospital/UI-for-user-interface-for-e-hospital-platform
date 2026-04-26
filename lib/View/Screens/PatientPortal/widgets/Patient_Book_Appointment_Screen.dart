import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PatientBookAppointmentScreen extends StatefulWidget {
  const PatientBookAppointmentScreen({super.key, required this.patientId});

  final dynamic patientId;

  @override
  State<PatientBookAppointmentScreen> createState() =>
      _PatientBookAppointmentScreenState();
}

class _PatientBookAppointmentScreenState
    extends State<PatientBookAppointmentScreen> {
  static const String _baseUrl =
      'https://tysnx3mi2s.us-east-1.awsapprunner.com';

  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _pageBg = Color(0xFFF5F7FB);
  static const Color _cardBg = Colors.white;
  static const Color _mutedText = Color(0xFF6B7280);
  static const Color _panelBg = Color(0xFFF2F2F2);
  static const Color _slotBg = Color(0xFFF0F7FC);

  final List<String> _specialties = const [
    'Cardiology',
    'Dermatology',
    'Neurology',
  ];

  final List<String> _appointmentTypes = const [
    'Surgery',
    'General Consultation',
    'Lab Testing',
  ];

  bool _isLoadingDoctors = false;
  bool _isLoadingSlots = false;
  bool _isSubmittingBooking = false;
  String? _errorMessage;

  String? _selectedSpecialty;
  String? _selectedAppointmentType;
  DoctorOption? _selectedDoctor;

  List<DoctorOption> _doctors = [];
  List<AppointmentSlot> _allSlots = [];

  int _dateOffset = 0;
  int _selectedDateIndex = 0;
  String? _selectedSlotId;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _loadSlots();
  }

  DateTime get _baseDate => DateTime(2026, 5, 1);

  List<DateTime> get _visibleDates =>
      List.generate(7, (i) => _baseDate.add(Duration(days: _dateOffset + i)));

  DateTime get _selectedDate => _visibleDates[_selectedDateIndex];

  bool get _isFormComplete =>
      _selectedSpecialty != null &&
      _selectedAppointmentType != null &&
      _selectedDoctor != null &&
      _selectedSlotId != null;

  String get _dateRangeLabel {
    final start = _visibleDates.first;
    final end = _visibleDates.last;
    return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoadingDoctors = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/appointments/getDoctors'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load doctors');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = (data['result'] as List? ?? [])
          .map((e) => DoctorOption.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _doctors = result;
        _isLoadingDoctors = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDoctors = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _errorMessage = null;
    });

    try {
      final start = DateTime.utc(2026, 5, 1);
      final end = DateTime.utc(2026, 5, 31, 23, 59, 59);

      final response = await http.post(
        Uri.parse('$_baseUrl/api/appointments/patientGetCalendar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'loginData': {'id': widget.patientId},
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        }),
      );

      print('patientGetCalendar body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to load slots');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        throw Exception('Backend returned ${data['status']}');
      }

      final result =
          (data['result'] as List? ?? [])
              .map((e) => AppointmentSlot.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.start.compareTo(b.start));

      if (!mounted) return;
      setState(() {
        _allSlots = result;
        _isLoadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSlots = false;
        _errorMessage = e.toString();
      });
    }
  }

  int _bookingCategoryForSlot(AppointmentSlot slot) {
    if (slot.category == null) {
      throw Exception('Selected slot has no category');
    }
    return slot.category!;
  }

  Future<void> _bookAppointment(AppointmentSlot slot) async {
    if (_isSubmittingBooking) return;

    setState(() {
      _isSubmittingBooking = true;
      _errorMessage = null;
    });

    try {
      final category = _bookingCategoryForSlot(slot);

      final body = {
        'loginData': {'id': widget.patientId},
        'id': int.tryParse(slot.id) ?? slot.id,
        'category': category,
        'description': '',
      };

      print('patientBookTime request body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/appointments/patientBookTime'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('patientBookTime status: ${response.statusCode}');
      print('patientBookTime body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to submit booking request');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        throw Exception(
          data['message']?.toString() ?? 'Backend returned ${data['status']}',
        );
      }

      if (!mounted) return;

      setState(() {
        _selectedSlotId = null;
      });

      await _loadSlots();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request submitted successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit booking request: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmittingBooking = false;
      });
    }
  }

  void _handleDoubleLeft() {
    setState(() {
      _dateOffset -= 7;
      _selectedDateIndex = 0;
      _selectedSlotId = null;
    });
  }

  void _handleSingleLeft() {
    setState(() {
      _dateOffset -= 1;
      _selectedDateIndex = 0;
      _selectedSlotId = null;
    });
  }

  void _handleSingleRight() {
    setState(() {
      _dateOffset += 1;
      _selectedDateIndex = 0;
      _selectedSlotId = null;
    });
  }

  void _handleDoubleRight() {
    setState(() {
      _dateOffset += 7;
      _selectedDateIndex = 0;
      _selectedSlotId = null;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<AppointmentSlot> _filteredSlots() {
    if (_selectedDoctor == null) return [];

    final filtered = _allSlots.where((slot) {
      return slot.doctorId == _selectedDoctor!.id &&
          _isSameDay(slot.start.toLocal(), _selectedDate) &&
          slot.isAvailable;
    }).toList()..sort((a, b) => a.start.compareTo(b.start));

    return filtered;
  }

  void _showSummary() {
    if (!_isFormComplete) return;
    final slot = _allSlots.firstWhere((e) => e.id == _selectedSlotId);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Appointment Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _summaryRow('Specialty', _selectedSpecialty!),
                    _summaryRow('Appointment Type', _selectedAppointmentType!),
                    _summaryRow('Doctor', _selectedDoctor!.name),
                    _summaryRow(
                      'Date',
                      DateFormat(
                        'EEE, MMM dd, yyyy',
                      ).format(slot.start.toLocal()),
                    ),
                    _summaryRow(
                      'Time',
                      '${DateFormat('hh:mm a').format(slot.start.toLocal())} - ${DateFormat('hh:mm a').format(slot.end.toLocal())}',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmittingBooking
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _bookAppointment(slot);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmittingBooking
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Confirm Booking',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: _mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slots = _filteredSlots();

    return Scaffold(
      backgroundColor: _pageBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Book New Appointment',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Schedule your appointment with one of our healthcare professionals',
                    style: TextStyle(
                      fontSize: 15,
                      color: _mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDA4AF)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFBE123C),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFF9F1239),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _loadDoctors();
                              _loadSlots();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Container(
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        isMobile
                            ? Column(
                                children: [
                                  _buildSpecialtyField(),
                                  const SizedBox(height: 16),
                                  _buildAppointmentTypeField(),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: _buildSpecialtyField()),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildAppointmentTypeField()),
                                ],
                              ),
                        const SizedBox(height: 24),
                        isMobile
                            ? Column(
                                children: [
                                  _buildDoctorSection(),
                                  const SizedBox(height: 20),
                                  _buildSlotSection(slots, isMobile),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildDoctorSection()),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _buildSlotSection(slots, isMobile),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 24),
                        isMobile
                            ? Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed: _isSubmittingBooking
                                          ? null
                                          : () => Navigator.of(
                                              context,
                                            ).maybePop(),
                                      child: const Text('< Back'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isFormComplete &&
                                              !_isSubmittingBooking
                                          ? _showSummary
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primary,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                            Colors.grey.shade300,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'View Summary',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  TextButton(
                                    onPressed: _isSubmittingBooking
                                        ? null
                                        : () =>
                                              Navigator.of(context).maybePop(),
                                    child: const Text('< Back'),
                                  ),
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed:
                                        _isFormComplete && !_isSubmittingBooking
                                        ? _showSummary
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primary,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          Colors.grey.shade300,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'View Summary',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecialtyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a Specialty',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSpecialty,
          decoration: InputDecoration(
            hintText: 'Search or select a specialty',
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.search, color: _mutedText),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _primary),
            ),
          ),
          items: _specialties
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedSpecialty = value;
              _selectedAppointmentType = null;
              _selectedDoctor = null;
              _selectedSlotId = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAppointmentTypeField() {
    final enabled = _selectedSpecialty != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Appointment Type',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedAppointmentType,
          decoration: InputDecoration(
            hintText: 'Select appointment type',
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _primary),
            ),
          ),
          items: _appointmentTypes
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: enabled
              ? (value) {
                  setState(() {
                    _selectedAppointmentType = value;
                    _selectedDoctor = null;
                    _selectedSlotId = null;
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDoctorSection() {
    final enabled =
        _selectedSpecialty != null && _selectedAppointmentType != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select a Doctor',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 500,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _panelBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: !enabled
              ? const Center(
                  child: Text(
                    'Choose a specialty and appointment type first.',
                    style: TextStyle(color: _mutedText),
                    textAlign: TextAlign.center,
                  ),
                )
              : _isLoadingDoctors
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _doctors[index];
                    final selected = _selectedDoctor?.id == doctor.id;

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _selectedDoctor = doctor;
                          _selectedSlotId = null;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected ? _primary : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: selected
                                  ? Colors.white24
                                  : const Color(0xFFE5E7EB),
                              child: Icon(
                                Icons.person,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedSpecialty ?? '',
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white70
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 180,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: selected
                                            ? Colors.white70
                                            : const Color(0xFF6B7280),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Clinic not specified',
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white70
                                                : const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_outlined,
                                        size: 16,
                                        color: selected
                                            ? Colors.white70
                                            : const Color(0xFF6B7280),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Mon–Fri, 9AM–4PM',
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white70
                                                : const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSlotSection(List<AppointmentSlot> slots, bool isMobile) {
    final enabled = _selectedDoctor != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Time Slots with The Doctor',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 500,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : _panelBg,
            borderRadius: BorderRadius.circular(12),
            border: enabled
                ? Border.all(color: const Color(0xFFE5E7EB), width: 2)
                : null,
          ),
          child: !enabled
              ? const Center(
                  child: Text(
                    'Please select a doctor to see available time slots.',
                    style: TextStyle(color: _mutedText),
                    textAlign: TextAlign.center,
                  ),
                )
              : _isLoadingSlots
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Icon(Icons.today, color: _primary, size: 24),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dateRangeLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDateNavigator(isMobile),
                    const SizedBox(height: 20),
                    Expanded(
                      child: slots.isEmpty
                          ? const Center(
                              child: Text(
                                'No available slots for this doctor on this date.',
                                style: TextStyle(color: _mutedText),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : GridView.builder(
                              itemCount: slots.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isMobile ? 1 : 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: isMobile ? 4.8 : 3.3,
                                  ),
                              itemBuilder: (context, index) {
                                final slot = slots[index];
                                final selected = _selectedSlotId == slot.id;

                                return OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedSlotId = slot.id;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: selected
                                        ? _primary
                                        : _slotBg,
                                    foregroundColor: selected
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                                    side: BorderSide(
                                      color: selected
                                          ? _primary
                                          : const Color(0xFFB6D8F5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    '${DateFormat('hh:mm a').format(slot.start.toLocal())} - ${DateFormat('hh:mm a').format(slot.end.toLocal())}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildDateNavigator(bool isMobile) {
    final dates = _visibleDates;

    return Row(
      children: [
        IconButton(
          onPressed: _handleDoubleLeft,
          icon: const Icon(Icons.keyboard_double_arrow_left, color: _primary),
        ),
        IconButton(
          onPressed: _handleSingleLeft,
          icon: const Icon(Icons.chevron_left, color: _primary),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(dates.length, (index) {
                final date = dates[index];
                final selected = _selectedDateIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _selectedDateIndex = index;
                        _selectedSlotId = null;
                      });
                    },
                    child: Container(
                      width: isMobile ? 68 : 72,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? _primary : _slotBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('M/d').format(date),
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEE').format(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? Colors.white70
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        IconButton(
          onPressed: _handleSingleRight,
          icon: const Icon(Icons.chevron_right, color: _primary),
        ),
        IconButton(
          onPressed: _handleDoubleRight,
          icon: const Icon(Icons.keyboard_double_arrow_right, color: _primary),
        ),
      ],
    );
  }
}

class DoctorOption {
  final String id;
  final String name;

  const DoctorOption({required this.id, required this.name});

  factory DoctorOption.fromJson(Map<String, dynamic> json) {
    return DoctorOption(
      id: json['id'].toString(),
      name: (json['name']?.toString() ?? 'Unknown Doctor')
          .replaceAll('null', '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
    );
  }
}

class AppointmentSlot {
  final String id;
  final String doctorId;
  final String doctorName;
  final DateTime start;
  final DateTime end;
  final int status;
  final int? category;
  final String description;
  final dynamic patient;

  const AppointmentSlot({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.start,
    required this.end,
    required this.status,
    required this.description,
    required this.patient,
    this.category,
  });

  bool get isAvailable => status == 0 && patient == null;

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'] as Map<String, dynamic>?;

    return AppointmentSlot(
      id: json['id'].toString(),
      doctorId: doctor?['id']?.toString() ?? '',
      doctorName: (doctor?['name']?.toString() ?? 'Unknown Doctor')
          .replaceAll('null', '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
      start: DateTime.parse(json['start'].toString()),
      end: DateTime.parse(json['end'].toString()),
      status: (json['status'] as num?)?.toInt() ?? 0,
      category: (json['category'] as num?)?.toInt(),
      description: json['description']?.toString() ?? '',
      patient: json['patient'],
    );
  }
}
