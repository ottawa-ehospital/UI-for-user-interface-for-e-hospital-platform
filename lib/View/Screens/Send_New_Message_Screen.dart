import 'package:ehosptal_flutter_revamp/Service/API_service.dart';
import 'package:flutter/material.dart';

class SendNewMessageScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const SendNewMessageScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<SendNewMessageScreen> createState() => _SendNewMessageScreenState();
}

class _SendNewMessageScreenState extends State<SendNewMessageScreen> {
  final ApiService _api = ApiService();

  // No search field needed; list is scrollable.
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _selectedGroup = '';
  int? _selectedRecipientId;
  String _selectedRecipientLabel = '';

  bool _loadingRecipients = false;
  bool _sending = false;

  List<Map<String, dynamic>> _allRecipients = [];

  dynamic get _doctorId {
    return widget.doctor['id'] ??
        widget.doctor['doctorId'] ??
        widget.doctor['doctor_id'] ??
        widget.doctor['user_id'] ??
        widget.doctor['userId'];
  }
  dynamic get _doctorIdForRequest {
    final raw = _doctorId;
    if (raw is int) return raw;
    final parsed = int.tryParse(raw?.toString() ?? '');
    return parsed ?? raw;
  }
  String get _senderType => (widget.doctor['type'] ?? 'Doctor').toString();

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipients(String group) async {
    setState(() {
      _selectedGroup = group;
      _selectedRecipientId = null;
      _selectedRecipientLabel = '';
      _allRecipients = [];
      _loadingRecipients = true;
    });

    try {
      List<Map<String, dynamic>> items = [];

      if (group == 'Patient') {
        final patients = await _api.getDoctorPatientsAuthorized(
          doctorId: _doctorIdForRequest,
        );
        items = patients
            .map(
              (p) => {
                'id': _toInt(p.id),
                'label': p.fullName.trim().isEmpty ? 'Unnamed Patient' : p.fullName,
              },
            )
            .where((item) => item['id'] != null)
            .toList();
      } else if (group == 'ClinicStaff') {
        final staff = await _api.findClinicStaffsByDoctorId(
          doctorId: _doctorIdForRequest,
        );
        items = staff
            .map(
              (item) => {
                'id': _extractId(item),
                'label': _extractName(item),
              },
            )
            .where((item) => item['id'] != null)
            .cast<Map<String, dynamic>>()
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _allRecipients = items;
        _loadingRecipients = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRecipients = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load recipients: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _filteredRecipients() => _allRecipients;

  Future<void> _send() async {
    if (_selectedGroup.isEmpty ||
        _selectedRecipientId == null ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      final result = await _api.messageSend(
        payload: {
          "conversationId": 0,
          "senderType": _senderType,
          "sender_id": _doctorIdForRequest,
          "receiverType": _selectedGroup,
          "receiver_id": _selectedRecipientId,
          "viewer_permissions": {},
          "subject": _subjectController.text.trim().isEmpty
              ? "No Subject"
              : _subjectController.text.trim(),
          "content": _messageController.text.trim(),
        },
      );

      if (!mounted) return;
      setState(() => _sending = false);

      if (result == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully.')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF5F7FB);
    const primary = Color(0xFF3F51B5);
    const border = Color(0xFFE5E7EB);

    final recipients = _filteredRecipients();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primary),
        title: const Text(
          'New Message',
          style: TextStyle(color: Color(0xFF111827)),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compose Message',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: _selectedGroup.isEmpty ? null : _selectedGroup,
                      decoration: const InputDecoration(
                        labelText: 'Recipient Group',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Patient',
                          child: Text('Patient'),
                        ),
                        DropdownMenuItem(
                          value: 'ClinicStaff',
                          child: Text('Clinic Staff'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        _loadRecipients(value);
                      },
                    ),

                    const SizedBox(height: 16),

                    if (_loadingRecipients)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: LinearProgressIndicator(),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: _selectedRecipientId,
                        decoration: const InputDecoration(
                          labelText: 'Recipient',
                          border: OutlineInputBorder(),
                        ),
                        items: recipients
                            .map(
                              (item) {
                                final rawId = item['id'];
                                final id = rawId is int
                                    ? rawId
                                    : int.tryParse(rawId?.toString() ?? '');

                                return DropdownMenuItem<int>(
                                  value: id,
                                  child:
                                      Text((item['label'] ?? '').toString()),
                                );
                              },
                            )
                            .toList(),
                        onChanged: _selectedGroup.isEmpty
                            ? null
                            : (value) {
                                final picked = recipients.firstWhere(
                                  (e) => e['id'] == value,
                                  orElse: () => {'label': ''},
                                );
                                setState(() {
                                  _selectedRecipientId = value;
                                  _selectedRecipientLabel =
                                      (picked['label'] ?? '').toString();
                                });
                              },
                      ),

                    if (_selectedRecipientLabel.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Selected: $_selectedRecipientLabel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    TextField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _messageController,
                      minLines: 8,
                      maxLines: 14,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _sending ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _sending ? null : _send,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                          ),
                          icon: _sending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: const Text('Send'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int? _extractId(Map<String, dynamic> item) {
    final value =
        item['id'] ?? item['staff_id'] ?? item['doctor_id'] ?? item['patient_id'];
    return _toInt(value);
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  String _extractName(Map<String, dynamic> item) {
    final direct = item['name']?.toString().trim() ?? '';
    if (direct.isNotEmpty) return direct;

    final first = item['FName']?.toString().trim() ?? '';
    final last = item['LName']?.toString().trim() ?? '';
    final joined = '$first $last'.trim();

    return joined.isEmpty ? 'Unnamed Recipient' : joined;
  }
}