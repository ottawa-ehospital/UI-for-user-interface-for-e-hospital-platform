import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:html' as html;

class EHospitalExplainerApp extends StatelessWidget {
  const EHospitalExplainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E Hospital Medical Test Explainer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          primary: const Color(0xFF1976D2),
          secondary: const Color(0xFF64B5F6),
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _reportController = TextEditingController();
  final String apiBaseUrl = 'http://localhost:5001/api';
  
  String? _selectedReportType = 'auto';
  bool _isLoading = false;
  String? _explanation;
  Map<String, dynamic>? _summary;
  String? _fileName;
  List<int>? _fileBytes;

  final Map<String, String> _samples = {
    'Normal CBC': '''Complete Blood Count (CBC)
WBC: 7.5 × 10^9/L [4.0-11.0]
RBC: 4.8 × 10^12/L [4.5-5.9]
Hemoglobin: 14.5 g/dL [13.5-17.5]
Hematocrit: 42% [38-50]
Platelets: 250 × 10^9/L [150-400]''',
    
    'Lipid Panel': '''Lipid Panel
Total Cholesterol: 235 mg/dL [<200]
LDL Cholesterol: 155 mg/dL [<100]
HDL Cholesterol: 48 mg/dL [>40]
Triglycerides: 165 mg/dL [<150]''',
    
    'Chest X-Ray': '''CHEST X-RAY
FINDINGS: The lungs are clear. No focal consolidation, pleural effusion, or pneumothorax.
Heart size is normal. No acute osseous abnormality is detected.
IMPRESSION: No acute cardiopulmonary process.''',
  };

  void _loadSample(String sampleName) {
    setState(() {
      _reportController.text = _samples[sampleName]!;
      _fileName = null;
      _fileBytes = null;
      _explanation = null;
      _summary = null;
    });
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'docx'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _fileName = result.files.single.name;
          _fileBytes = result.files.single.bytes;
          _reportController.clear();
          _explanation = null;
          _summary = null;
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _generateExplanation() async {
    if (_reportController.text.trim().isEmpty && _fileBytes == null) {
      _showError('Please enter a medical report or upload a file');
      return;
    }

    setState(() {
      _isLoading = true;
      _explanation = null;
      _summary = null;
    });

    try {
      Map<String, dynamic> result;
      
      if (_fileBytes != null) {
        result = await _uploadReport();
      } else {
        result = await _explainReport();
      }

      if (result['success'] == true) {
        setState(() {
          _explanation = result['data']['explanation'];
          _summary = result['data']['summary'];
          _isLoading = false;
        });
      } else {
        _showError(result['error'] ?? 'An error occurred');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Connection error. Make sure backend is running on port 5001.');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _explainReport() async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/explain'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'report_text': _reportController.text,
          'report_type': _selectedReportType ?? 'auto',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> _uploadReport() async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/upload'));
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _fileBytes!,
        filename: _fileName,
      ));
      request.fields['report_type'] = _selectedReportType ?? 'auto';

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'error': 'Upload error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Upload failed: $e'};
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _reportController.clear();
      _fileName = null;
      _fileBytes = null;
      _explanation = null;
      _summary = null;
    });
  }

  void _downloadResults() {
    if (_explanation == null) return;

    final content = '''E HOSPITAL EXPLAINER
AI-Powered Medical Report Explanation
=====================================

Generated: ${DateTime.now()}
Report Type: $_selectedReportType

EXPLANATION:
$_explanation

=====================================
DISCLAIMER: This is for educational purposes only and is NOT medical advice.
Always consult your healthcare provider.
''';

    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'medical-report-${DateTime.now().millisecondsSinceEpoch}.txt')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInputSection(),
                    const SizedBox(height: 24),
                    _buildGenerateButton(),
                    const SizedBox(height: 24),
                    if (_isLoading) _buildLoadingIndicator(),
                    if (_explanation != null) _buildResultsSection(),
                    if (!_isLoading && _explanation == null) _buildDisclaimer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1976D2),
            Color(0xFF64B5F6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'E Hospital Explainer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'AI-Powered Medical Report Translation',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.description, color: Color(0xFF1976D2)),
                SizedBox(width: 12),
                Text(
                  'Step 1: Enter Medical Report',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _samples.keys.map((sampleName) {
                return OutlinedButton.icon(
                  onPressed: () => _loadSample(sampleName),
                  icon: const Icon(Icons.science, size: 18),
                  label: Text(sampleName),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1976D2),
                    side: const BorderSide(color: Color(0xFF1976D2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (_fileName == null) ...[
              TextField(
                controller: _reportController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Paste your medical report here...\n\nExample:\nComplete Blood Count (CBC)\nWBC: 7.5 × 10^9/L [4.0-11.0]\nHemoglobin: 14.5 g/dL [13.5-17.5]',
                  hintStyle: const TextStyle(fontSize: 14),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1976D2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_fileName == null)
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload File (PDF/TXT/DOCX)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1976D2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: Color(0xFF1976D2)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _fileName ?? 'File selected',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _fileName = null;
                          _fileBytes = null;
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedReportType,
              decoration: InputDecoration(
                labelText: 'Report Type',
                prefixIcon: const Icon(Icons.category),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'auto', child: Text('Auto-Detect')),
                DropdownMenuItem(value: 'blood_test', child: Text('Blood Test')),
                DropdownMenuItem(value: 'imaging', child: Text('Imaging Report')),
              ],
              onChanged: (value) {
                setState(() => _selectedReportType = value);
              },
            ),
            if (_reportController.text.isNotEmpty || _fileName != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _clearAll,
                icon: const Icon(Icons.clear),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _generateExplanation,
      icon: const Icon(Icons.auto_awesome, size: 24),
      label: const Text('Generate Patient-Friendly Explanation'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 20),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
            ),
            const SizedBox(height: 24),
            Text(
              'AI is analyzing your report...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This usually takes 2-3 seconds',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Card(
      elevation: 2,
      color: const Color(0xFFE3F2FD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Patient-Friendly Explanation',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _downloadResults,
                  icon: const Icon(Icons.download),
                  tooltip: 'Download Results',
                  color: const Color(0xFF1976D2),
                ),
              ],
            ),
            if (_summary != null) ...[
              const SizedBox(height: 20),
              _buildSummaryStats(),
            ],
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                _explanation!,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton.icon(
                onPressed: _clearAll,
                icon: const Icon(Icons.refresh),
                label: const Text('Analyze Another Report'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1976D2),
                  side: const BorderSide(color: Color(0xFF1976D2)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total Tests',
            '${_summary!['total_tests'] ?? 0}',
            Icons.science,
          ),
          _buildStatItem(
            'Normal',
            '${_summary!['normal_results'] ?? 0}',
            Icons.check_circle,
            Colors.green,
          ),
          _buildStatItem(
            'Abnormal',
            '${_summary!['abnormal_results'] ?? 0}',
            Icons.warning,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? const Color(0xFF1976D2), size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFF1976D2),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Disclaimer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This tool is for educational purposes only and is not medical advice. Always consult your healthcare provider for medical decisions, diagnosis, treatment recommendations, and any health concerns.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }
}
