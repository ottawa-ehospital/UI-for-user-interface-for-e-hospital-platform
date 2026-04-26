import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ehosptal_flutter_revamp/model/patient.dart';

class PatientProfileScreen extends StatefulWidget {
  final Patient patient;
  const PatientProfileScreen({super.key, required this.patient});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  static const String baseUrl = 'https://tysnx3mi2s.us-east-1.awsapprunner.com';

  bool _isLoading = true;
  Map<String, dynamic>? _patientDetails;
  Map<String, dynamic>? _medicalHistory;
  List<dynamic> _visits = [];
  List<dynamic> _prescriptions = [];
  List<dynamic> _referrals = [];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _fetchPatientPortalInfo(),
        _fetchMedicalHistory(),
        _fetchPatientVisits(),
        _fetchPrescriptions(),
        _fetchReferrals(),
        _fetchMedicalTests(),
      ]);
    } catch (e) {
      debugPrint('Error loading patient data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPatientPortalInfo() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/getPatientPortalInfoById'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'patientId': widget.patient.id}),
      );
      if (response.statusCode == 200) {
        setState(() => _patientDetails = json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching patient portal info: $e');
    }
  }

  Future<void> _fetchMedicalHistory() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/patientMedicalHistory'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'patientId': widget.patient.id}),
      );
      if (response.statusCode == 200) {
        setState(() => _medicalHistory = json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching medical history: $e');
    }
  }

  Future<void> _fetchPatientVisits() async {
    try {
      final requestBody = {
        'doctorId': 58,
        'patientId': widget.patient.id.toString(), // Convert to string
      };

      final response = await http.post(
        Uri.parse('$baseUrl/patientVisits'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          _visits = data is List ? data : [];
        });
        
        debugPrint('Total visits loaded: ${_visits.length}');
      } else {
        debugPrint('Failed to fetch visits: ${response.statusCode}');
        debugPrint('Error response: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching visits: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _fetchPrescriptions() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getPrescriptionsByPatientId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'patientId': widget.patient.id}),
      );
      if (response.statusCode == 200) {
        setState(() => _prescriptions = json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching prescriptions: $e');
    }
  }

  Future<void> _fetchReferrals() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getReferralByPatientID'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'patientId': widget.patient.id}),
      );
      if (response.statusCode == 200) {
        setState(() => _referrals = json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching referrals: $e');
    }
  }

  Map<String, dynamic> _medicalTests = {};

  Future<void> _fetchMedicalTests() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getMedicalTest'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'patientId': '${widget.patient.id}'}),
      );
      
      debugPrint('Medical Tests Response: ${response.statusCode}');
      debugPrint('Medical Tests Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _medicalTests = data is Map<String, dynamic> ? data : {};
        });
        debugPrint('Medical tests loaded: ${_medicalTests.keys.length} items');
      }
    } catch (e) {
      debugPrint('Error fetching medical tests: $e');
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = date is DateTime ? date : DateTime.parse(date.toString());
      return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2C5BFF);
    const backgroundColor = Color(0xFFF5F7FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Patient Profile'),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
          IconButton(icon: const Icon(Icons.print), onPressed: () {}),
          IconButton(icon: const Icon(Icons.video_call), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildPatientHeader(),
                  _buildMedicalHistorySummary(),
                  _buildEncountersSection(),
                  _buildRecordHub(),
                ],
              ),
            ),
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.patient.fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C5BFF),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF2C5BFF)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.description, color: Color(0xFF2C5BFF)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.video_call, color: Color(0xFF2C5BFF)),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Birthdate',
                  _formatDate(
                    _patientDetails?['date_of_birth'] ??
                        widget.patient.lastAppointment,
                  ),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Address',
                  _patientDetails?['Address'] ?? 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Age', '${widget.patient.age ?? "-"} yr'),
              ),
              Expanded(
                child: _buildInfoItem('Email', _patientDetails?['EmailId'] ?? '-'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Sex / Gender',
                  '${widget.patient.gender.isNotEmpty ? widget.patient.gender : "F"} / M',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Tel',
                  _patientDetails?['tel'] ?? widget.patient.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Height',
                  _patientDetails?['height'] ?? '186 cm / 80 kg',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Weight',
                  _patientDetails?['weight'] ?? 'N/A',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMedicalHistorySummary() {
    // Extract pathology data from patient details
    final pathologyData = _patientDetails?['pathology'] as Map<String, dynamic>?;
    
    // Create a list of medical history items
    List<Map<String, String>> historyItems = [];
    
    if (pathologyData != null) {
      // Map API keys to user-friendly titles
      final keyMapping = {
        'pathology': 'Past Medical History',
        'surgeries': 'Surgical History',
        'pregnancies': 'Pregnancy',
        'prior_medication': 'Prior Medications',
      };
      
      pathologyData.forEach((key, value) {
        String title = keyMapping[key] ?? _formatPathologyKey(key);
        String content = _formatPathologyValue(key, value);
        historyItems.add({'title': title, 'content': content});
      });
    }
    
    // Add additional fields from medical history if available
    if (_medicalHistory != null) {
      if (_medicalHistory!['allergies'] != null) {
        historyItems.insert(0, {
          'title': 'Allergies',
          'content': _medicalHistory!['allergies'].toString(),
        });
      }
      if (_medicalHistory!['familyHistory'] != null) {
        historyItems.add({
          'title': 'Family History',
          'content': _medicalHistory!['familyHistory'].toString(),
        });
      }
    }
    
    // If no data, show placeholder cards
    if (historyItems.isEmpty) {
      historyItems = [
        {'title': 'Allergies', 'content': 'No allergies recorded'},
        {'title': 'Past Medical History', 'content': 'No history'},
        {'title': 'Surgical History', 'content': 'No surgeries'},
        {'title': 'Prior Medications', 'content': 'None'},
      ];
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medical History Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C5BFF),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: historyItems.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(
                historyItems[index]['title']!,
                historyItems[index]['content']!,
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper method to format pathology keys
  String _formatPathologyKey(String key) {
    String formatted = key.replaceAll('_', ' ');
    return formatted.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Helper method to format pathology values based on key
  String _formatPathologyValue(String key, dynamic value) {
    if (value == null) return 'N/A';
    
    // Handle different value types
    if (value is int) {
      if (key == 'pregnancies') {
        return value == 0 ? 'No pregnancies' : '$value ${value == 1 ? "pregnancy" : "pregnancies"}';
      }
      return value.toString();
    }
    
    if (value is String) {
      if (value.isEmpty || value.toLowerCase() == 'none') {
        return 'None';
      }
      return value;
    }
    
    return value.toString();
  }

  Widget _buildHistoryCard(String title, String content) {
    return InkWell(
      onTap: () => _showHistoryDetail(title, content),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      content,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showHistoryDetail(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2C5BFF),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF2C5BFF)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEncountersSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Encounters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C5BFF),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Past Encounter Notes'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2C5BFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_visits.isNotEmpty)
            ..._visits.take(3).map((visit) => _buildEncounterItem(visit))
          else
            _buildEncounterItem({
              'date': '2025-06-12',
              'title': 'Follow-up visit',
              'description': 'Complained of chest pain. ECG ordered.',
              'doctor': 'Dr. Smith',
              'status': 'Signed',
            }),
          const SizedBox(height: 16),
          _buildLastVisitCard(),
        ],
      ),
    );
  }

  Widget _buildEncounterItem(Map<String, dynamic> encounter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(encounter['date'] ?? encounter['visitDate']),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  encounter['title'] ?? encounter['reasonForVisit'] ?? 'Visit',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  encounter['description'] ??
                      encounter['diagnosis'] ??
                      'Medical consultation',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${encounter['doctor'] ?? encounter['doctorName'] ?? 'Dr. Unknown'}',
                  style: const TextStyle(fontSize: 11, color: Colors.blue),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              encounter['status'] ?? 'Signed',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildLastVisitCard() {
    final lastVisit = _visits.isNotEmpty ? _visits.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Last Visit: ${_formatDate(lastVisit?['visitDate'] ?? widget.patient.lastAppointment)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Signed',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.launch, size: 20),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildVisitDetailRow(
            'Reason for Visit',
            lastVisit?['reasonForVisit'] ?? 'Follow-up for chest pain',
          ),
          const SizedBox(height: 8),
          _buildVisitDetailRow(
            'Summary',
            lastVisit?['summary'] ??
                'Patient presents with intermittent chest pain without associated shortness of breath or dizziness. Vitals stable and physical exams unremarkable. No acute findings. Monitoring recommended.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDiagnosisChip('Diagnosis', 'Chest Pain'),
              _buildDiagnosisChip(
                'Type',
                lastVisit?['diagnosis'] ?? 'Atypical chest pain',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2C5BFF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF2C5BFF),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2C5BFF),
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: const BorderSide(color: Color(0xFF2C5BFF)),
        ),
      ),
    );
  }

  Widget _buildRecordHub() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Record Hub',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C5BFF),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabButton('Visits', 0),
                _buildTabButton('Surgeries', 1),
                _buildTabButton('Treatments', 2),
                _buildTabButton('Prescriptions', 3),
                _buildTabButton('Referrals', 4),
                _buildTabButton('Medical Tests', 5),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildTabContent(),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: () => setState(() => _selectedTabIndex = index),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF2C5BFF) : Colors.white,
          foregroundColor: isSelected ? Colors.white : const Color(0xFF2C5BFF),
          side: const BorderSide(color: Color(0xFF2C5BFF)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildVisitsList();
      case 1:
        return _buildSurgicalHistory();
      case 2:
        return _buildTreatmentsList();
      case 3:
        return _buildPrescriptionsList();
      case 4:
        return _buildReferralsList();
      case 5:
        return _buildMedicalTestsList();
      case 6:
        return _buildReportsList();
      default:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('No data available'),
          ),
        );
    }
  }

    Widget _buildPrescriptionsList() {
    if (_prescriptions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No prescriptions available'),
        ),
      );
    }

    // Sort prescriptions by date (most recent first)
    final sortedPrescriptions = List.from(_prescriptions);
    sortedPrescriptions.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['prescription_creation_time']);
        final dateB = DateTime.parse(b['prescription_creation_time']);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Prescription History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...sortedPrescriptions.map((prescription) => _buildPrescriptionCard(prescription)),
      ],
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> prescription) {
    final medicineInfo = prescription['medicine_name'] ?? 
                        prescription['prescription_description'] ?? 
                        'No medicine specified';
    final dose = prescription['dose'];
    final doseUnit = prescription['dose_unit']?.toString() ?? '';
    final frequency = prescription['frequency']?.toString() ?? '';
    final duration = prescription['duration']?.toString() ?? '';
    final route = prescription['route']?.toString() ?? '';
    final quantity = prescription['quantity'];
    final quantityUnit = prescription['quantity_unit']?.toString() ?? '';
    final refill = prescription['refill'];
    final doctorName = '${prescription['doctor_FName'] ?? ''} ${prescription['doctor_LName'] ?? ''}'.trim();
    final creationDate = prescription['prescription_creation_time'];
    final pharmacistPermission = prescription['pharmacist_permission'];
    final description = prescription['prescription_description']?.toString() ?? '';

    // Determine status based on pharmacist permission
    String status = 'Pending';
    Color statusColor = Colors.orange;
    Color statusTextColor = const Color(0xFFE65100);
    
    if (pharmacistPermission == 1) {
      status = 'Approved';
      statusColor = Colors.green;
      statusTextColor = const Color(0xFF2E7D32);
    } else if (pharmacistPermission == 0) {
      status = 'Rejected';
      statusColor = Colors.red;
      statusTextColor = const Color(0xFFC62828);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            medicineInfo,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (pharmacistPermission != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 11,
                                color: statusTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (dose != null && dose > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$dose $doseUnit',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2C5BFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          _buildPrescriptionDetailRow('Date', _formatDate(creationDate)),
          _buildPrescriptionDetailRow('Prescribed by', doctorName.isNotEmpty ? 'Dr. $doctorName' : 'Unknown Doctor'),
          if (frequency.isNotEmpty)
            _buildPrescriptionDetailRow('Frequency', frequency),
          if (duration.isNotEmpty)
            _buildPrescriptionDetailRow('Duration', duration),
          if (route.isNotEmpty)
            _buildPrescriptionDetailRow('Route', route),
          if (quantity != null && quantity > 0)
            _buildPrescriptionDetailRow('Quantity', '$quantity $quantityUnit'),
          if (refill != null && refill > 0)
            _buildPrescriptionDetailRow('Refills', refill.toString()),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showPrescriptionDetail(prescription),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
            ),
            child: const Text(
              'View Full Details',
              style: TextStyle(
                color: Color(0xFF2C5BFF),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrescriptionDetail(Map<String, dynamic> prescription) {
    final medicineInfo = prescription['medicine_name'] ?? 
                        prescription['prescription_description'] ?? 
                        'No medicine specified';
    final dose = prescription['dose'];
    final doseUnit = prescription['dose_unit']?.toString() ?? '';
    final frequency = prescription['frequency']?.toString() ?? '';
    final duration = prescription['duration']?.toString() ?? '';
    final route = prescription['route']?.toString() ?? '';
    final quantity = prescription['quantity'];
    final quantityUnit = prescription['quantity_unit']?.toString() ?? '';
    final refill = prescription['refill'];
    final doctorName = '${prescription['doctor_FName'] ?? ''} ${prescription['doctor_LName'] ?? ''}'.trim();
    final doctorPhone = prescription['doctor_phone']?.toString() ?? '';
    final doctorAddress = prescription['doctor_office_address']?.toString() ?? '';
    final creationDate = _formatDate(prescription['prescription_creation_time']);
    final pharmacistPermission = prescription['pharmacist_permission'];
    final description = prescription['prescription_description']?.toString() ?? '';

    // Determine status
    String status = 'Pending';
    Color statusColor = Colors.orange;
    Color statusTextColor = const Color(0xFFE65100);
    
    if (pharmacistPermission == 1) {
      status = 'Approved';
      statusColor = Colors.green;
      statusTextColor = const Color(0xFF2E7D32);
    } else if (pharmacistPermission == 0) {
      status = 'Rejected';
      statusColor = Colors.red;
      statusTextColor = const Color(0xFFC62828);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      medicineInfo,
                      style: const TextStyle(
                        color: Color(0xFF2C5BFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (pharmacistPermission != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (dose != null && dose > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$dose $doseUnit',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2C5BFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Prescribed Date', creationDate),
                const SizedBox(height: 12),
                const Text(
                  'Prescribing Doctor',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dr. $doctorName',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                if (doctorPhone.isNotEmpty)
                  Text(
                    'Phone: $doctorPhone',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                if (doctorAddress.isNotEmpty)
                  Text(
                    'Address: $doctorAddress',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Prescription Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                if (description.isNotEmpty)
                  _buildDetailRow('Description', description),
                if (frequency.isNotEmpty)
                  _buildDetailRow('Frequency', frequency),
                if (duration.isNotEmpty)
                  _buildDetailRow('Duration', duration),
                if (route.isNotEmpty)
                  _buildDetailRow('Route', route),
                if (quantity != null && quantity > 0)
                  _buildDetailRow('Quantity', '$quantity $quantityUnit'),
                if (refill != null && refill > 0)
                  _buildDetailRow('Refills Available', refill.toString()),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF2C5BFF)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSurgicalHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Surgical History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSurgeryCard(
          'Cesarean Section',
          '2021-11-10',
          'Dr. Maria Chen',
          'Lower abdomen',
          'Surgical (C-section)',
          'Spinal anesthesia',
          'Discharged after 3 days, recovered in 6 weeks',
          'Mild wound infection',
          'Completed',
        ),
        const SizedBox(height: 12),
        _buildSurgeryCard(
          'Appendectomy',
          '2020-08-18',
          'Dr. Johnson',
          'Lower right abdomen',
          'Laparoscopic',
          'General anesthesia',
          'No follow-up required',
          'None',
          'Completed',
        ),
        const SizedBox(height: 12),
        _buildSurgeryCard(
          'Gallbladder Removal',
          '2018-03-24',
          'Dr. Smith',
          'Right upper abdomen',
          'Laparoscopic',
          'General anesthesia',
          'Mild digestive symptoms for 1 week',
          'None',
          'Completed',
        ),
      ],
    );
  }

  Widget _buildSurgeryCard(
    String title,
    String date,
    String doctor,
    String site,
    String method,
    String anesthesia,
    String recovery,
    String complications,
    String status,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          _buildSurgeryDetailRow('Date', date),
          _buildSurgeryDetailRow('Doctor', doctor),
          _buildSurgeryDetailRow('Site', site),
          _buildSurgeryDetailRow('Method', method),
          _buildSurgeryDetailRow('Anesthesia', anesthesia),
          _buildSurgeryDetailRow('Recovery', recovery),
          _buildSurgeryDetailRow('Complications', complications),
        ],
      ),
    );
  }

  Widget _buildSurgeryDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentsList() {
    // Extract treatments data from patient details
    final treatments = _patientDetails?['treatments'] as List<dynamic>?;
    
    if (treatments == null || treatments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No treatments recorded'),
        ),
      );
    }

    // Filter out empty or undefined treatments and sort by date
    final validTreatments = treatments.where((treatment) {
      final treatmentText = treatment['treatment']?.toString() ?? '';
      return treatmentText.isNotEmpty && 
             treatmentText != 'undefined' && 
             treatment['RecordDate'] != '0000-00-00 00:00:00';
    }).toList();

    // Sort by date (most recent first)
    validTreatments.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['RecordDate']);
        final dateB = DateTime.parse(b['RecordDate']);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Treatment History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...validTreatments.map((treatment) => _buildTreatmentCard(treatment)),
      ],
    );
  }

    Widget _buildTreatmentCard(Map<String, dynamic> treatment) {
    final treatmentText = treatment['treatment']?.toString() ?? 'No treatment details';
    final recordDate = treatment['RecordDate'];
    final diseaseType = treatment['disease_type']?.toString();
    final doctorName = treatment['doctor_name']?.toString() ?? 'Unknown Doctor';
    
    // Determine if it's a long-form treatment (likely multiple lines)
    final isLongForm = treatmentText.contains('\n') || treatmentText.length > 50;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (diseaseType != null && diseaseType.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C5BFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          diseaseType,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2C5BFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      isLongForm ? 'Treatment Plan' : treatmentText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: isLongForm ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          _buildTreatmentDetailRow(
            'Date',
            _formatDate(recordDate),
          ),
          _buildTreatmentDetailRow(
            'Doctor',
            doctorName,
          ),
          if (!isLongForm)
            _buildTreatmentDetailRow(
              'Treatment',
              treatmentText,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Treatment:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  treatmentText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                TextButton(
                  onPressed: () => _showTreatmentDetail(treatment),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Text(
                    'View Full Details',
                    style: TextStyle(
                      color: Color(0xFF2C5BFF),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

    Widget _buildTreatmentDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _showTreatmentDetail(Map<String, dynamic> treatment) {
    final treatmentText = treatment['treatment']?.toString() ?? 'No details';
    final diseaseType = treatment['disease_type']?.toString();
    final doctorName = treatment['doctor_name']?.toString() ?? 'Unknown Doctor';
    final recordDate = _formatDate(treatment['RecordDate']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (diseaseType != null && diseaseType.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C5BFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    diseaseType,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2C5BFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Text(
                'Treatment Details',
                style: TextStyle(
                  color: Color(0xFF2C5BFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Date', recordDate),
                const SizedBox(height: 12),
                _buildDetailRow('Doctor', doctorName),
                const SizedBox(height: 12),
                const Text(
                  'Treatment Plan:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  treatmentText,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF2C5BFF)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.visible, // Allow label to wrap if needed
              softWrap: true,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return Column(
      children:  [
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No reports available'),
                ),
              ),
            ]
          ,
    );
  }

  Widget _buildReportItem(Map<String, dynamic> test) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: Color(0xFF2C5BFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test['testName'] ?? 'Medical Test',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  _formatDate(test['date']),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildReferralsList() {
    if (_referrals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No referrals'),
        ),
      );
    }

    // Filter out invalid referrals and sort by date
    final validReferrals = _referrals.where((referral) {
      final referralDate = referral['referral_date']?.toString() ?? '';
      final doctorName = '${referral['referred_doctor_FName'] ?? ''} ${referral['referred_doctor_LName'] ?? ''}'.trim();
      return referralDate != '1899-11-30T00:00:00.000Z' && doctorName.isNotEmpty;
    }).toList();

    // Sort by referral date (most recent first)
    validReferrals.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['referral_date']);
        final dateB = DateTime.parse(b['referral_date']);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    if (validReferrals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No valid referrals'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Referral History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...validReferrals.map((referral) => _buildReferralItem(referral)),
      ],
    );
  }

  Widget _buildReferralItem(Map<String, dynamic> referral) {
    final doctorName = '${referral['referred_doctor_FName'] ?? ''} ${referral['referred_doctor_LName'] ?? ''}'.trim();
    final specialization = referral['referred_doctor_specialization']?.toString() ?? '';
    final phone = referral['referred_doctor_phone']?.toString() ?? '';
    final referralDate = referral['referral_date'];
    final referralMessage = referral['referral_message']?.toString() ?? '';
    final isInSystem = referral['is_referred_doctor_in_system'] == 1;
    final appointmentDate = referral['first_appointment_date'];

    // Determine status
    String status = 'Pending';
    Color statusColor = Colors.orange;
    Color statusTextColor = const Color(0xFFE65100);
    
    if (appointmentDate != null) {
      status = 'Scheduled';
      statusColor = Colors.green;
      statusTextColor = const Color(0xFF2E7D32);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Dr. $doctorName',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (specialization.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C5BFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                specialization,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2C5BFF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isInSystem)
                              Row(
                                children: const [
                                  Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Color(0xFF2C5BFF),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'In System',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF2C5BFF),
                                      fontWeight: FontWeight.w600,
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
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          _buildReferralDetailRow('Referral Date', _formatDate(referralDate)),
          if (phone.isNotEmpty)
            _buildReferralDetailRow('Phone', phone),
          if (appointmentDate != null)
            _buildReferralDetailRow('First Appointment', _formatDate(appointmentDate)),
          if (referralMessage.isNotEmpty)
            _buildReferralDetailRow(
              'Message',
              referralMessage.length > 50 
                ? '${referralMessage.substring(0, 50)}...' 
                : referralMessage,
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showReferralDetail(referral),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
            ),
            child: const Text(
              'View Full Details',
              style: TextStyle(
                color: Color(0xFF2C5BFF),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _showReferralDetail(Map<String, dynamic> referral) {
    final doctorName = '${referral['referred_doctor_FName'] ?? ''} ${referral['referred_doctor_LName'] ?? ''}'.trim();
    final specialization = referral['referred_doctor_specialization']?.toString() ?? '';
    final phone = referral['referred_doctor_phone']?.toString() ?? '';
    final referralDate = _formatDate(referral['referral_date']);
    final referralMessage = referral['referral_message']?.toString() ?? '';
    final isInSystem = referral['is_referred_doctor_in_system'] == 1;
    final appointmentDate = referral['first_appointment_date'];
    final patientName = '${referral['patient_FName'] ?? ''} ${referral['patient_LName'] ?? ''}'.trim();
    final patientPhone = referral['patient_MobileNumber']?.toString() ?? '';

    // Determine status
    String status = 'Pending';
    Color statusColor = Colors.orange;
    Color statusTextColor = const Color(0xFFE65100);
    
    if (appointmentDate != null) {
      status = 'Scheduled';
      statusColor = Colors.green;
      statusTextColor = const Color(0xFF2E7D32);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Dr. $doctorName',
                      style: const TextStyle(
                        color: Color(0xFF2C5BFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (specialization.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C5BFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          specialization,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2C5BFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isInSystem)
                        Row(
                          children: const [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Color(0xFF2C5BFF),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'In System',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2C5BFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Referral Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Referral Date', referralDate),
                if (phone.isNotEmpty)
                  _buildDetailRow('Phone', phone),
                if (appointmentDate != null)
                  _buildDetailRow('First Appointment', _formatDate(appointmentDate)),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Patient Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Patient Name', patientName),
                if (patientPhone.isNotEmpty)
                  _buildDetailRow('Patient Phone', patientPhone),
                if (referralMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Referral Message',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    referralMessage,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (phone.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  // TODO: Implement call functionality
                },
                icon: const Icon(Icons.phone, size: 18),
                label: const Text('Call'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2C5BFF),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF2C5BFF)),
              ),
            ),
          ],
        );
      },
    );
  }

    Widget _buildVisitsList() {
    debugPrint('Building visits list. Total visits: ${_visits.length}');
    _visits.forEach((visit) {
      debugPrint('Visit: ${visit['reason_for_visit']} - ${visit['date']}');
    });
    if (_visits.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No visits recorded'),
        ),
      );
    }

    // Filter out invalid visits and sort by date
    final validVisits = _visits.where((visit) {
      final reason = visit['reason_for_visit']?.toString() ?? '';
      final observations = visit['observations']?.toString() ?? '';
      return reason.isNotEmpty || observations.isNotEmpty;
    }).toList();

    // Sort by date (most recent first)
    validVisits.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    if (validVisits.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No valid visits'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Visit History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...validVisits.map((visit) => _buildVisitCard(visit)),
      ],
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit) {
    final reason = visit['reason_for_visit']?.toString() ?? 'General Visit';
    final observations = visit['observations']?.toString() ?? '';
    final visitDate = visit['date'];
    final startTime = visit['start_time']?.toString() ?? '';
    final endTime = visit['end_time']?.toString() ?? '';
    final recordTime = visit['record_time'];

    // Format time display
    String timeDisplay = '';
    if (startTime.isNotEmpty && startTime != '00:00:00' && 
        endTime.isNotEmpty && endTime != '00:00:00') {
      timeDisplay = '${_formatTime(startTime)} - ${_formatTime(endTime)}';
    }

    // Determine status based on date
    String status = 'Completed';
    Color statusColor = Colors.green;
    Color statusTextColor = const Color(0xFF2E7D32);
    
    try {
      final visitDateTime = DateTime.parse(visit['date']);
      final now = DateTime.now();
      
      if (visitDateTime.isAfter(now)) {
        status = 'Scheduled';
        statusColor = Colors.blue;
        statusTextColor = const Color(0xFF1976D2);
      } else if (visitDateTime.year == now.year && 
                 visitDateTime.month == now.month && 
                 visitDateTime.day == now.day) {
        status = 'Today';
        statusColor = Colors.orange;
        statusTextColor = const Color(0xFFE65100);
      }
    } catch (e) {
      debugPrint('Error parsing visit date: $e');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reason.isEmpty ? 'General Visit' : reason,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (timeDisplay.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Color(0xFF2C5BFF),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeDisplay,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2C5BFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Date', _formatDate(visitDate)),
          if (observations.isNotEmpty)
            _buildDetailRow(
              'Observations',
              observations.length > 80 
                ? '${observations.substring(0, 80)}...' 
                : observations,
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showVisitDetail(visit),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
            ),
            child: const Text(
              'View Full Details',
              style: TextStyle(
                color: Color(0xFF2C5BFF),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildDetailRow(String label, String value) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 8),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         SizedBox(
  //           width: 110,
  //           child: Text(
  //             '$label:',
  //             style: const TextStyle(
  //               fontSize: 13,
  //               fontWeight: FontWeight.w600,
  //               color: Colors.black87,
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           child: Text(
  //             value,
  //             style: const TextStyle(fontSize: 13, color: Colors.black54),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        
        String period = 'AM';
        if (hour >= 12) {
          period = 'PM';
          if (hour > 12) hour -= 12;
        }
        if (hour == 0) hour = 12;
        
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      debugPrint('Error formatting time: $e');
    }
    return time;
  }

  void _showVisitDetail(Map<String, dynamic> visit) {
    final reason = visit['reason_for_visit']?.toString() ?? 'General Visit';
    final observations = visit['observations']?.toString() ?? '';
    final visitDate = _formatDate(visit['date']);
    final startTime = visit['start_time']?.toString() ?? '';
    final endTime = visit['end_time']?.toString() ?? '';
    final recordTime = _formatDate(visit['record_time']);

    // Format time display
    String timeDisplay = 'Not specified';
    if (startTime.isNotEmpty && startTime != '00:00:00' && 
        endTime.isNotEmpty && endTime != '00:00:00') {
      timeDisplay = '${_formatTime(startTime)} - ${_formatTime(endTime)}';
    }

    // Determine status
    String status = 'Completed';
    Color statusColor = Colors.green;
    Color statusTextColor = const Color(0xFF2E7D32);
    
    try {
      final visitDateTime = DateTime.parse(visit['date']);
      final now = DateTime.now();
      
      if (visitDateTime.isAfter(now)) {
        status = 'Scheduled';
        statusColor = Colors.blue;
        statusTextColor = const Color(0xFF1976D2);
      } else if (visitDateTime.year == now.year && 
                 visitDateTime.month == now.month && 
                 visitDateTime.day == now.day) {
        status = 'Today';
        statusColor = Colors.orange;
        statusTextColor = const Color(0xFFE65100);
      }
    } catch (e) {
      debugPrint('Error parsing visit date: $e');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reason.isEmpty ? 'General Visit' : reason,
                      style: const TextStyle(
                        color: Color(0xFF2C5BFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Visit Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Visit Date', visitDate),
                _buildDetailRow('Time', timeDisplay),
                _buildDetailRow('Recorded', recordTime),
                if (observations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Clinical Observations',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    observations,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF2C5BFF)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMedicalTestsList() {
    if (_medicalTests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No medical tests available'),
        ),
      );
    }

    // Extract the main test info from key "0"
    final mainTest = _medicalTests["0"] as Map<String, dynamic>?;
    final additionalData = _medicalTests["1"] as Map<String, dynamic>?;
    
    if (mainTest == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No valid medical tests'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Medical Tests History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
              color: const Color(0xFF2C5BFF),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMedicalTestCard(mainTest, additionalData),
      ],
    );
  }

  Widget _buildMedicalTestCard(Map<String, dynamic> test, Map<String, dynamic>? additionalData) {
    final practitionerName = test['practitioner_name']?.toString() ?? 'Unknown Practitioner';
    final labServiceDate = test['lab_service_date'];
    final specimenDate = test['specimen_collection_date'];
    final signatureDate = test['signature_date'];
    final clinicalInfo = test['clinical_information']?.toString() ?? '';
    final labNotes = test['lab_notes']?.toString() ?? '';
    
    // Determine which date to use
    String displayDate = 'Date not specified';
    if (labServiceDate != null) {
      displayDate = _formatDate(labServiceDate);
    } else if (specimenDate != null) {
      displayDate = _formatDate(specimenDate);
    } else if (signatureDate != null) {
      displayDate = _formatDate(signatureDate);
    }

    // Count test types from both main test and additional data
    int testCount = _countMedicalTests(test, additionalData);
    
    // Determine status
    String status = 'Completed';
    Color statusColor = Colors.green;
    Color statusTextColor = const Color(0xFF2E7D32);
    
    if (signatureDate == null) {
      status = 'Pending';
      statusColor = Colors.orange;
      statusTextColor = const Color(0xFFE65100);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Laboratory Tests',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (testCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C5BFF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$testCount test${testCount > 1 ? "s" : ""} ordered',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2C5BFF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Date', displayDate),
          _buildDetailRow('Practitioner', practitionerName),
          if (clinicalInfo.isNotEmpty)
            _buildDetailRow(
              'Clinical Info',
              clinicalInfo.length > 60 
                ? '${clinicalInfo.substring(0, 60)}...' 
                : clinicalInfo,
            ),
          if (labNotes.isNotEmpty)
            _buildDetailRow(
              'Lab Notes',
              labNotes.length > 60 
                ? '${labNotes.substring(0, 60)}...' 
                : labNotes,
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showMedicalTestDetail(test, additionalData),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
            ),
            child: const Text(
              'View Test Details',
              style: TextStyle(
                color: Color(0xFF2C5BFF),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _countMedicalTests(Map<String, dynamic> test, Map<String, dynamic>? additionalData) {
    int count = 0;
    
    // Chemistry tests from main test
    if (test['glucose_radio'] != null) count++;
    if (test['hbA1C'] != null) count++;
    if (test['creatinine'] != null) count++;
    if (test['uric_acid'] != null) count++;
    if (test['sodium'] != null) count++;
    if (test['potassium'] != null) count++;
    if (test['alt'] != null) count++;
    if (test['alk'] != null) count++;
    if (test['bilirubin'] != null) count++;
    if (test['albumin'] != null) count++;
    if (test['lipid_assessment'] != null) count++;
    if (test['albumin_creatine_ratio'] != null) count++;
    if (test['urinalysis'] != null) count++;
    
    // Count tests from additional data structure
    if (additionalData != null) {
      // Vitamin D
      if (additionalData['medical_request_form_vitamind'] != null) count++;
      
      // PSA
      if (additionalData['medical_request_form_psa'] != null) count++;
      
      // Immunology tests
      final immunology = additionalData['medical_request_form_immunology'];
      if (immunology is List && immunology.isNotEmpty) {
        count += immunology.length;
      }
      
      // Hepatitis tests
      final hepatitis = additionalData['medical_request_form_hepatitis'];
      if (hepatitis is List && hepatitis.isNotEmpty) {
        count += hepatitis.length;
      }
      
      // Hematology
      final hematology = additionalData['medical_request_form_hermatology'];
      if (hematology is List && hematology.isNotEmpty) {
        count += hematology.length;
      }
      
      // Microbiology
      if (additionalData['medical_request_form_microbiology_id_sensitivities'] != null) count++;
    }
    
    return count > 0 ? count : 1;
  }

  void _showMedicalTestDetail(Map<String, dynamic> test, Map<String, dynamic>? additionalData) {
    final practitionerName = test['practitioner_name']?.toString() ?? 'Unknown Practitioner';
    final practitionerPhone = test['practitioner_phone_number']?.toString() ?? '';
    final practitionerAddress = test['practitioner_address']?.toString() ?? '';
    final labServiceDate = test['lab_service_date'];
    final specimenDate = test['specimen_collection_date'];
    final specimenTime = test['specimen_collection_time']?.toString() ?? '';
    final signatureDate = test['signature_date'];
    final clinicalInfo = test['clinical_information']?.toString() ?? '';
    final labNotes = test['lab_notes']?.toString() ?? '';
    final testTypes = test['test_types']?.toString() ?? '';
    
    // Determine status
    String status = 'Completed';
    Color statusColor = Colors.green;
    Color statusTextColor = const Color(0xFF2E7D32);
    
    if (signatureDate == null) {
      status = 'Pending';
      statusColor = Colors.orange;
      statusTextColor = const Color(0xFFE65100);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Medical Test Details',
                  style: TextStyle(
                    color: Color(0xFF2C5BFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Practitioner Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Name', practitionerName),
                if (practitionerPhone.isNotEmpty)
                  _buildDetailRow('Phone', practitionerPhone),
                if (practitionerAddress.isNotEmpty)
                  _buildDetailRow('Address', practitionerAddress),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Test Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                if (labServiceDate != null)
                  _buildDetailRow('Service Date', _formatDate(labServiceDate)),
                if (specimenDate != null)
                  _buildDetailRow('Specimen Date', _formatDate(specimenDate)),
                if (specimenTime.isNotEmpty)
                  _buildDetailRow('Collection Time', specimenTime),
                if (signatureDate != null)
                  _buildDetailRow('Signed Date', _formatDate(signatureDate)),
                if (testTypes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Test Types',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    testTypes,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black54),
                  ),
                ],
                if (clinicalInfo.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Clinical Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    clinicalInfo,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black54),
                  ),
                ],
                if (labNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Lab Notes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labNotes,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black54),
                  ),
                ],
                _buildTestCategories(test, additionalData),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF2C5BFF)),
              ),
            ),
          ],
        );
      },
    );
  }

    Widget _buildTestCategories(Map<String, dynamic> test, Map<String, dynamic>? additionalData) {
    List<Widget> categories = [];

    // Chemistry Tests
    List<String> chemistryTests = [];
    if (test['glucose_radio'] != null) chemistryTests.add('Glucose');
    if (test['hbA1C'] != null) chemistryTests.add('HbA1C');
    if (test['creatinine'] != null) chemistryTests.add('Creatinine');
    if (test['uric_acid'] != null) chemistryTests.add('Uric Acid');
    if (test['sodium'] != null) chemistryTests.add('Sodium');
    if (test['potassium'] != null) chemistryTests.add('Potassium');
    if (test['alt'] != null) chemistryTests.add('ALT');
    if (test['alk'] != null) chemistryTests.add('ALK');
    if (test['bilirubin'] != null) chemistryTests.add('Bilirubin');
    if (test['albumin'] != null) chemistryTests.add('Albumin');
    if (test['lipid_assessment'] != null) chemistryTests.add('Lipid Assessment');
    if (test['albumin_creatine_ratio'] != null) chemistryTests.add('Albumin/Creatine Ratio');
    if (test['urinalysis'] != null) chemistryTests.add('Urinalysis');

    if (chemistryTests.isNotEmpty) {
      categories.add(_buildTestCategory('Chemistry Tests', chemistryTests));
    }

    // Additional tests from additionalData
    if (additionalData != null) {
      // Vitamin D
      final vitaminD = additionalData['medical_request_form_vitamind'];
      if (vitaminD is List && vitaminD.isNotEmpty) {
        List<String> vitaminDTests = [];
        for (var test in vitaminD) {
          if (test['insuredVitaminD'] == 1) vitaminDTests.add('Vitamin D (Insured)');
          if (test['uninsuredVitaminD'] == 1) vitaminDTests.add('Vitamin D (Uninsured)');
        }
        if (vitaminDTests.isNotEmpty) {
          categories.add(_buildTestCategory('Vitamin D', vitaminDTests));
        }
      }

      // PSA
      final psa = additionalData['medical_request_form_psa'];
      if (psa is List && psa.isNotEmpty) {
        List<String> psaTests = [];
        for (var test in psa) {
          if (test['totalPSA'] == 1) psaTests.add('Total PSA');
          if (test['freePSA'] == 1) psaTests.add('Free PSA');
        }
        if (psaTests.isNotEmpty) {
          categories.add(_buildTestCategory('PSA Tests', psaTests));
        }
      }

      // Immunology
      final immunology = additionalData['medical_request_form_immunology'];
      if (immunology is List && immunology.isNotEmpty) {
        List<String> immunologyTests = [];
        for (var test in immunology) {
          if (test['pregnancyTestUrine'] == 1) immunologyTests.add('Pregnancy Test (Urine)');
          if (test['mononucleosis'] == 1) immunologyTests.add('Mononucleosis');
          if (test['rubella'] == 1) immunologyTests.add('Rubella');
          if (test['prenatalABORhDAntibody'] == 1) immunologyTests.add('Prenatal ABO/RhD');
          if (test['repeatPrenatalAntibodies'] == 1) immunologyTests.add('Repeat Prenatal Antibodies');
        }
        if (immunologyTests.isNotEmpty) {
          categories.add(_buildTestCategory('Immunology', immunologyTests));
        }
      }

      // Hepatitis
      final hepatitis = additionalData['medical_request_form_hepatitis'];
      if (hepatitis is List && hepatitis.isNotEmpty) {
        List<String> hepatitisTests = [];
        for (var test in hepatitis) {
          if (test['acuteHepatitis'] == 1) hepatitisTests.add('Acute Hepatitis');
          if (test['chronicHepatitis'] == 1) hepatitisTests.add('Chronic Hepatitis');
          if (test['immuneStatusExposure'] == 1) hepatitisTests.add('Immune Status/Exposure');
          if (test['hepatitisA'] == 1) hepatitisTests.add('Hepatitis A');
          if (test['hepatitisB'] == 1) hepatitisTests.add('Hepatitis B');
          if (test['hepatitisC'] == 1) hepatitisTests.add('Hepatitis C');
        }
        if (hepatitisTests.isNotEmpty) {
          categories.add(_buildTestCategory('Hepatitis', hepatitisTests));
        }
      }

      // Hematology
      final hematology = additionalData['medical_request_form_hermatology'];
      if (hematology is List && hematology.isNotEmpty) {
        List<String> hematologyTests = [];
        for (var test in hematology) {
          if (test['cbc'] == 1) hematologyTests.add('CBC');
          if (test['prothrombinTime'] != null) hematologyTests.add('Prothrombin Time');
        }
        if (hematologyTests.isNotEmpty) {
          categories.add(_buildTestCategory('Hematology', hematologyTests));
        }
      }

      // Microbiology
      final microbiology = additionalData['medical_request_form_microbiology_id_sensitivities'];
      if (microbiology is List && microbiology.isNotEmpty) {
        List<String> microbiologyTests = [];
        for (var test in microbiology) {
          if (test['cervicalSwab'] == 1) microbiologyTests.add('Cervical Swab');
          if (test['vaginalSwab'] == 1) microbiologyTests.add('Vaginal Swab');
          if (test['vaginalRectalGroupBStrep'] == 1) microbiologyTests.add('Vaginal/Rectal Group B Strep');
          if (test['chlamydia'] == 1) microbiologyTests.add('Chlamydia');
          if (test['gc'] == 1) microbiologyTests.add('GC');
          if (test['sputum'] == 1) microbiologyTests.add('Sputum');
          if (test['throatSwab'] == 1) microbiologyTests.add('Throat Swab');
          if (test['woundSwab'] == 1) microbiologyTests.add('Wound Swab');
          if (test['urineCulture'] == 1) microbiologyTests.add('Urine Culture');
          if (test['stoolCulture'] == 1) microbiologyTests.add('Stool Culture');
          if (test['stoolOvaParasites'] == 1) microbiologyTests.add('Stool Ova/Parasites');
          if (test['otherSwabs'] == 1) microbiologyTests.add('Other Swabs');
        }
        if (microbiologyTests.isNotEmpty) {
          categories.add(_buildTestCategory('Microbiology', microbiologyTests));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories,
    );
  }

  Widget _buildTestCategory(String title, List<String> tests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tests.map((test) => Chip(
            label: Text(
              test,
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: const Color(0xFF2C5BFF).withOpacity(0.1),
            labelStyle: const TextStyle(color: Color(0xFF2C5BFF)),
          )).toList(),
        ),
      ],
    );
  }
}
