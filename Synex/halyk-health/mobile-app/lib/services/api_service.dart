import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_models.dart';

class ApiService {
  ApiService({this.baseUrl = 'http://localhost:4000/api'});

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

  Future<AppUser> me() async {
    final response = await _request('/auth/me');
    return AppUser.fromJson(response as Map<String, dynamic>);
  }

  Future<List<PatientProfile>> getPatientProfiles() async {
    final response = await _request('/patient-profiles/my') as List<dynamic>;
    return response
        .map((item) => PatientProfile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getPatientAppointmentContext(String profileId) async {
    final response = await _request('/patient-profiles/$profileId/appointment-context');
    return response as Map<String, dynamic>;
  }

  Future<List<Clinic>> getClinics() async {
    final response =
        await _request('/clinics', authenticated: false) as List<dynamic>;
    return response
        .map((item) => Clinic.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<DoctorProfile>> getClinicDoctors(String clinicId) async {
    final response =
        await _request('/clinics/$clinicId/doctors', authenticated: false)
            as List<dynamic>;
    return response
        .map((item) => DoctorProfile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment> createAppointment({
    required String patientProfileId,
    required String doctorId,
    required String clinicId,
    required DateTime appointmentDate,
    required String complaint,
  }) async {
    final response = await _request(
      '/appointments',
      method: 'POST',
      body: {
        'patientProfileId': patientProfileId,
        'doctorId': doctorId,
        'clinicId': clinicId,
        'appointmentDate': appointmentDate.toUtc().toIso8601String(),
        'complaint': complaint,
      },
    );
    return Appointment.fromJson(response as Map<String, dynamic>);
  }

  Future<List<Appointment>> getMyAppointments({String? patientProfileId}) async {
    String path = '/appointments/my';
    if (patientProfileId != null) {
      path += '?patientProfileId=$patientProfileId';
    }
    final response = await _request(path) as List<dynamic>;
    return response
        .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment> cancelAppointment(String id) async {
    final response =
        await _request('/appointments/$id/cancel', method: 'PATCH');
    return Appointment.fromJson(response as Map<String, dynamic>);
  }

  Future<Appointment> rescheduleAppointment(String id, DateTime newDate) async {
    final response = await _request(
      '/appointments/$id/reschedule',
      method: 'PATCH',
      body: {'appointmentDate': newDate.toUtc().toIso8601String()},
    );
    return Appointment.fromJson(response as Map<String, dynamic>);
  }

  Future<List<Prescription>> getMyPrescriptions({String? patientProfileId}) async {
    String path = '/prescriptions/my';
    if (patientProfileId != null) {
      path += '?patientProfileId=$patientProfileId';
    }
    final response = await _request(path) as List<dynamic>;
    return response
        .map((item) => Prescription.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Prescription> getPrescriptionById(String prescriptionId) async {
    final response = await _request('/prescriptions/$prescriptionId');
    return Prescription.fromJson(response as Map<String, dynamic>);
  }

  Future<Prescription> analyzePrescription(String prescriptionId) async {
    final response = await _request(
      '/prescriptions/$prescriptionId/analyze-ai',
      method: 'POST',
    );
    return Prescription.fromJson(response as Map<String, dynamic>);
  }

  Future<List<MedicineProductGroup>> getPrescriptionMarketProducts(
    String prescriptionId,
  ) async {
    final response =
        await _request('/prescriptions/$prescriptionId/market-products')
            as List<dynamic>;
    return response
        .map(
          (item) => MedicineProductGroup.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<MarketProduct>> getMarketProducts() async {
    final response = await _request('/market/products', authenticated: false)
        as List<dynamic>;
    return response
        .map((item) => MarketProduct.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<MarketProduct>> searchMarketProducts(String query) async {
    final response = await _request(
      '/market/search?query=${Uri.encodeQueryComponent(query)}',
      authenticated: false,
    ) as List<dynamic>;
    return response
        .map((item) => MarketProduct.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<MarketProduct>> getAlternatives(String activeSubstance) async {
    final response = await _request(
      '/market/alternatives?activeSubstance=${Uri.encodeQueryComponent(activeSubstance)}',
      authenticated: false,
    ) as List<dynamic>;
    return response
        .map((item) => MarketProduct.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addToCart(String productId, {String? patientProfileId}) async {
    await _request(
      '/market/cart',
      method: 'POST',
      body: {
        'productId': productId,
        'quantity': 1,
        if (patientProfileId != null) 'patientProfileId': patientProfileId,
      },
    );
  }

  Future<List<CartItem>> getCart() async {
    final response = await _request('/market/cart') as List<dynamic>;
    return response
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateCartItemQuantity(String cartItemId, int quantity) async {
    await _request(
      '/market/cart/$cartItemId',
      method: 'PATCH',
      body: {'quantity': quantity},
    );
  }

  Future<void> removeCartItem(String cartItemId) async {
    await _request('/market/cart/$cartItemId', method: 'DELETE');
  }

  Future<List<MedicationScheduleItem>> getMySchedule({String? patientProfileId}) async {
    String path = '/schedule/my';
    if (patientProfileId != null) {
      path += '?patientProfileId=$patientProfileId';
    }
    final response = await _request(path) as List<dynamic>;
    return response
        .map(
          (item) =>
              MedicationScheduleItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();
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
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
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
