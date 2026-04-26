import 'package:flutter/material.dart';

class TrialPatientsTable extends StatelessWidget {
  const TrialPatientsTable({super.key});

  @override
  Widget build(BuildContext context) {
    final patients = [
      _TrialPatientItem(
        patientId: 201,
        patientName: 'Alice Johnson',
        status: 'Enrolled',
        date: '2026-02-10',
        doctors: ['Dr Smith', 'Dr Wilson'],
      ),
      _TrialPatientItem(
        patientId: 202,
        patientName: 'Michael Brown',
        status: 'Inviting',
        date: '2026-02-18',
        doctors: ['Dr Lee'],
      ),
      _TrialPatientItem(
        patientId: 203,
        patientName: 'Sophia Davis',
        status: 'Applying',
        date: '2026-03-01',
        doctors: ['Dr Taylor', 'Dr White'],
      ),
      _TrialPatientItem(
        patientId: 204,
        patientName: 'Daniel Clark',
        status: 'Enrolled',
        date: '2026-03-04',
        doctors: ['Dr Adams'],
      ),
      _TrialPatientItem(
        patientId: 205,
        patientName: 'Emma Harris',
        status: 'Inviting',
        date: '2026-03-06',
        doctors: ['Dr Brown'],
      ),
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
                'Partnership Patients',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E4ED8),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit page placeholder')),
                  );
                },
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TrialPatientsHeader(),
          ...List.generate(patients.length, (index) {
            final item = patients[index];
            final isEven = index % 2 == 0;
            return _TrialPatientsRow(
              item: item,
              backgroundColor:
                  isEven ? const Color(0xFFF9FAFB) : Colors.white,
            );
          }),
        ],
      ),
    );
  }
}

class _TrialPatientsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Date',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Doctor Name',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrialPatientsRow extends StatelessWidget {
  final _TrialPatientItem item;
  final Color backgroundColor;

  const _TrialPatientsRow({
    required this.item,
    required this.backgroundColor,
  });

  Color _statusBg(String status) {
    switch (status) {
      case 'Inviting':
        return const Color(0xFFFFE7C2);
      case 'Applying':
        return const Color(0xFFDCEBFF);
      case 'Enrolled':
        return const Color(0xFFDDF4DE);
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  Color _statusFg(String status) {
    switch (status) {
      case 'Inviting':
        return const Color(0xFFB26A00);
      case 'Applying':
        return const Color(0xFF1565C0);
      case 'Enrolled':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF374151);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Open patient ${item.patientName}'),
                  ),
                );
              },
              child: Text(
                item.patientName,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusBg(item.status),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    color: _statusFg(item.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.date,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: item.doctors
                  .map(
                    (doctor) => InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Open doctor $doctor')),
                        );
                      },
                      child: Text(
                        doctor,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrialPatientItem {
  final int patientId;
  final String patientName;
  final String status;
  final String date;
  final List<String> doctors;

  const _TrialPatientItem({
    required this.patientId,
    required this.patientName,
    required this.status,
    required this.date,
    required this.doctors,
  });
}
