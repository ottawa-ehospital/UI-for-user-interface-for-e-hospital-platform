import 'package:flutter/material.dart';

class PharmaceuticalsPrescriptionsPage extends StatelessWidget {
  const PharmaceuticalsPrescriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const prescriptions = [
      _PrescriptionItem(id: 1001, patientName: 'John Smith', medicineName: 'Aspirin', dosage: '100 mg', expiryDate: '2026-12-31'),
      _PrescriptionItem(id: 1002, patientName: 'Emily Johnson', medicineName: 'Metformin', dosage: '500 mg', expiryDate: '2027-03-15'),
      _PrescriptionItem(id: 1003, patientName: 'Michael Brown', medicineName: 'Amoxicillin', dosage: '250 mg', expiryDate: '2026-09-20'),
      _PrescriptionItem(id: 1004, patientName: 'Sophia Davis', medicineName: 'Atorvastatin', dosage: '20 mg', expiryDate: '2027-01-08'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pages / Prescriptions',
            style: TextStyle(fontSize: 12, color: Color(0xFF9AA3B2), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prescription Dashboard', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF1E263B))),
                const SizedBox(height: 16),
                Text('Total Prescriptions: ${prescriptions.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
                const SizedBox(height: 18),
                _PrescriptionsTable(items: prescriptions),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionsTable extends StatelessWidget {
  final List<_PrescriptionItem> items;

  const _PrescriptionsTable({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1D5DB)), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: const BoxDecoration(color: Color(0xFF1E4ED8), borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Prescription ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                Expanded(flex: 3, child: Text('Patient Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                Expanded(flex: 3, child: Text('Medicine Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                Expanded(flex: 2, child: Text('Dosage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                Expanded(flex: 3, child: Text('Expiry Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
              ],
            ),
          ),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final isEven = index % 2 == 0;
            return Container(
              color: isEven ? const Color(0xFFF3F4F6) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(item.id.toString(), style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 3, child: Text(item.patientName, style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 3, child: Text(item.medicineName, style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 2, child: Text(item.dosage, style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 3, child: Text(item.expiryDate, style: const TextStyle(fontSize: 13))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PrescriptionItem {
  final int id;
  final String patientName;
  final String medicineName;
  final String dosage;
  final String expiryDate;

  const _PrescriptionItem({
    required this.id,
    required this.patientName,
    required this.medicineName,
    required this.dosage,
    required this.expiryDate,
  });
}
