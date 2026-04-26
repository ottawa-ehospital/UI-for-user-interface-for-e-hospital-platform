import 'package:flutter/material.dart';

class PharmaceuticalsClinicalTrialPage extends StatelessWidget {
  const PharmaceuticalsClinicalTrialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final trials = [
      {
        "name": "Evaluation of ZE-504 for Migraine Prevention",
        "id": "101",
        "condition": "Migraine",
        "phase": "Phase III",
        "type": "Interventional",
        "location": "Ottawa",
        "investigator": "Dr Smith",
        "sponsor": "ZE Pharma",
        "ethics": "Approved",
        "status": "Under Review"
      },
      {
        "name": "Double-Blind Trial of NK-505 for Rheumatoid Arthritis",
        "id": "102",
        "condition": "Arthritis",
        "phase": "Phase II",
        "type": "Interventional",
        "location": "Toronto",
        "investigator": "Dr Wilson",
        "sponsor": "NK Labs",
        "ethics": "Approved",
        "status": "Ongoing"
      },
      {
        "name": "Comparative Study of AB-606 vs Standard Care",
        "id": "103",
        "condition": "Diabetes",
        "phase": "Phase III",
        "type": "Interventional",
        "location": "Montreal",
        "investigator": "Dr Lee",
        "sponsor": "AB Pharma",
        "ethics": "Approved",
        "status": "Completed"
      }
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    "Clinical Trial List",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E4ED8),
                    ),
                  ),
                  Spacer(),
                ],
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 30,
                  columns: const [
                    DataColumn(label: Text("Name")),
                    DataColumn(label: Text("Id")),
                    DataColumn(label: Text("Conditions")),
                    DataColumn(label: Text("Phase")),
                    DataColumn(label: Text("Type")),
                    DataColumn(label: Text("Location")),
                    DataColumn(label: Text("Investigator")),
                    DataColumn(label: Text("Sponsor")),
                    DataColumn(label: Text("Ethics")),
                    DataColumn(label: Text("Status")),
                  ],
                  rows: trials.map((trial) {
                    return DataRow(
                      cells: [
                        DataCell(Text(trial["name"]!)),
                        DataCell(Text(trial["id"]!)),
                        DataCell(Text(trial["condition"]!)),
                        DataCell(Text(trial["phase"]!)),
                        DataCell(Text(trial["type"]!)),
                        DataCell(Text(trial["location"]!)),
                        DataCell(Text(trial["investigator"]!)),
                        DataCell(Text(trial["sponsor"]!)),
                        DataCell(Text(trial["ethics"]!)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(trial["status"]!),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              trial["status"]!,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case "Under Review":
        return Colors.orange;
      case "Ongoing":
        return Colors.blue;
      case "Completed":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
