import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class BillingScreen extends StatefulWidget {
  final String doctorId;
  const BillingScreen({super.key, required this.doctorId});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  int selectedTab = 1; // 0 = New Bill, 1 = Bills
  List<Bill> bills = [];
  bool isLoading = true;

  // Pagination for desktop table
  int rowsPerPage = 10;
  int currentPage = 0;

  bool get _isWide => MediaQuery.of(context).size.width >= 900;
  bool get _isCompact => MediaQuery.of(context).size.width < 700;

  double get _pagePadding => _isCompact ? 12 : 24;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() => isLoading = true);
    try {
      final String response = await rootBundle.loadString('assets/data/bills.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        bills = data.map((e) => Bill.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error loading bills: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(_pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Billing Management",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 18),

                  _TabsRow(
                    isCompact: _isCompact,
                    selected: selectedTab,
                    onSelect: (i) => setState(() => selectedTab = i),
                  ),
                  const SizedBox(height: 18),

                  if (selectedTab == 0)
                    NewBillForm(doctorId: widget.doctorId)
                  else
                    BillsListView(
                      bills: bills,
                      isLoading: isLoading,
                      wide: _isWide,
                      rowsPerPage: rowsPerPage,
                      currentPage: currentPage,
                      onRowsPerPageChanged: (v) {
                        setState(() {
                          rowsPerPage = v;
                          currentPage = 0;
                        });
                      },
                      onPageChanged: (p) => setState(() => currentPage = p),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabsRow extends StatelessWidget {
  final bool isCompact;
  final int selected;
  final ValueChanged<int> onSelect;

  const _TabsRow({
    required this.isCompact,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    Widget button({
      required IconData icon,
      required String label,
      required bool active,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF3F51B5) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? const Color(0xFF3F51B5) : const Color(0xFFE5E7EB)),
            boxShadow: [
              if (!active)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: active ? Colors.white : const Color(0xFF3F51B5)),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : const Color(0xFF3F51B5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isCompact) {
      return Column(
        children: [
          button(
            icon: Icons.receipt_long,
            label: "New Bill",
            active: selected == 0,
            onTap: () => onSelect(0),
          ),
          const SizedBox(height: 12),
          button(
            icon: Icons.medical_information,
            label: "Bills",
            active: selected == 1,
            onTap: () => onSelect(1),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: button(
            icon: Icons.receipt_long,
            label: "New Bill",
            active: selected == 0,
            onTap: () => onSelect(0),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: button(
            icon: Icons.medical_information,
            label: "Bills",
            active: selected == 1,
            onTap: () => onSelect(1),
          ),
        ),
      ],
    );
  }
}

// -------------------- New Bill Form --------------------

class NewBillForm extends StatefulWidget {
  final String doctorId;
  const NewBillForm({super.key, required this.doctorId});

  @override
  State<NewBillForm> createState() => _NewBillFormState();
}

class _NewBillFormState extends State<NewBillForm> {
  final _formKey = GlobalKey<FormState>();

  String billType = 'OHIP';
  DateTime selectedDate = DateTime.now();

  final _patientNameController = TextEditingController();
  final _ohipNumberController = TextEditingController();
  final _serviceCodeController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? selectedService;
  final List<BillItem> billItems = [];

  bool get _isCompact => MediaQuery.of(context).size.width < 700;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create New Bill",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF3F51B5)),
            ),
            const SizedBox(height: 18),

            const Text("Bill Type", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _RadioChip(
                  label: "OHIP",
                  selected: billType == "OHIP",
                  onTap: () => setState(() => billType = "OHIP"),
                ),
                _RadioChip(
                  label: "Private",
                  selected: billType == "Private",
                  onTap: () => setState(() => billType = "Private"),
                ),
              ],
            ),

            const SizedBox(height: 18),
            _label("Patient Name*"),
            const SizedBox(height: 8),
            TextFormField(
              controller: _patientNameController,
              decoration: _inputDecoration("Enter patient name"),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
            ),

            const SizedBox(height: 18),
            _label("Date"),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) setState(() => selectedDate = date);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(DateFormat('yyyy-MM-dd').format(selectedDate))),
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6B7280)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),
            const Text(
              "OHIP Billing Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF3F51B5)),
            ),
            const SizedBox(height: 14),

            // Responsive fields
            if (_isCompact) ...[
              _ohipNumberField(),
              const SizedBox(height: 14),
              _serviceDropdown(),
              const SizedBox(height: 14),
              _serviceCodeField(),
              const SizedBox(height: 14),
              _amountField(),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _ohipNumberField()),
                  const SizedBox(width: 16),
                  Expanded(child: _serviceDropdown()),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _serviceCodeField()),
                  const SizedBox(width: 16),
                  Expanded(child: _amountField()),
                ],
              ),
            ],

            const SizedBox(height: 18),
            _label("Note"),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: _inputDecoration("Enter note (optional)"),
            ),

            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: _addBillItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("ADD OHIP ITEM"),
              ),
            ),

            const SizedBox(height: 18),
            const Text("Bill Preview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),

            // Preview table that NEVER overflows
            _PreviewTable(
              items: billItems,
              onRemove: (it) => setState(() => billItems.remove(it)),
              total: _calculateTotal(),
            ),

            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _submitBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Submit Bill", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ohipNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("OHIP Number*"),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ohipNumberController,
          decoration: _inputDecoration("Enter OHIP number"),
        ),
      ],
    );
  }

  Widget _serviceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Service*"),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedService,
          isExpanded: true,
          decoration: _inputDecoration("Search or select service"),
          items: const ['Consultation', 'Surgery', 'Lab Test', 'X-Ray', 'Vaccination']
              .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (v) => setState(() => selectedService = v),
        ),
      ],
    );
  }

  Widget _serviceCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Service Code*"),
        const SizedBox(height: 8),
        TextFormField(
          controller: _serviceCodeController,
          decoration: _inputDecoration("e.g. A001"),
        ),
      ],
    );
  }

  Widget _amountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Amount*"),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration("e.g. 25.00"),
        ),
        const SizedBox(height: 6),
        Text(
          "Amount can be set based on service",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700));

  void _addBillItem() {
    if (_serviceCodeController.text.trim().isEmpty || _amountController.text.trim().isEmpty) return;

    final unitPrice = double.tryParse(_amountController.text.trim());
    if (unitPrice == null) return;

    setState(() {
      billItems.add(
        BillItem(
          code: _serviceCodeController.text.trim(),
          description: selectedService ?? 'Service',
          unitPrice: unitPrice,
          unit: 1,
        ),
      );
      _serviceCodeController.clear();
      _amountController.clear();
      selectedService = null;
    });
  }

  double _calculateTotal() => billItems.fold(0, (sum, it) => sum + it.unitPrice * it.unit);

  void _submitBill() {
    final ok = (_formKey.currentState?.validate() ?? false) && billItems.isNotEmpty;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill required fields and add at least one item')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bill submitted successfully')),
    );

    _patientNameController.clear();
    _ohipNumberController.clear();
    _noteController.clear();

    setState(() {
      billItems.clear();
      selectedDate = DateTime.now();
    });
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _ohipNumberController.dispose();
    _serviceCodeController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}

class _RadioChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RadioChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? const Color(0xFFEEF2FF) : Colors.white,
          border: Border.all(color: selected ? const Color(0xFF3F51B5) : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18, color: selected ? const Color(0xFF3F51B5) : const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _PreviewTable extends StatelessWidget {
  final List<BillItem> items;
  final ValueChanged<BillItem> onRemove;
  final double total;

  const _PreviewTable({required this.items, required this.onRemove, required this.total});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        // horizontal scroll always safe, table has a minimum width
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  DataTable(
                    headingRowHeight: 48,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 60,
                    columnSpacing: 24,
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                    columns: const [
                      DataColumn(label: Text("Code")),
                      DataColumn(label: Text("Description")),
                      DataColumn(label: Text("Unit Price")),
                      DataColumn(label: Text("Unit")),
                      DataColumn(label: Text("")),
                    ],
                    rows: items.isEmpty
                        ? const []
                        : items.map((it) {
                            return DataRow(
                              cells: [
                                DataCell(Text(it.code)),
                                DataCell(SizedBox(width: 220, child: Text(it.description, overflow: TextOverflow.ellipsis))),
                                DataCell(Text("\$${it.unitPrice.toStringAsFixed(2)}")),
                                DataCell(Text("${it.unit}")),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => onRemove(it),
                                    tooltip: "Remove",
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                  ),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(18),
                      child: Text("No items added yet", style: TextStyle(color: Color(0xFF6B7280))),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text("Total:", style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(width: 12),
                        Text(
                          "\$${total.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3F51B5), fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// -------------------- Bills List (Cards on mobile, Table on desktop) --------------------

class BillsListView extends StatelessWidget {
  final List<Bill> bills;
  final bool isLoading;
  final bool wide;

  final int rowsPerPage;
  final int currentPage;
  final ValueChanged<int> onRowsPerPageChanged;
  final ValueChanged<int> onPageChanged;

  const BillsListView({
    super.key,
    required this.bills,
    required this.isLoading,
    required this.wide,
    required this.rowsPerPage,
    required this.currentPage,
    required this.onRowsPerPageChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Bills", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          if (isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (bills.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text("No bills found", style: TextStyle(color: Color(0xFF6B7280))),
            )
          else
            wide ? _DesktopBillsTable(
              bills: bills,
              rowsPerPage: rowsPerPage,
              currentPage: currentPage,
              onRowsPerPageChanged: onRowsPerPageChanged,
              onPageChanged: onPageChanged,
            ) : _MobileBillsCards(bills: bills),
        ],
      ),
    );
  }
}

class _MobileBillsCards extends StatelessWidget {
  final List<Bill> bills;
  const _MobileBillsCards({required this.bills});

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: shrinkWrap + no scroll physics because parent is SingleChildScrollView
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bills.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final b = bills[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('MMM dd, yyyy').format(b.date), style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              _kv("Time", b.time),
              _kv("Doctor", b.doctor),
              _kv("Patient", b.patient),
              _kv("Type", b.type),
              _kv("Notes", b.notes.isEmpty ? "-" : b.notes),
              _kv("Codes", b.codes.join(", ")),
            ],
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: Text(k, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Expanded(child: Text(v, maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _DesktopBillsTable extends StatelessWidget {
  final List<Bill> bills;
  final int rowsPerPage;
  final int currentPage;
  final ValueChanged<int> onRowsPerPageChanged;
  final ValueChanged<int> onPageChanged;

  const _DesktopBillsTable({
    required this.bills,
    required this.rowsPerPage,
    required this.currentPage,
    required this.onRowsPerPageChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final startIndex = currentPage * rowsPerPage;
    final endIndex = (startIndex + rowsPerPage > bills.length) ? bills.length : (startIndex + rowsPerPage);
    final pageBills = bills.sublist(startIndex, endIndex);

    return Column(
      children: [
        LayoutBuilder(
          builder: (_, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowHeight: 48,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 60,
                  columnSpacing: 22,
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                  columns: const [
                    DataColumn(label: Text("Date")),
                    DataColumn(label: Text("Time")),
                    DataColumn(label: Text("Doctor")),
                    DataColumn(label: Text("Patient")),
                    DataColumn(label: Text("Type")),
                    DataColumn(label: Text("Notes")),
                    DataColumn(label: Text("Codes")),
                  ],
                  rows: pageBills.map((b) {
                    return DataRow(
                      cells: [
                        DataCell(Text(DateFormat('MMM dd, yyyy').format(b.date))),
                        DataCell(Text(b.time)),
                        DataCell(SizedBox(width: 160, child: Text(b.doctor, overflow: TextOverflow.ellipsis))),
                        DataCell(SizedBox(width: 160, child: Text(b.patient, overflow: TextOverflow.ellipsis))),
                        DataCell(Text(b.type)),
                        DataCell(SizedBox(width: 220, child: Text(b.notes, maxLines: 1, overflow: TextOverflow.ellipsis))),
                        DataCell(SizedBox(width: 220, child: Text(b.codes.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Pagination
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text("Rows per page:", style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            DropdownButton<int>(
              value: rowsPerPage,
              items: const [10, 25, 50]
                  .map((v) => DropdownMenuItem(value: v, child: Text("$v")))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                onRowsPerPageChanged(v);
              },
            ),
            const SizedBox(width: 18),
            Text("${startIndex + 1}–$endIndex of ${bills.length}", style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: endIndex < bills.length ? () => onPageChanged(currentPage + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

// -------------------- Models --------------------

class Bill {
  final String id;
  final DateTime date;
  final String time;
  final String doctor;
  final String patient;
  final String type;
  final String notes;
  final List<String> codes;

  Bill({
    required this.id,
    required this.date,
    required this.time,
    required this.doctor,
    required this.patient,
    required this.type,
    required this.notes,
    required this.codes,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id']?.toString() ?? '',
      date: DateTime.parse(json['date']),
      time: json['time'] ?? '',
      doctor: json['doctor'] ?? '',
      patient: json['patient'] ?? '',
      type: json['type'] ?? '',
      notes: json['notes'] ?? '',
      codes: List<String>.from(json['codes'] ?? const []),
    );
  }
}

class BillItem {
  final String code;
  final String description;
  final double unitPrice;
  final int unit;

  BillItem({
    required this.code,
    required this.description,
    required this.unitPrice,
    required this.unit,
  });
}
