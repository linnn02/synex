import 'dart:math';

// Custom models for Halyk MedCare
class MedCarePatient {
  final String id;
  final String fullName;
  final String iin;
  final String phone;
  final String insuranceStatus; // 'active' or 'inactive'
  final String clinicId;
  final String doctorId;

  MedCarePatient({
    required this.id,
    required this.fullName,
    required this.iin,
    required this.phone,
    required this.insuranceStatus,
    required this.clinicId,
    required this.doctorId,
  });
}

class MedCareClinic {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String status; // e.g. "Прикреплен"

  MedCareClinic({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.status,
  });
}

class MedCareDoctor {
  final String id;
  final String fullName;
  final String specialization;
  final String cabinet;
  final String clinicId;
  final int experience;
  final double rating;

  MedCareDoctor({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.cabinet,
    required this.clinicId,
    required this.experience,
    required this.rating,
  });
}

class AppointmentSlot {
  final String id;
  final String doctorId;
  final String date; // e.g. "31.05.2026"
  final String time; // e.g. "14:30"
  final bool isAvailable;

  AppointmentSlot({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.isAvailable,
  });
}

class MedCareAppointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String clinicId;
  final String reason;
  final String date;
  final String time;
  final String status; // "Ожидает подтверждения"
  final DateTime createdAt;

  MedCareAppointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.clinicId,
    required this.reason,
    required this.date,
    required this.time,
    required this.status,
    required this.createdAt,
  });
}

class AppointmentService {
  // Singleton instance
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;
  AppointmentService._internal() {
    _initMockData();
  }

  // In-memory mock database
  final List<MedCarePatient> _patients = [];
  final List<MedCareClinic> _clinics = [];
  final List<MedCareDoctor> _doctors = [];
  final List<AppointmentSlot> _slots = [];
  final List<MedCareAppointment> _appointments = [];

  // Currently logged-in fake patient IIN
  String _currentIin = "920815350112"; // Default patient with active insurance

  void setFakePatientIin(String iin) {
    _currentIin = iin;
  }

  void _initMockData() {
    // 1. Seed Clinics
    _clinics.addAll([
      MedCareClinic(
        id: "c1",
        name: "Halyk MedCare Clinic №1",
        address: "г. Алматы, пр. Аль-Фараби, 101/3",
        phone: "+7 (727) 356-90-01",
        status: "Основное прикрепление по страховке",
      ),
      MedCareClinic(
        id: "c2",
        name: "Городская поликлиника №5",
        address: "г. Алматы, ул. Макатаева, 142",
        phone: "+7 (727) 293-84-75",
        status: "Временное прикрепление",
      ),
    ]);

    // 2. Seed Doctors
    _doctors.addAll([
      MedCareDoctor(
        id: "d1",
        fullName: "Доктор Алия Нурланова",
        specialization: "Терапевт высшей категории",
        cabinet: "305",
        clinicId: "c1",
        experience: 14,
        rating: 4.9,
      ),
      MedCareDoctor(
        id: "d2",
        fullName: "Иванов Дмитрий Сергеевич",
        specialization: "Терапевт / Кардиолог",
        cabinet: "212",
        clinicId: "c2",
        experience: 8,
        rating: 4.7,
      ),
    ]);

    // 3. Seed Patients
    _patients.addAll([
      // Active insurance
      MedCarePatient(
        id: "p1",
        fullName: "Аделия Каримова",
        iin: "920815350112",
        phone: "+7 (707) 123-45-67",
        insuranceStatus: "active",
        clinicId: "c1",
        doctorId: "d1",
      ),
      // Inactive insurance
      MedCarePatient(
        id: "p2",
        fullName: "Нурлан Маратов",
        iin: "950101450231",
        phone: "+7 (747) 987-65-43",
        insuranceStatus: "inactive",
        clinicId: "c2",
        doctorId: "d2",
      ),
    ]);

    // 4. Seed Slots for Doctor 1 (Aliya) and Doctor 2 (Dmitry)
    final random = Random();
    final today = DateTime.now();
    final dateTimes = [
      today.add(const Duration(days: 1)),
      today.add(const Duration(days: 2)),
      today.add(const Duration(days: 3)),
    ];

    final times = ["09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30"];

    int slotId = 1;
    for (final doctor in _doctors) {
      for (final dt in dateTimes) {
        final dateStr = "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}";
        for (final time in times) {
          // 70% of slots are available
          final isAvail = random.nextDouble() < 0.75;
          _slots.add(AppointmentSlot(
            id: "s${slotId++}",
            doctorId: doctor.id,
            date: dateStr,
            time: time,
            isAvailable: isAvail,
          ));
        }
      }
    }
  }

  // --- API Functions ---

  // 1. getCurrentPatient()
  Future<MedCarePatient?> getCurrentPatient() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      return _patients.firstWhere((p) => p.iin == _currentIin);
    } catch (_) {
      return null;
    }
  }

  // 2. getPatientClinic(patientId)
  Future<MedCareClinic?> getPatientClinic(String clinicId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _clinics.firstWhere((c) => c.id == clinicId);
    } catch (_) {
      return null;
    }
  }

  // 3. getPatientDoctor(doctorId)
  Future<MedCareDoctor?> getPatientDoctor(String doctorId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _doctors.firstWhere((d) => d.id == doctorId);
    } catch (_) {
      return null;
    }
  }

  // 4. getAvailableSlots(doctorId)
  Future<List<AppointmentSlot>> getAvailableSlots(String doctorId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _slots.where((s) => s.doctorId == doctorId).toList();
  }

  // 5. createAppointment(data)
  Future<MedCareAppointment> createAppointment({
    required String patientId,
    required String doctorId,
    required String clinicId,
    required String reason,
    required String date,
    required String time,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final id = "apt_${DateTime.now().millisecondsSinceEpoch}";
    final appointment = MedCareAppointment(
      id: id,
      patientId: patientId,
      doctorId: doctorId,
      clinicId: clinicId,
      reason: reason,
      date: date,
      time: time,
      status: "Ожидает подтверждения",
      createdAt: DateTime.now(),
    );

    // Add to in-memory database
    _appointments.add(appointment);

    // Mark that slot as unavailable
    final index = _slots.indexWhere((s) => s.doctorId == doctorId && s.date == date && s.time == time);
    if (index != -1) {
      _slots[index] = AppointmentSlot(
        id: _slots[index].id,
        doctorId: doctorId,
        date: date,
        time: time,
        isAvailable: false,
      );
    }

    return appointment;
  }

  // Utility to get all scheduled appointments for debug
  List<MedCareAppointment> getAppointments() => _appointments;
}
