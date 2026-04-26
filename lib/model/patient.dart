class Patient {
  final int id;
  final String firstName;
  final String middleInitial;
  final String lastName;
  final String phone;
  final int? age;
  final String gender;

  // UI columns you want
  final String status; // Active / Inactive
  final DateTime? lastAppointment;
  final String lastDiagnosis;

  const Patient({
    required this.id,
    required this.firstName,
    required this.middleInitial,
    required this.lastName,
    required this.phone,
    required this.age,
    required this.gender,
    required this.status,
    required this.lastAppointment,
    required this.lastDiagnosis,
  });

  String get fullName {
    final mi = middleInitial.trim();
    if (mi.isEmpty) return "$firstName $lastName";
    return "$firstName $mi $lastName";
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? "") ?? 0;
  }

  static DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s); // supports YYYY-MM-DD or full ISO
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: _parseInt(json["id"] ?? json["patientId"] ?? json["PatientID"]),
      firstName: (json["FName"] ?? json["firstName"] ?? "").toString(),
      middleInitial: (json["MI"] ?? json["middleInitial"] ?? "").toString(),
      lastName: (json["LName"] ?? json["lastName"] ?? "").toString(),
      phone: (json["MobileNumber"] ?? json["phone"] ?? "").toString(),
      age: json["Age"] == null ? null : _parseInt(json["Age"]),
      gender: (json["Gender"] ?? json["gender"] ?? "").toString(),

      // These may not be returned by your API yet, so safe defaults:
      status: (json["Status"] ?? json["status"] ?? "Active").toString(),
      lastAppointment: _tryParseDate(
        json["LastAppointment"] ?? json["lastAppointment"],
      ),
      lastDiagnosis: (json["LastDiagnosis"] ?? json["lastDiagnosis"] ?? "-")
          .toString(),
    );
  }

  Patient copyWith({
    String? status,
    DateTime? lastAppointment,
    String? lastDiagnosis,
  }) {
    return Patient(
      id: id,
      firstName: firstName,
      middleInitial: middleInitial,
      lastName: lastName,
      phone: phone,
      age: age,
      gender: gender,
      status: status ?? this.status,
      lastAppointment: lastAppointment ?? this.lastAppointment,
      lastDiagnosis: lastDiagnosis ?? this.lastDiagnosis,
    );
  }
}
