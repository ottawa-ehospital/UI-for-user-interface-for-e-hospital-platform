import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ehosptal_flutter_revamp/model/patient.dart';
import 'package:ehosptal_flutter_revamp/model/message_models.dart';

class ApiService {
  static const String baseUrl =
      "https://tysnx3mi2s.us-east-1.awsapprunner.com";

  static const Duration _timeout = Duration(seconds: 20);

  static const Map<String, String> _headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final url = Uri.parse("$baseUrl/api/users/login");
    final response = await http
        .post(url, headers: _headers,
            body: jsonEncode({"email": email, "password": password, "selectedOption": role}))
        .timeout(_timeout);
    _ensureSuccess(response, "Login failed");
    final decoded = _decodeJson(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception("Login failed: unexpected response format: ${response.body}");
  }

  Future<List<Patient>> getDoctorPatientsAuthorized({required dynamic doctorId}) async {
    if (doctorId == null) throw Exception("doctorId is null.");
    final url = Uri.parse("$baseUrl/DoctorPatientsAuthorized");
    final response = await http
        .post(url, headers: _headers, body: jsonEncode({
          "doctorId": doctorId,
          "doctor_id": doctorId,
        }))
        .timeout(_timeout);
    _ensureSuccess(response, "getDoctorPatientsAuthorized failed");
    final decoded = _decodeJson(response.body);
    if (decoded is List) return decoded.whereType<Map<String, dynamic>>().map(Patient.fromJson).toList();
    if (decoded is Map<String, dynamic>) {
      final list = decoded["result"] ?? decoded["data"];
      if (list is List) return list.whereType<Map<String, dynamic>>().map(Patient.fromJson).toList();
    }
    throw Exception("Unexpected response format: ${response.body}");
  }

  Future<List<Map<String, dynamic>>> getDoctorCalendar({
    required Map<String, dynamic> loginData,
    required DateTime start,
    required DateTime end,
  }) async {
    final url = Uri.parse("$baseUrl/api/appointments/doctorGetCalendar");
    final res = await http.post(url, headers: _headers, body: jsonEncode({
      "loginData": loginData,
      "start": start.toUtc().toIso8601String(),
      "end": end.toUtc().toIso8601String(),
    })).timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) throw Exception("doctorGetCalendar failed: ${res.statusCode}");
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      final result = decoded["result"];
      if (result is List) return result.cast<Map<String, dynamic>>();
    }
    throw Exception("Unexpected response format");
  }

  Future<List<Map<String, dynamic>>> patientMainPageGetCalendar({
    required Map<String, dynamic> loginData,
    required DateTime start,
    required DateTime end,
    required String timezone,
  }) async {
    final url = Uri.parse("$baseUrl/api/appointments/patientMainPageGetCalendar");
    final res = await http.post(url, headers: _headers, body: jsonEncode({
      "loginData": loginData,
      "start": start.toUtc().toIso8601String(),
      "end": end.toUtc().toIso8601String(),
      "timezone": timezone,
    })).timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) throw Exception("patientMainPageGetCalendar failed: ${res.statusCode}");
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      if (decoded["status"] != "OK") throw Exception("patientMainPageGetCalendar status: ${decoded["status"]}");
      final result = decoded["result"];
      if (result is List) return result.cast<Map<String, dynamic>>();
    }
    throw Exception("Unexpected response format: ${res.body}");
  }

  Future<Map<String, dynamic>> getPatientPortalInfoById({required dynamic patientId}) async {
    final url = Uri.parse("$baseUrl/api/users/getPatientPortalInfoById");
    final res = await http.post(url, headers: _headers, body: jsonEncode({"patientId": patientId})).timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) throw Exception("getPatientPortalInfoById failed: ${res.statusCode}");
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception("Unexpected response format: ${res.body}");
  }

  // prescription table: medicine_name, dosage, start_date, end_date, status
  // prescription_form table: medication_name, medication_strength, dosage_instructions
  Future<dynamic> getPrescriptionsByPatientId({required dynamic patientId}) async {
    final url = Uri.parse("$baseUrl/getPrescriptionsByPatientId");
    final res = await http.post(url, headers: _headers, body: jsonEncode({"patientId": patientId})).timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) throw Exception("getPrescriptionsByPatientId failed: ${res.statusCode}");
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> imageRetrieveByPatientId({required dynamic patientId, required String recordType}) async {
    final url = Uri.parse("$baseUrl/imageRetrieveByPatientId");
    final res = await http.post(url, headers: _headers, body: jsonEncode({"patientId": patientId, "recordType": recordType})).timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) throw Exception("imageRetrieveByPatientId failed: ${res.statusCode}");
    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded["success"] is List) return decoded["success"];
    if (decoded is List) return decoded;
    return [];
  }

  // bloodtests table: test_name, test_date, result_value, unit, normal_range
  Future<dynamic> getBloodtestByPatientId({required dynamic patientId}) async {
    final url = Uri.parse("$baseUrl/getBloodtestByPatientId");
    final res = await http.post(url, headers: _headers, body: jsonEncode({"patientId": patientId})).timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) throw Exception("getBloodtestByPatientId failed: ${res.statusCode}");
    return jsonDecode(res.body);
  }

  // ─────────────────────────── MESSAGING ────────────────────────────────────
  // Confirmed endpoints from React src/api/user.js:
  //   POST /api/users/getMessagesByTypeAndId  { user_id, user_type }
  //   POST /api/users/MessageSend             { conversationId, senderType, sender_id, receiverType, receiver_id, subject, content }
  //   POST /findDoctorsByPatientId            { patientId }  → Fname, Lname, id

  /// Fetch all conversations for this patient, categorized by type.
  /// Returns e.g. { "Doctor": [...], "ClinicStaff": [...] }
  Future<Map<String, List<Map<String, dynamic>>>> getPatientConversations({
    required dynamic patientId,
  }) async {
    final url = Uri.parse("$baseUrl/api/users/getMessagesByTypeAndId");
    final res = await http
        .post(url, headers: _headers,
            body: jsonEncode({"user_id": patientId, "user_type": "Patient"}))
        .timeout(_timeout);
    _ensureSuccess(res, "getPatientConversations failed");
    final decoded = _decodeJson(res.body);

    Map<String, dynamic> raw = {};
    if (decoded is Map<String, dynamic>) raw = decoded;

    final result = <String, List<Map<String, dynamic>>>{};
    for (final entry in raw.entries) {
      if (entry.value is List) {
        result[entry.key] = (entry.value as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      }
    }
    return result;
  }

  /// Send a message — works for both Doctor and ClinicStaff.
  /// conversationId = 0 for new conversation.
  Future<void> sendMessage({
    required dynamic senderId,
    required String senderType,
    required dynamic receiverId,
    required String receiverType,
    required String content,
    String subject = '',
    int conversationId = 0,
  }) async {
    final url = Uri.parse("$baseUrl/api/users/MessageSend");
    final res = await http
        .post(url, headers: _headers, body: jsonEncode({
          "conversationId": conversationId,
          "senderType": senderType,
          "sender_id": senderId,
          "receiverType": receiverType,
          "receiver_id": receiverId,
          "viewer_permissions": {},
          "subject": subject.isEmpty ? "No Subject" : subject,
          "content": content,
        }))
        .timeout(_timeout);
    _ensureSuccess(res, "sendMessage failed");
  }

  /// Get doctors linked to this patient → /findDoctorsByPatientId
  /// Returns: [ { id, Fname, Lname, specialty? }, ... ]
  Future<List<Map<String, dynamic>>> getAvailableDoctors({
    required dynamic patientId,
  }) async {
    final url = Uri.parse("$baseUrl/findDoctorsByPatientId");
    final res = await http
        .post(url, headers: _headers, body: jsonEncode({"patientId": patientId}))
        .timeout(_timeout);
    _ensureSuccess(res, "getAvailableDoctors failed");
    final decoded = _decodeJson(res.body);
    if (decoded is List) return decoded.whereType<Map<String, dynamic>>().toList();
    if (decoded is Map<String, dynamic>) {
      final list = decoded["result"] ?? decoded["data"];
      if (list is List) return list.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// Get clinic staff — endpoint TBC, falls back gracefully
  Future<List<Map<String, dynamic>>> getAvailableStaff({
    required dynamic patientId,
  }) async {
    final url = Uri.parse("$baseUrl/findClinicStaffsByPatientId");
    final res = await http
        .post(url, headers: _headers, body: jsonEncode({"patientId": patientId}))
        .timeout(_timeout);
    _ensureSuccess(res, "getAvailableStaff failed");
    final decoded = _decodeJson(res.body);
    if (decoded is List) return decoded.whereType<Map<String, dynamic>>().toList();
    if (decoded is Map<String, dynamic>) {
      final list = decoded["result"] ?? decoded["data"];
      if (list is List) return list.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  // Keep these for backwards compatibility — they now delegate to sendMessage
  Future<void> sendMessageToDoctor({
    required dynamic patientId,
    required dynamic doctorId,
    required String message,
    bool isUrgent = false,
    dynamic replyTo,
  }) async {
    await sendMessage(
      senderId: patientId,
      senderType: "Patient",
      receiverId: doctorId,
      receiverType: "Doctor",
      content: message,
    );
  }

  Future<void> sendMessageToStaff({
    required dynamic patientId,
    required dynamic staffId,
    required String message,
    bool isUrgent = false,
    dynamic replyTo,
  }) async {
    await sendMessage(
      senderId: patientId,
      senderType: "Patient",
      receiverId: staffId,
      receiverType: "ClinicStaff",
      content: message,
    );
  }

  // These are now unused but kept to avoid breaking other references
  Future<List<Map<String, dynamic>>> getPatientDoctorMessages({
    required dynamic patientId,
    required dynamic doctorId,
  }) async => [];

  Future<List<Map<String, dynamic>>> getPatientStaffMessages({
    required dynamic patientId,
    required dynamic staffId,
  }) async => [];

  Future<List<Map<String, dynamic>>> getPatientMessageHub({
    required dynamic patientId,
  }) async => [];

  // ─────────────────────────── PRIVATE ──────────────────────────────────────

  void _ensureSuccess(http.Response response, String message) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception("$message: ${response.statusCode} - ${response.body}");
  }

  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      throw Exception("Failed to decode JSON. Raw response: $body");
    }
  }

  // ─────────────────────────── ORCHESTRATOR ─────────────────────────────────

  Future<String> orchestrate({
    required String id,
    required String message,
  }) async {
    final url = Uri.parse("http://15.222.187.122/orchestrator/api/orchestrate");
    const orchestratorTimeout = Duration(minutes: 5);
    final request = http.Request("POST", url);
    request.headers.addAll(_headers);
    request.body = jsonEncode({"id": id, "message": message});
    final streamed = await request.send().timeout(orchestratorTimeout);
    final response = await http.Response.fromStream(streamed);
    _ensureSuccess(response, "orchestrate failed");
    return response.body;
  }

  Future<String> orchestratorChat({required String message}) async {
    final url = Uri.parse("http://15.222.187.122/orchestrator/api/chat");
    const orchestratorTimeout = Duration(minutes: 5);
    final request = http.Request("POST", url);
    request.headers.addAll({
      "sec-ch-ua-platform": "\"Windows\"",
      "Referer": "",
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36",
      "sec-ch-ua": "\"Chromium\";v=\"146\", \"Not-A.Brand\";v=\"24\", \"Google Chrome\";v=\"146\"",
      "sec-ch-ua-mobile": "?0",
      "Content-Type": "application/json",
    });
    request.body = jsonEncode({"message": message});
    final streamed = await request.send().timeout(orchestratorTimeout);
    final response = await http.Response.fromStream(streamed);
    _ensureSuccess(response, "orchestratorChat failed");
    return response.body;
  }

  // ─────────────────────────── DOCTOR MESSAGES ──────────────────────────────

  /// Fetch all conversations for a doctor or patient, categorized by type.
  /// Returns typed MessageConversation objects used by MessagesScreen.
  Future<Map<String, List<MessageConversation>>> getMessagesByTypeAndId({
    required dynamic userId,
    required String userType,
  }) async {
    final url = Uri.parse("$baseUrl/api/users/getMessagesByTypeAndId");

    Future<http.Response> postPayload(Map<String, dynamic> payload) async {
      return http.post(url, headers: _headers, body: jsonEncode(payload))
          .timeout(_timeout);
    }

    http.Response response = await postPayload({
      "user_id": userId, "user_type": userType,
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      response = await postPayload({"doctorId": userId, "userType": userType});
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      response = await postPayload({"user_id": userId, "userType": userType});
    }

    _ensureSuccess(response, "getMessagesByTypeAndId failed");
    final decoded = _decodeJson(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception("Unexpected messages response: ${response.body}");
    }
    final rawResult = decoded["result"];
    if (rawResult is! Map<String, dynamic>) {
      throw Exception("Unexpected messages result format: ${response.body}");
    }

    final result = <String, List<MessageConversation>>{};
    rawResult.forEach((category, rawList) {
      if (rawList is List) {
        result[category] = rawList.whereType<Map>().map((e) =>
            MessageConversation.fromJson(Map<String, dynamic>.from(e),
                category: category)).toList();
      } else {
        result[category] = const [];
      }
    });
    return result;
  }

  Future<int> messageSend({required Map<String, dynamic> payload}) async {
    final url = Uri.parse("$baseUrl/api/users/MessageSend");
    final response = await http.post(url, headers: _headers,
        body: jsonEncode(payload)).timeout(_timeout);
    _ensureSuccess(response, "MessageSend failed");
    final decoded = _decodeJson(response.body);
    if (decoded is int) return decoded;
    if (decoded is num) return decoded.toInt();
    if (decoded is Map<String, dynamic>) {
      final value = decoded["result"] ?? decoded["success"] ?? decoded["data"];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
    }
    if (decoded is String) return int.tryParse(decoded) ?? 0;
    return 0;
  }

  Future<void> messageReadStatusUpdate({required List<int> messageIds}) async {
    if (messageIds.isEmpty) return;
    final url = Uri.parse("$baseUrl/api/users/MessageReadStatusUpdate");
    final response = await http.post(url, headers: _headers,
        body: jsonEncode({"messageIds": messageIds})).timeout(_timeout);
    _ensureSuccess(response, "MessageReadStatusUpdate failed");
  }

  Future<List<Map<String, dynamic>>> findClinicStaffsByDoctorId({
    required dynamic doctorId,
  }) async {
    final url = Uri.parse("$baseUrl/findClinicStaffsByDoctorId");
    final response = await http.post(url, headers: _headers,
        body: jsonEncode({"doctorId": doctorId})).timeout(_timeout);
    _ensureSuccess(response, "findClinicStaffsByDoctorId failed");
    final decoded = _decodeJson(response.body);
    if (decoded is List) {
      return decoded.whereType<Map>().map((e) =>
          Map<String, dynamic>.from(e)).toList();
    }
    if (decoded is Map<String, dynamic>) {
      final list = decoded["result"] ?? decoded["data"];
      if (list is List) return list.whereType<Map>().map((e) =>
          Map<String, dynamic>.from(e)).toList();
    }
    throw Exception("Unexpected clinic staff response: ${response.body}");
  }
}