import 'package:flutter/material.dart';

class MatchedPatientsTable extends StatefulWidget {
  const MatchedPatientsTable({super.key});

  @override
  State<MatchedPatientsTable> createState() => _MatchedPatientsTableState();
}

class _MatchedPatientsTableState extends State<MatchedPatientsTable> {
  bool pathology = true;
  bool gender = true;
  bool age = true;
  bool diseases = true;
  bool bmi = true;
  bool priorMedications = true;
  bool surgeries = true;
  bool pregnancy = true;

  String genderValue = 'Both';
  String pregnancyValue = 'Unrestricted';
  String diseaseValue = 'Cardiovascular Diseases';
  String surgeryValue = 'Recent surgeries';

  final pathologyController = TextEditingController(text: 'Migraine');
  final minAgeController = TextEditingController(text: '18');
  final maxAgeController = TextEditingController(text: '65');
  final minBmiController = TextEditingController(text: '18');
  final maxBmiController = TextEditingController(text: '30');
  final priorMedicationsController = TextEditingController(text: 'None');

  @override
  void dispose() {
    pathologyController.dispose();
    minAgeController.dispose();
    maxAgeController.dispose();
    minBmiController.dispose();
    maxBmiController.dispose();
    priorMedicationsController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1E4ED8)),
      ),
    );
  }

  String get bmiText {
    final min = minBmiController.text.trim();
    final max = maxBmiController.text.trim();
    if (min.isEmpty && max.isEmpty) return '> 1 and < 99';
    if (min.isNotEmpty && max.isNotEmpty) return '> $min and < $max';
    if (min.isNotEmpty) return '> $min';
    return '< $max';
  }

  @override
  Widget build(BuildContext context) {
    final matchedPatients = [
      ['Alice Johnson', 'Frequent migraine episodes with aura'],
      ['Michael Brown', 'Chronic migraine with medication history'],
      ['Sophia Davis', 'Recurring severe migraine symptoms'],
      ['Daniel Clark', 'Migraine with neurological indicators'],
      ['Emma Harris', 'Long-term migraine case'],
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Matched Patients',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E4ED8),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _openSettingsDialog,
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1E4ED8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Patient Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    'Detailed Description',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(matchedPatients.length, (index) {
            final row = matchedPatients[index];
            final isEven = index % 2 == 0;
            return Container(
              color: isEven ? const Color(0xFFF9FAFB) : Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Open patient ${row[0]}')),
                        );
                      },
                      child: Text(
                        row[0],
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      row[1],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget checkboxRow({
              required bool value,
              required String label,
              required ValueChanged<bool?> onChanged,
              Widget? trailing,
            }) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 170,
                      child: CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: value,
                        onChanged: onChanged,
                        title: Text(label),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: trailing ?? const SizedBox()),
                  ],
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 620,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.all(22),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Custom Matching Criteria',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Inclusion Criteria',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      checkboxRow(
                        value: pathology,
                        label: 'Pathology',
                        onChanged: (v) =>
                            setDialogState(() => pathology = v ?? false),
                        trailing: TextField(
                          controller: pathologyController,
                          enabled: pathology,
                          decoration: _inputDecoration('Pathology'),
                        ),
                      ),
                      checkboxRow(
                        value: gender,
                        label: 'Gender',
                        onChanged: (v) =>
                            setDialogState(() => gender = v ?? false),
                        trailing: DropdownButtonFormField<String>(
                          value: genderValue,
                          items: const [
                            DropdownMenuItem(value: 'Male', child: Text('Male')),
                            DropdownMenuItem(value: 'Female', child: Text('Female')),
                            DropdownMenuItem(value: 'Both', child: Text('Both')),
                          ],
                          onChanged: gender
                              ? (v) => setDialogState(
                                    () => genderValue = v ?? 'Both',
                                  )
                              : null,
                          decoration: _inputDecoration('Gender'),
                        ),
                      ),
                      checkboxRow(
                        value: pregnancy,
                        label: 'Pregnancy',
                        onChanged: (v) =>
                            setDialogState(() => pregnancy = v ?? false),
                        trailing: DropdownButtonFormField<String>(
                          value: pregnancyValue,
                          items: const [
                            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                            DropdownMenuItem(value: 'No', child: Text('No')),
                            DropdownMenuItem(
                              value: 'Unrestricted',
                              child: Text('Unrestricted'),
                            ),
                          ],
                          onChanged: pregnancy
                              ? (v) => setDialogState(
                                    () => pregnancyValue = v ?? 'Unrestricted',
                                  )
                              : null,
                          decoration: _inputDecoration('Pregnancy'),
                        ),
                      ),
                      checkboxRow(
                        value: age,
                        label: 'Age',
                        onChanged: (v) =>
                            setDialogState(() => age = v ?? false),
                        trailing: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: minAgeController,
                                enabled: age,
                                decoration: _inputDecoration('Min Age'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: maxAgeController,
                                enabled: age,
                                decoration: _inputDecoration('Max Age'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Exclusion Criteria',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      checkboxRow(
                        value: bmi,
                        label: 'BMI',
                        onChanged: (v) =>
                            setDialogState(() => bmi = v ?? false),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: minBmiController,
                                    enabled: bmi,
                                    decoration: _inputDecoration('Min BMI'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: maxBmiController,
                                    enabled: bmi,
                                    decoration: _inputDecoration('Max BMI'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bmiText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      checkboxRow(
                        value: diseases,
                        label: 'Diseases',
                        onChanged: (v) =>
                            setDialogState(() => diseases = v ?? false),
                        trailing: DropdownButtonFormField<String>(
                          value: diseaseValue,
                          items: const [
                            DropdownMenuItem(
                              value: 'Cardiovascular Diseases',
                              child: Text('Cardiovascular Diseases'),
                            ),
                            DropdownMenuItem(
                              value: 'Endocrine Diseases',
                              child: Text('Endocrine Diseases'),
                            ),
                            DropdownMenuItem(
                              value: 'Respiratory Diseases',
                              child: Text('Respiratory Diseases'),
                            ),
                          ],
                          onChanged: diseases
                              ? (v) => setDialogState(
                                    () => diseaseValue =
                                        v ?? 'Cardiovascular Diseases',
                                  )
                              : null,
                          decoration: _inputDecoration('Diseases'),
                        ),
                      ),
                      checkboxRow(
                        value: surgeries,
                        label: 'Surgeries',
                        onChanged: (v) =>
                            setDialogState(() => surgeries = v ?? false),
                        trailing: DropdownButtonFormField<String>(
                          value: surgeryValue,
                          items: const [
                            DropdownMenuItem(
                              value: 'Recent surgeries',
                              child: Text('Recent surgeries'),
                            ),
                            DropdownMenuItem(
                              value: 'Recent abdominal surgery',
                              child: Text('Recent abdominal surgery'),
                            ),
                            DropdownMenuItem(
                              value: 'Thoracic surgery',
                              child: Text('Thoracic surgery'),
                            ),
                          ],
                          onChanged: surgeries
                              ? (v) => setDialogState(
                                    () => surgeryValue =
                                        v ?? 'Recent surgeries',
                                  )
                              : null,
                          decoration: _inputDecoration('Surgeries'),
                        ),
                      ),
                      checkboxRow(
                        value: priorMedications,
                        label: 'Prior Medications',
                        onChanged: (v) => setDialogState(
                          () => priorMedications = v ?? false,
                        ),
                        trailing: TextField(
                          controller: priorMedicationsController,
                          enabled: priorMedications,
                          decoration: _inputDecoration('Prior Medications'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Criteria updated'),
                                ),
                              );
                            },
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
