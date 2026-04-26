import 'package:flutter/material.dart';

class PharmaceuticalsClinicalTrialAddPage extends StatefulWidget {
  const PharmaceuticalsClinicalTrialAddPage({super.key});

  @override
  State<PharmaceuticalsClinicalTrialAddPage> createState() =>
      _PharmaceuticalsClinicalTrialAddPageState();
}

class _PharmaceuticalsClinicalTrialAddPageState
    extends State<PharmaceuticalsClinicalTrialAddPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneCodeController =
      TextEditingController(text: '+1');
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final TextEditingController trialNameController = TextEditingController();
  final TextEditingController trialIdController = TextEditingController();
  final TextEditingController officialTitleController = TextEditingController();

  final TextEditingController briefSummaryController = TextEditingController();
  final TextEditingController detailedDescriptionController =
      TextEditingController();

  final TextEditingController sponsorController = TextEditingController();
  final TextEditingController principalInvestigatorController =
      TextEditingController();
  final TextEditingController ethicsApprovalController =
      TextEditingController();

  final TextEditingController relatedConditionsController =
      TextEditingController();
  final TextEditingController minAgeController = TextEditingController();
  final TextEditingController maxAgeController = TextEditingController();

  final TextEditingController minBMIController = TextEditingController();
  final TextEditingController maxBMIController = TextEditingController();
  final TextEditingController priorMedicationsController =
      TextEditingController();

  String selectedCountry = 'Canada';
  String selectedRegion = 'Ontario';

  String primaryPurpose = '';
  String trialPhase = '';
  String studyType = '';
  String allocation = '';
  String interventionModel = '';
  String masking = '';

  bool maskingParticipant = false;
  bool maskingInvestigator = false;

  DateTime? startDate;
  DateTime? endDate;

  String pathology = '';
  String gender = '';
  String diseases = '';
  String surgeries = '';
  String pregnancy = '';

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    phoneCodeController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    trialNameController.dispose();
    trialIdController.dispose();
    officialTitleController.dispose();
    briefSummaryController.dispose();
    detailedDescriptionController.dispose();
    sponsorController.dispose();
    principalInvestigatorController.dispose();
    ethicsApprovalController.dispose();
    relatedConditionsController.dispose();
    minAgeController.dispose();
    maxAgeController.dispose();
    minBMIController.dispose();
    maxBMIController.dispose();
    priorMedicationsController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD6DCE8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD6DCE8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1E4ED8)),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E4ED8),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(hint),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: _inputDecoration(hint),
      items: items
          .map(
            (e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2026, 1, 1),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  String _dateText(DateTime? date) {
    if (date == null) return 'YYYY/MM/DD';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _bmiCondition() {
    final min = minBMIController.text.trim();
    final max = maxBMIController.text.trim();

    if (min.isEmpty && max.isEmpty) return '> 1 and < 99';
    if (min.isNotEmpty && max.isNotEmpty) {
      final minVal = double.tryParse(min);
      final maxVal = double.tryParse(max);
      if (minVal != null && maxVal != null) {
        return minVal > maxVal ? '> $min or < $max' : '> $min and < $max';
      }
    }
    if (min.isNotEmpty) return '> $min';
    return '< $max';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Clinical trial created successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pages / Clinical Trial / Add',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9AA3B2),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Contact Information'),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('First Name'),
                                  _textField(
                                    controller: firstNameController,
                                    hint: 'Enter First Name',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Middle Name'),
                                  TextFormField(
                                    controller: middleNameController,
                                    decoration:
                                        _inputDecoration('Enter Middle Name'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Last Name'),
                                  _textField(
                                    controller: lastNameController,
                                    hint: 'Enter Last Name',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Phone Code'),
                                  _textField(
                                    controller: phoneCodeController,
                                    hint: '+1',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Phone Number'),
                                  _textField(
                                    controller: phoneNumberController,
                                    hint: 'Enter Phone Number',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Email'),
                            _textField(
                              controller: emailController,
                              hint: 'Enter Email Address',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Trial Basic Information'),
                        const SizedBox(height: 18),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Trial Name'),
                            _textField(
                              controller: trialNameController,
                              hint: 'Enter Trial Name',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Trial ID'),
                                  _textField(
                                    controller: trialIdController,
                                    hint: 'Enter Trial ID',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Country'),
                                  _dropdown(
                                    value: selectedCountry,
                                    items: const [
                                      'Canada',
                                      'United States',
                                      'United Kingdom'
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCountry = value ?? 'Canada';
                                      });
                                    },
                                    hint: 'Country',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Region'),
                            _dropdown(
                              value: selectedRegion,
                              items: const [
                                'Ontario',
                                'Quebec',
                                'British Columbia'
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedRegion = value ?? 'Ontario';
                                });
                              },
                              hint: 'Region',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Official Title'),
                            _textField(
                              controller: officialTitleController,
                              hint: 'Enter Official Title',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Brief Summary'),
                        const SizedBox(height: 18),
                        _textField(
                          controller: briefSummaryController,
                          hint: 'Enter Brief Summary',
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 6,
                  child: _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Detailed Description'),
                        const SizedBox(height: 18),
                        _textField(
                          controller: detailedDescriptionController,
                          hint: 'Enter Detailed Description',
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Trial Details'),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Primary Purpose'),
                                      _dropdown(
                                        value: primaryPurpose,
                                        items: const [
                                          'Treatment',
                                          'Prevention',
                                          'Diagnostic',
                                          'Supportive Care'
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            primaryPurpose = value ?? '';
                                          });
                                        },
                                        hint: 'Purpose',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Trial Phase'),
                                      _dropdown(
                                        value: trialPhase,
                                        items: const [
                                          'Phase I',
                                          'Phase II',
                                          'Phase III',
                                          'Phase IV'
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            trialPhase = value ?? '';
                                          });
                                        },
                                        hint: 'Phase',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Study Type'),
                                      _dropdown(
                                        value: studyType,
                                        items: const [
                                          'Interventional',
                                          'Observational'
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            studyType = value ?? '';
                                          });
                                        },
                                        hint: 'Type',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Allocation'),
                                      _dropdown(
                                        value: allocation,
                                        items: const [
                                          'Randomized',
                                          'Non-randomized'
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            allocation = value ?? '';
                                          });
                                        },
                                        hint: 'Allocation',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Intervention Model'),
                                      _dropdown(
                                        value: interventionModel,
                                        items: const [
                                          'Single Group',
                                          'Parallel',
                                          'Crossover'
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            interventionModel = value ?? '';
                                          });
                                        },
                                        hint: 'Model',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Masking'),
                                      _dropdown(
                                        value: masking,
                                        items: const [
                                          'None (Open Label)',
                                          'Single',
                                          'Double'
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            masking = value ?? '';
                                          });
                                        },
                                        hint: 'Masking',
                                      ),
                                      if (masking == 'Single' ||
                                          masking == 'Double') ...[
                                        const SizedBox(height: 8),
                                        CheckboxListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          value: maskingParticipant,
                                          onChanged: (value) {
                                            setState(() {
                                              maskingParticipant =
                                                  value ?? false;
                                            });
                                          },
                                          title: const Text('Participant'),
                                        ),
                                        CheckboxListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          value: maskingInvestigator,
                                          onChanged: (value) {
                                            setState(() {
                                              maskingInvestigator =
                                                  value ?? false;
                                            });
                                          },
                                          title: const Text('Investigator'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Start Date'),
                                      InkWell(
                                        onTap: () => _pickDate(true),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(0xFFD6DCE8),
                                            ),
                                          ),
                                          child: Text(_dateText(startDate)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('End Date'),
                                      InkWell(
                                        onTap: () => _pickDate(false),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(0xFFD6DCE8),
                                            ),
                                          ),
                                          child: Text(_dateText(endDate)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Sponsor'),
                                      _textField(
                                        controller: sponsorController,
                                        hint: 'Enter Sponsor Details',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Principal Investigator'),
                                      _textField(
                                        controller:
                                            principalInvestigatorController,
                                        hint: 'Enter Principal Investigator',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Ethics Approval'),
                                _textField(
                                  controller: ethicsApprovalController,
                                  hint: 'Enter Ethics Approval Details',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Inclusion Criteria'),
                        const SizedBox(height: 18),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Related Conditions'),
                            _textField(
                              controller: relatedConditionsController,
                              hint: 'Enter Related Conditions',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Pathology'),
                                  _dropdown(
                                    value: pathology,
                                    items: const [
                                      'Hypertension',
                                      'Type 2 Diabetes',
                                      'Asthma'
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        pathology = value ?? '';
                                      });
                                    },
                                    hint: 'Pathology',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Gender'),
                                  _dropdown(
                                    value: gender,
                                    items: const ['Male', 'Female', 'Both'],
                                    onChanged: (value) {
                                      setState(() {
                                        gender = value ?? '';
                                      });
                                    },
                                    hint: 'Gender',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Age Range (Min)'),
                                  _textField(
                                    controller: minAgeController,
                                    hint: 'Min Age',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Age Range (Max)'),
                                  _textField(
                                    controller: maxAgeController,
                                    hint: 'Max Age',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Exclusion Criteria'),
                        const SizedBox(height: 18),
                        _label('BMI Range'),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                controller: minBMIController,
                                hint: 'Min BMI',
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _textField(
                                controller: maxBMIController,
                                hint: 'Max BMI',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _bmiCondition(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Diseases'),
                            _dropdown(
                              value: diseases,
                              items: const [
                                'Cardiovascular Diseases',
                                'Endocrine Diseases',
                                'Respiratory Diseases',
                                'Digestive Diseases',
                                'Renal Disease',
                                'Neurological Diseases',
                                'Immunological Diseases',
                                'Infectious Diseases',
                                'Cancer',
                                'Liver Disease',
                                'Dermatological Diseases',
                                'Musculoskeletal Diseases',
                                'Mental Health Disorders',
                              ],
                              onChanged: (value) {
                                setState(() {
                                  diseases = value ?? '';
                                });
                              },
                              hint: 'Diseases',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Surgeries'),
                            _dropdown(
                              value: surgeries,
                              items: const [
                                'Recent surgeries',
                                'Recent abdominal surgery',
                                'Recent brain surgery',
                                'Thoracic surgery',
                                'Recent lung surgery',
                                'Joint replacement surgery',
                                'Recent joint surgery',
                                'Recent breast surgery',
                                'Recent thoracic surgery',
                                'Recent bowel surgery',
                              ],
                              onChanged: (value) {
                                setState(() {
                                  surgeries = value ?? '';
                                });
                              },
                              hint: 'Surgeries',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Prior Medications'),
                            _textField(
                              controller: priorMedicationsController,
                              hint: 'Enter Prior Medications',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Pregnancy'),
                            _dropdown(
                              value: pregnancy,
                              items: const ['Yes', 'No', 'Unrestricted'],
                              onChanged: (value) {
                                setState(() {
                                  pregnancy = value ?? '';
                                });
                              },
                              hint: 'Pregnancy',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E4ED8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Create Trials',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
