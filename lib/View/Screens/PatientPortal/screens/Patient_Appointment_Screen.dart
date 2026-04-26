import 'dart:convert';

import 'package:ehosptal_flutter_revamp/Service/API_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/Patient_Book_Appointment_Screen.dart';

class PatientAppointmentScreen extends StatefulWidget {
  const PatientAppointmentScreen({
    super.key,
    required this.patientId,
    this.timezone = 'America/Toronto',
  });

  final dynamic patientId;
  final String timezone;

  @override
  State<PatientAppointmentScreen> createState() =>
      _PatientAppointmentScreenState();
}

class _PatientAppointmentScreenState extends State<PatientAppointmentScreen> {
  static const String _baseUrl =
      'https://tysnx3mi2s.us-east-1.awsapprunner.com';

  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _pageBg = Color(0xFFF5F7FB);
  static const Color _cardBg = Colors.white;
  static const Color _mutedText = Color(0xFF6B7280);

  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _deletingAppointmentId;
  AppointmentTab _selectedTab = AppointmentTab.past;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.patientId == null) {
        throw Exception('Patient id is missing');
      }

      final result = await _api.patientMainPageGetCalendar(
        loginData: {'id': widget.patientId},
        start: DateTime.utc(2000, 1, 1),
        end: DateTime.utc(2100, 1, 1),
        timezone: widget.timezone,
      );

      final appointmentsById = <String, Appointment>{};

      for (final item in result) {
        try {
          final appointment = Appointment.fromApiJson(item);
          appointmentsById[appointment.id] = appointment;
        } catch (_) {}
      }

      final appointments = appointmentsById.values.toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (!mounted) return;

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _appointments = [];
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _canDeleteAppointment(Appointment appointment) {
    return !appointment.isPast &&
        appointment.status != AppointmentStatus.canceled;
  }

  Future<void> _confirmDeleteAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Appointment'),
          content: Text(
            'Are you sure you want to delete the appointment with ${appointment.doctorName} on ${DateFormat('MMM dd, yyyy • hh:mm a').format(appointment.dateTime)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFDC2626)),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteAppointment(appointment);
    }
  }

  Future<void> _deleteAppointment(Appointment appointment) async {
    if (_deletingAppointmentId != null) return;

    setState(() {
      _deletingAppointmentId = appointment.id;
      _errorMessage = null;
    });

    try {
      final body = {
        'loginData': {'id': widget.patientId},
        'id': int.tryParse(appointment.id) ?? appointment.id,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/api/appointments/cancelAppointmentRequest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('cancelAppointmentRequest status: ${response.statusCode}');
      print('cancelAppointmentRequest body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete appointment');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        throw Exception(
          data['message']?.toString() ?? 'Backend returned ${data['status']}',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment deleted successfully.')),
      );

      await _loadAppointments();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete appointment: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _deletingAppointmentId = null;
      });
    }
  }

  List<Appointment> _getAppointmentsForSelectedTab() {
    final query = _searchController.text.trim().toLowerCase();

    bool matchesSearch(Appointment appointment) {
      if (query.isEmpty) return true;

      final haystack = [
        appointment.doctorName,
        appointment.specialty,
        appointment.location,
        appointment.status.label,
        appointment.details,
        appointment.address,
        appointment.contactNumber,
        appointment.cancellationReason ?? '',
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }

    bool matchesTab(Appointment appointment) {
      switch (_selectedTab) {
        case AppointmentTab.calendar:
          return true;
        case AppointmentTab.upcoming:
          return appointment.isUpcoming;
        case AppointmentTab.past:
          return appointment.isPast;
        case AppointmentTab.canceled:
          return appointment.status == AppointmentStatus.canceled;
      }
    }

    final filtered = _appointments
        .where(
          (appointment) =>
              matchesTab(appointment) && matchesSearch(appointment),
        )
        .toList();

    filtered.sort((a, b) {
      if (_selectedTab == AppointmentTab.past) {
        return b.dateTime.compareTo(a.dateTime);
      }
      return a.dateTime.compareTo(b.dateTime);
    });

    return filtered;
  }

  List<Appointment> _getAppointmentsForDay(DateTime day) {
    final query = _searchController.text.trim().toLowerCase();

    bool matchesSearch(Appointment appointment) {
      if (query.isEmpty) return true;

      final haystack = [
        appointment.doctorName,
        appointment.specialty,
        appointment.location,
        appointment.status.label,
        appointment.details,
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }

    final filtered = _appointments.where((appointment) {
      return isSameDay(appointment.dateTime, day) && matchesSearch(appointment);
    }).toList();

    filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return filtered;
  }

  List<Appointment> _getAppointmentsForCalendarMarker(DateTime day) {
    final matches = _appointments.where((appointment) {
      return isSameDay(appointment.dateTime, day);
    });

    return matches.isEmpty ? [] : [matches.first];
  }

  AppointmentCardMode _cardModeFor(Appointment appointment) {
    if (appointment.status == AppointmentStatus.canceled) {
      return AppointmentCardMode.canceled;
    }
    if (appointment.isPast) {
      return AppointmentCardMode.past;
    }
    return AppointmentCardMode.upcoming;
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label coming soon')));
  }

  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder: (_) => AppointmentDetailsDialog(appointment: appointment),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          return _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFDA4AF),
                              ),
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
                                    'Could not load appointments. $_errorMessage',
                                    style: const TextStyle(
                                      color: Color(0xFF9F1239),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _loadAppointments,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        isMobile
                            ? _buildMobileToolbar()
                            : _buildDesktopToolbar(),
                        const SizedBox(height: 20),
                        _selectedTab == AppointmentTab.calendar
                            ? _buildCalendarSection(isMobile: isMobile)
                            : _buildListSection(
                                _getAppointmentsForSelectedTab(),
                              ),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Appointments',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Review upcoming visits, check history, or manage changes to your appointments.',
          style: TextStyle(
            fontSize: 15,
            color: _mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopToolbar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildTabBar(),
        const SizedBox(width: 16),
        SizedBox(width: 320, child: _buildSearchField()),
        const Spacer(),
        _buildBookButton(),
      ],
    );
  }

  Widget _buildMobileToolbar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabBar(),
        const SizedBox(height: 12),
        _buildSearchField(),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: _buildBookButton()),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = AppointmentTab.values;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: tabs.map((tab) {
          final selected = _selectedTab == tab;
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() => _selectedTab = tab);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? _primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tab == AppointmentTab.calendar) ...[
                    Icon(
                      Icons.calendar_month,
                      size: 18,
                      color: selected ? Colors.white : const Color(0xFF374151),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    tab.label,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search by doctor, type, details or status ...',
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.search, color: _mutedText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primary),
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  PatientBookAppointmentScreen(patientId: widget.patientId),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Book an Appointment',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCalendarSection({required bool isMobile}) {
    final appointmentsForDay = _getAppointmentsForDay(_selectedDay);

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: isMobile
          ? Column(
              children: [
                _buildCalendarWidget(),
                const SizedBox(height: 20),
                _buildSelectedDayList(appointmentsForDay),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 360, child: _buildCalendarWidget()),
                const SizedBox(width: 20),
                Expanded(child: _buildSelectedDayList(appointmentsForDay)),
              ],
            ),
    );
  }

  Widget _buildCalendarWidget() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      eventLoader: _getAppointmentsForCalendarMarker,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: _primary),
        rightChevronIcon: Icon(Icons.chevron_right, color: _primary),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: _primary.withOpacity(0.25),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: _primary,
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: _primary,
          shape: BoxShape.circle,
        ),
        outsideTextStyle: TextStyle(color: Colors.grey.shade400),
        weekendTextStyle: const TextStyle(color: Colors.black87),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
        ),
        weekendStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
        ),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
    );
  }

  Widget _buildSelectedDayList(List<Appointment> appointmentsForDay) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointments for ${DateFormat('MMM dd, yyyy').format(_selectedDay)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),
        if (appointmentsForDay.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(Icons.event_busy, size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No appointments on this date',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appointmentsForDay.length,
            itemBuilder: (context, index) {
              final appointment = appointmentsForDay[index];

              return AppointmentCard(
                appointment: appointment,
                mode: _cardModeFor(appointment),
                isDeleting: _deletingAppointmentId == appointment.id,
                onViewDetails: () => _showAppointmentDetails(appointment),
                onDelete: _canDeleteAppointment(appointment)
                    ? () => _confirmDeleteAppointment(appointment)
                    : null,
                onEdit: () => _showComingSoon('Edit'),
                onMessage: () => _showComingSoon('Message'),
                onVideoCall: () => _showComingSoon('Start Video Call'),
                onRebook: () => _showComingSoon('Rebook'),
              );
            },
          ),
      ],
    );
  }

  Widget _buildListSection(List<Appointment> appointments) {
    if (appointments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.event_note, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No appointments found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];

          return AppointmentCard(
            appointment: appointment,
            mode: _cardModeFor(appointment),
            isDeleting: _deletingAppointmentId == appointment.id,
            onViewDetails: () => _showAppointmentDetails(appointment),
            onDelete: _canDeleteAppointment(appointment)
                ? () => _confirmDeleteAppointment(appointment)
                : null,
            onEdit: () => _showComingSoon('Edit'),
            onMessage: () => _showComingSoon('Message'),
            onVideoCall: () => _showComingSoon('Start Video Call'),
            onRebook: () => _showComingSoon('Rebook'),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final AppointmentCardMode mode;
  final bool isDeleting;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onMessage;
  final VoidCallback onVideoCall;
  final VoidCallback onRebook;
  final VoidCallback? onDelete;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.mode,
    required this.isDeleting,
    required this.onViewDetails,
    required this.onEdit,
    required this.onMessage,
    required this.onVideoCall,
    required this.onRebook,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(appointment.dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 700;

          return stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfo(formattedDate),
                    const SizedBox(height: 12),
                    _buildActions(context),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildInfo(formattedDate)),
                    const SizedBox(width: 16),
                    _buildActions(context),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildInfo(String formattedDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appointment.doctorName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          appointment.specialty,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            SizedBox(
              width: 220,
              child: _iconText(Icons.calendar_month, formattedDate),
            ),
            SizedBox(
              width: 200,
              child: _iconText(
                Icons.location_on_outlined,
                appointment.location,
              ),
            ),
            SizedBox(
              width: 180,
              child: AppointmentStatusChip(status: appointment.status),
            ),
          ],
        ),
        if (appointment.details.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            appointment.details,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
        if (mode == AppointmentCardMode.canceled &&
            appointment.cancellationReason != null) ...[
          const SizedBox(height: 10),
          Text(
            'Reason: ${appointment.cancellationReason!}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    switch (mode) {
      case AppointmentCardMode.upcoming:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (onDelete != null)
              isDeleting
                  ? const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _textButton(
                      'Delete',
                      onDelete!,
                      color: const Color(0xFFDC2626),
                    ),
            _textButton('Edit', onEdit),
            _textButton('Message', onMessage),
            _textButton('Start Video Call', onVideoCall),
            _textButton(
              'View Details',
              onViewDetails,
              color: const Color(0xFF1A4EBA),
            ),
          ],
        );
      case AppointmentCardMode.past:
        return _textButton(
          'View Appointment Summary',
          onViewDetails,
          color: const Color(0xFF1A4EBA),
        );
      case AppointmentCardMode.canceled:
        return _textButton('Rebook', onRebook, color: const Color(0xFF1A4EBA));
    }
  }

  Widget _textButton(String label, VoidCallback onTap, {Color? color}) {
    return TextButton(
      onPressed: isDeleting ? null : onTap,
      child: Text(
        label,
        style: TextStyle(
          color: color ?? const Color(0xFF374151),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }
}

class AppointmentStatusChip extends StatelessWidget {
  final AppointmentStatus status;

  const AppointmentStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info_outline, size: 18, color: status.color),
        const SizedBox(width: 6),
        Text(
          status.label,
          style: TextStyle(
            color: status.color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class AppointmentDetailsDialog extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailsDialog({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final formattedStart = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(appointment.dateTime);
    final formattedEnd = DateFormat('hh:mm a').format(appointment.endDateTime);

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 24,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Appointment Details',
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
                const SizedBox(height: 12),
                _detailItem(
                  icon: Icons.calendar_month,
                  title: '$formattedStart - $formattedEnd',
                  subtitle: '${appointment.durationMinutes} minutes',
                ),
                _detailItem(
                  icon: Icons.person_outline,
                  title: appointment.doctorName,
                  subtitle: appointment.specialty,
                ),
                _detailItem(
                  icon: Icons.location_on_outlined,
                  title: appointment.location,
                  subtitle: appointment.address,
                ),
                _detailItem(
                  icon: Icons.description_outlined,
                  title: 'Appointment Notes',
                  subtitle: appointment.details,
                ),
                _detailItem(
                  icon: Icons.local_phone_outlined,
                  title: 'Contact',
                  subtitle: appointment.contactNumber,
                ),
                _detailItem(
                  icon: Icons.info_outline,
                  title: 'Status',
                  subtitle: appointment.status.label,
                ),
                if (appointment.cancellationReason != null)
                  _detailItem(
                    icon: Icons.warning_amber_outlined,
                    title: 'Cancellation Reason',
                    subtitle: appointment.cancellationReason!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF1F2937)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Appointment {
  final String id;
  final String doctorName;
  final String specialty;
  final DateTime dateTime;
  final DateTime endDateTime;
  final int durationMinutes;
  final String location;
  final String address;
  final String details;
  final String contactNumber;
  final AppointmentStatus status;
  final String? cancellationReason;
  final int rawStatus;
  final int? rawCategory;
  final int? rawType;

  const Appointment({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.dateTime,
    required this.endDateTime,
    required this.durationMinutes,
    required this.location,
    required this.address,
    required this.details,
    required this.contactNumber,
    required this.status,
    required this.rawStatus,
    this.rawCategory,
    this.rawType,
    this.cancellationReason,
  });

  bool get isPast => endDateTime.isBefore(DateTime.now());

  bool get isUpcoming => !isPast && status != AppointmentStatus.canceled;

  factory Appointment.fromApiJson(Map<String, dynamic> json) {
    final id = json['id'];
    final startRaw = json['start']?.toString();
    final endRaw = json['end']?.toString();

    if (id == null || startRaw == null || endRaw == null) {
      throw const FormatException('Appointment missing required fields');
    }

    final start = DateTime.parse(startRaw).toLocal();
    final end = DateTime.parse(endRaw).toLocal();

    final rawStatus = (json['status'] as num?)?.toInt() ?? 0;
    final rawCategory = (json['category'] as num?)?.toInt();
    final rawType = (json['type'] as num?)?.toInt();

    String doctorName = '';

    final doctor = json['doctor'];
    if (doctor is Map && doctor['name'] != null) {
      doctorName = doctor['name'].toString().trim();
    }

    if (doctorName.isEmpty) {
      final firstName = (json['Fname']?.toString() ?? '').trim();
      final lastName = (json['Lname']?.toString() ?? '').trim();
      doctorName = '$firstName $lastName'.trim();
    }

    if (doctorName.isEmpty) {
      doctorName = 'Unknown Doctor';
    }

    final description = (json['description']?.toString() ?? '').trim();

    return Appointment(
      id: id.toString(),
      doctorName: doctorName,
      specialty: _categoryLabel(rawCategory),
      dateTime: start,
      endDateTime: end,
      durationMinutes: end.difference(start).inMinutes.abs(),
      location: 'Clinic not specified',
      address: 'Address not provided',
      details: description.isEmpty ? 'No additional details.' : description,
      contactNumber: 'Not provided',
      status: _mapStatus(rawStatus, end),
      rawStatus: rawStatus,
      rawCategory: rawCategory,
      rawType: rawType,
      cancellationReason: null,
    );
  }

  static AppointmentStatus _mapStatus(int rawStatus, DateTime end) {
    final now = DateTime.now();

    if (end.isBefore(now)) {
      return AppointmentStatus.completed;
    }

    switch (rawStatus) {
      case 1:
        return AppointmentStatus.approved;
      case 0:
        return AppointmentStatus.pending;
      case -1:
        return AppointmentStatus.approved;
      case -2:
        return AppointmentStatus.canceled;
      default:
        return AppointmentStatus.pending;
    }
  }

  static String _categoryLabel(int? category) {
    switch (category) {
      case 2:
        return 'General Consultation';
      case 4:
        return 'Follow-up Visit';
      case 5:
        return 'Specialist Appointment';
      default:
        return 'Medical Appointment';
    }
  }
}

enum AppointmentStatus {
  approved,
  pending,
  completed,
  noShow,
  canceled;

  String get label {
    switch (this) {
      case AppointmentStatus.approved:
        return 'Appointment Approved';
      case AppointmentStatus.pending:
        return 'Appointment Pending';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.noShow:
        return 'No Show';
      case AppointmentStatus.canceled:
        return 'Canceled';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.approved:
        return const Color(0xFF10B981);
      case AppointmentStatus.pending:
        return const Color(0xFFF59E0B);
      case AppointmentStatus.completed:
        return const Color(0xFF10B981);
      case AppointmentStatus.noShow:
        return const Color(0xFFFBBF24);
      case AppointmentStatus.canceled:
        return const Color(0xFFEF4444);
    }
  }
}

enum AppointmentTab {
  calendar,
  upcoming,
  past,
  canceled;

  String get label {
    switch (this) {
      case AppointmentTab.calendar:
        return 'Calendar';
      case AppointmentTab.upcoming:
        return 'Upcoming';
      case AppointmentTab.past:
        return 'Past';
      case AppointmentTab.canceled:
        return 'Canceled';
    }
  }
}

enum AppointmentCardMode { upcoming, past, canceled }
