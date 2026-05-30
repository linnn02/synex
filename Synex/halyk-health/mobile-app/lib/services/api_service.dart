import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_models.dart';

class ApiService {
  ApiService({
    this.baseUrl = 'http://localhost:4000/api',
  });

  final String baseUrl;
  String? _token;

  bool get isAuthenticated => _token != null;

  Future<AppUser> login(String email, String password) async {
    final response = await _request(
      '/auth/login',
      method: 'POST',
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    _token = response['token'] as String;
    return AppUser.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<List<Clinic>> getClinics() async {
    final response = await _request('/clinics', authenticated: false) as List<dynamic>;
    return response.map((item) => Clinic.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<DoctorProfile>> getClinicDoctors(String clinicId) async {
    final response = await _request('/clinics/$clinicId/doctors', authenticated: false) as List<dynamic>;
    return response.map((item) => DoctorProfile.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> createAppointment({
    required String doctorId,
    required String clinicId,
    required DateTime appointmentDate,
    required String complaint,
  }) async {
    await _request(
      '/appointments',
      method: 'POST',
      body: {
        'doctorId': doctorId,
        'clinicId': clinicId,
        'appointmentDate': appointmentDate.toUtc().toIso8601String(),
        'complaint': complaint,
      },
    );
  }

  Future<List<Appointment>> getMyAppointments() async {
    final response = await _request('/appointments/my') as List<dynamic>;
    return response.map((item) => Appointment.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<Prescription>> getMyPrescriptions() async {
    final response = await _request('/prescriptions/my') as List<dynamic>;
    return response.map((item) => Prescription.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Prescription> analyzePrescription(String prescriptionId) async {
    final response = await _request('/prescriptions/$prescriptionId/analyze-ai', method: 'POST');
    return Prescription.fromJson(response as Map<String, dynamic>);
  }

  Future<List<MedicineProductGroup>> getPrescriptionMarketProducts(String prescriptionId) async {
    final response = await _request('/prescriptions/$prescriptionId/market-products') as List<dynamic>;
    return response.map((item) => MedicineProductGroup.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<MarketProduct>> getMarketProducts() async {
    final response = await _request('/market/products', authenticated: false) as List<dynamic>;
    return response.map((item) => MarketProduct.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<MarketProduct>> getAlternatives(String activeSubstance) async {
    final response = await _request(
      '/market/alternatives?activeSubstance=${Uri.encodeQueryComponent(activeSubstance)}',
      authenticated: false,
    ) as List<dynamic>;
    return response.map((item) => MarketProduct.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> addToCart(String productId) async {
    await _request(
      '/market/cart',
      method: 'POST',
      body: {'productId': productId, 'quantity': 1},
    );
  }

  Future<List<MedicationScheduleItem>> getMySchedule() async {
    final response = await _request('/schedule/my') as List<dynamic>;
    return response.map((item) => MedicationScheduleItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> markScheduleTaken(String id) async {
    await _request('/schedule/$id/taken', method: 'PATCH');
  }

  Future<void> markScheduleMissed(String id) async {
    await _request('/schedule/$id/missed', method: 'PATCH');
  }

  Future<dynamic> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authenticated && _token != null) 'Authorization': 'Bearer $_token',
    };

    final requestBody = body == null ? null : jsonEncode(body);
    late http.Response response;

    switch (method) {
      case 'POST':
        response = await http.post(uri, headers: headers, body: requestBody);
        break;
      case 'PATCH':
        response = await http.patch(uri, headers: headers, body: requestBody);
        break;
      default:
        response = await http.get(uri, headers: headers);
    }

    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded is Map<String, dynamic> ? decoded['error'] : null;
      final message = error is Map<String, dynamic>
          ? error['message']?.toString() ?? 'API request failed'
          : 'API request failed';
      throw Exception(message);
    }

    return decoded;
  }
}
