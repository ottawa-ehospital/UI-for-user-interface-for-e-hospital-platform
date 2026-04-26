import 'package:flutter/material.dart';

class PharmaceuticalsInventoryPage extends StatefulWidget {
  const PharmaceuticalsInventoryPage({super.key});

  @override
  State<PharmaceuticalsInventoryPage> createState() =>
      _PharmaceuticalsInventoryPageState();
}

class _PharmaceuticalsInventoryPageState
    extends State<PharmaceuticalsInventoryPage> {
  final List<_MedicineItem> medicines = const [
    _MedicineItem(medicineName: 'Aspirin', stock: 12, useIndication: 'Pain relief'),
    _MedicineItem(medicineName: 'Amoxicillin', stock: 7, useIndication: 'Antibiotic'),
    _MedicineItem(medicineName: 'Metformin', stock: 15, useIndication: 'Type 2 diabetes'),
    _MedicineItem(medicineName: 'Atorvastatin', stock: 9, useIndication: 'Cholesterol control'),
  ];

  int get totalStock => medicines.fold(0, (sum, item) => sum + item.stock);

  void _showNewInventoryDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => const _NewInventoryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pages / Inventory',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9AA3B2),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pharmacy Dashboard',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E263B),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: _showNewInventoryDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: const Text(
                          'New',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Total: $totalStock',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E263B),
                  ),
                ),
                const SizedBox(height: 18),
                _InventoryTable(medicines: medicines),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryTable extends StatelessWidget {
  final List<_MedicineItem> medicines;

  const _InventoryTable({required this.medicines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E4ED8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Medicine Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                Expanded(flex: 2, child: Text('Stock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                Expanded(flex: 3, child: Text('Use Indication', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                Expanded(flex: 2, child: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
              ],
            ),
          ),
          ...List.generate(medicines.length, (index) {
            final item = medicines[index];
            final isEven = index % 2 == 0;
            return Container(
              color: isEven ? const Color(0xFFF3F4F6) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(item.medicineName, style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 2, child: Text(item.stock.toString(), style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 3, child: Text(item.useIndication, style: const TextStyle(fontSize: 13))),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: const Text('Delete', style: TextStyle(fontSize: 12)),
                        ),
                      ),
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
}

class _NewInventoryDialog extends StatelessWidget {
  const _NewInventoryDialog();

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E4ED8))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Medicine', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 18),
                  TextField(decoration: _inputDecoration('Medicine Name')),
                  const SizedBox(height: 14),
                  TextField(decoration: _inputDecoration('Manufacturer')),
                  const SizedBox(height: 14),
                  TextField(decoration: _inputDecoration('Dosage')),
                  const SizedBox(height: 14),
                  TextField(decoration: _inputDecoration('Expiry Date')),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          child: const Text('Add Medicine'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF4B5563)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineItem {
  final String medicineName;
  final int stock;
  final String useIndication;

  const _MedicineItem({
    required this.medicineName,
    required this.stock,
    required this.useIndication,
  });
}
