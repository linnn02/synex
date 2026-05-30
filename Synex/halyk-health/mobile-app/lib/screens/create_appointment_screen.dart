import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import '../services/appointment_service.dart';
import '../widgets/appointment_success_card.dart';
import '../widgets/appointment_summary.dart';
import '../widgets/clinic_info_card.dart';
import '../widgets/doctor_info_card.dart';
import '../widgets/patient_info_card.dart';
import '../widgets/reason_selector.dart';
import '../widgets/slot_picker.dart';

const _green = Color(0xFF007F5F);
const _dark = Color(0xFF073E35);
const _bg = Color(0xFFF4F7F8);

class CreateAppointmentScreen extends StatefulWidget {
  const CreateAppointmentScreen({
    super.key,
    required this.apiService,
    this.currentUser,
  });

  final ApiService apiService;
  final AppUser? currentUser;

  @override
  State<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  AppUser? _user;
  List<PatientProfile> _profiles = [];
  List<Clinic> _clinics = [];
  List<DoctorProfile> _doctors = [];
  
  PatientProfile? _selectedProfile;
  Clinic? _selectedClinic;
  DoctorProfile? _selectedDoctor;
  List<AppointmentSlot> _slots = [];

  String _selectedReason = '';
  String? _selectedDate;
  String? _selectedTime;
  Appointment? _createdAppointment;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedDate = null;
      _selectedTime = null;
      _selectedReason = '';
    });

    try {
      final user = widget.currentUser ?? await widget.apiService.me();
      final profiles = await widget.apiService.getPatientProfiles();
      final clinics = await widget.apiService.getClinics();
      
      final initialProfile = profiles.firstWhere(
        (p) => p.relationType == 'SELF',
        orElse: () => profiles.isNotEmpty ? profiles.first : throw Exception('No patient profiles found'),
      );

      final preferredClinic = initialProfile.clinic ?? _pickPreferredClinic(clinics);
      final doctors = preferredClinic == null
          ? <DoctorProfile>[]
          : await widget.apiService.getClinicDoctors(preferredClinic.id);

      final preferredDoctor = initialProfile.primaryDoctor ?? _pickPreferredDoctor(doctors);

      if (!mounted) return;
      setState(() {
        _user = user;
        _profiles = profiles;
        _clinics = clinics;
        _selectedProfile = initialProfile;
        _selectedClinic = preferredClinic;
        _doctors = doctors;
        _selectedDoctor = preferredDoctor;
        _slots = _buildSlots();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Clinic? _pickPreferredClinic(List<Clinic> clinics) {
    if (clinics.isEmpty) return null;
    return clinics.firstWhere(
      (clinic) => clinic.name.toLowerCase().contains('halyk'),
      orElse: () => clinics.first,
    );
  }

  DoctorProfile? _pickPreferredDoctor(List<DoctorProfile> doctors) {
    if (doctors.isEmpty) return null;
    return doctors.firstWhere(
      (doctor) => doctor.specialization.toLowerCase().contains('терапевт'),
      orElse: () => doctors.first,
    );
  }

  List<AppointmentSlot> _buildSlots() {
    final now = DateTime.now();
    final times = [
      '09:00',
      '09:30',
      '10:00',
      '10:30',
      '11:00',
      '11:30',
      '14:00',
      '14:30',
      '15:00',
      '15:30',
      '16:00',
      '16:30',
    ];

    final slots = <AppointmentSlot>[];
    for (var day = 1; day <= 5; day++) {
      final date = now.add(Duration(days: day));
      final dateText = DateFormat('dd.MM.yyyy').format(date);
      for (var index = 0; index < times.length; index++) {
        slots.add(
          AppointmentSlot(
            id: '$dateText-${times[index]}',
            doctorId: _selectedDoctor?.user.id ?? '',
            date: dateText,
            time: times[index],
            isAvailable: (day + index) % 5 != 0,
          ),
        );
      }
    }
    return slots;
  }

  Future<void> _changeProfile(PatientProfile profile) async {
    setState(() {
      _selectedProfile = profile;
    });

    if (profile.clinic != null) {
      await _changeClinic(profile.clinic!, preselectedDoctor: profile.primaryDoctor);
    }
  }

  Future<void> _changeClinic(Clinic clinic, {DoctorProfile? preselectedDoctor}) async {
    setState(() {
      _selectedClinic = clinic;
      _selectedDoctor = null;
      _doctors = [];
      _slots = [];
      _selectedDate = null;
      _selectedTime = null;
    });

    try {
      final doctors = await widget.apiService.getClinicDoctors(clinic.id);
      if (!mounted) return;
      setState(() {
        _doctors = doctors;
        _selectedDoctor = preselectedDoctor ?? _pickPreferredDoctor(doctors);
        _slots = _buildSlots();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _changeDoctor(DoctorProfile doctor) {
    setState(() {
      _selectedDoctor = doctor;
      _selectedDate = null;
      _selectedTime = null;
      _slots = _buildSlots();
    });
  }

  void _onSlotSelected(String date, String time) {
    setState(() {
      _selectedDate = date;
      _selectedTime = time;
    });
  }

  Future<void> _submit() async {
    if (_selectedProfile == null ||
        _selectedClinic == null ||
        _selectedDoctor == null ||
        _selectedDate == null ||
        _selectedTime == null ||
        _selectedReason.isEmpty) {
      return;
    }

    final dateParts = _selectedDate!.split('.');
    final timeParts = _selectedTime!.split(':');
    final appointmentDate = DateTime(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    setState(() => _submitting = true);
    try {
      final appointment = await widget.apiService.createAppointment(
        patientProfileId: _selectedProfile!.id,
        doctorId: _selectedDoctor!.user.id,
        clinicId: _selectedClinic!.id,
        appointmentDate: appointmentDate,
        complaint: _selectedReason,
      );
      if (!mounted) return;
      setState(() {
        _createdAppointment = appointment;
        _submitting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _selectedReason.isNotEmpty &&
        _selectedDate != null &&
        _selectedTime != null &&
        !_submitting;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Запись к врачу',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _dark,
        elevation: 0,
      ),
      body: _createdAppointment != null
          ? _buildSuccess()
          : _loading
              ? const _LoadingState()
              : _error != null
                  ? _ErrorState(error: _error!, onRetry: _load)
                  : _buildForm(enabled),
    );
  }

  Widget _buildForm(bool enabled) {
    final profile = _selectedProfile!;
    final clinic = _selectedClinic!;
    final doctor = _selectedDoctor!;
    
    final medCarePatient = MedCarePatient(
      id: profile.id,
      fullName: profile.fullName,
      iin: profile.iin ?? 'Не указан',
      phone: _user?.phone ?? '',
      insuranceStatus: profile.insuranceStatus.toLowerCase(),
      clinicId: clinic.id,
      doctorId: doctor.user.id,
    );
    
    final medCareClinic = _clinicAdapter(clinic);
    final medCareDoctor = _doctorAdapter(doctor);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_dark, _green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halyk MedCare',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Подберём прикреплённую поликлинику, врача и ближайшие слоты. Заявка уйдёт в кабинет врача.',
                style: TextStyle(color: Color(0xD9FFFFFF), height: 1.42),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        _SelectionCard(
          title: 'Кому нужна запись?',
          icon: Icons.people_outline,
          child: DropdownButtonFormField<PatientProfile>(
            key: ValueKey(_selectedProfile?.id ?? 'profile'),
            initialValue: _selectedProfile,
            decoration: const InputDecoration(labelText: 'Выберите члена семьи'),
            items: _profiles
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(
                      '${p.fullName} (${p.relationLabel})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (p) {
              if (p != null) _changeProfile(p);
            },
          ),
        ),
        const SizedBox(height: 16),
        
        PatientInfoCard(patient: medCarePatient),
        const SizedBox(height: 16),
        
        _SelectionCard(
          title: 'Поликлиника',
          icon: Icons.local_hospital_outlined,
          child: DropdownButtonFormField<Clinic>(
            key: ValueKey(_selectedClinic?.id ?? 'clinic'),
            initialValue: _selectedClinic,
            decoration: const InputDecoration(labelText: 'Выберите клинику'),
            items: _clinics
                .map(
                  (clinic) => DropdownMenuItem(
                    value: clinic,
                    child: Text(
                      clinic.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (clinic) {
              if (clinic != null) _changeClinic(clinic);
            },
          ),
        ),
        const SizedBox(height: 12),
        ClinicInfoCard(clinic: medCareClinic),
        const SizedBox(height: 16),
        _SelectionCard(
          title: 'Лечащий врач',
          icon: Icons.medical_services_outlined,
          child: DropdownButtonFormField<DoctorProfile>(
            key: ValueKey(_selectedDoctor?.id ?? 'doctor'),
            initialValue: _selectedDoctor,
            decoration: const InputDecoration(labelText: 'Выберите врача'),
            items: _doctors
                .map(
                  (doctor) => DropdownMenuItem(
                    value: doctor,
                    child: Text(
                      '${doctor.user.fullName} · ${doctor.specialization}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (doctor) {
              if (doctor != null) _changeDoctor(doctor);
            },
          ),
        ),
        const SizedBox(height: 12),
        DoctorInfoCard(doctor: medCareDoctor),
        const SizedBox(height: 16),
        ReasonSelector(onChanged: (value) => setState(() => _selectedReason = value)),
        const SizedBox(height: 16),
        SlotPicker(slots: _slots, onSelected: _onSlotSelected),
        if (_selectedDate != null && _selectedTime != null) ...[
          const SizedBox(height: 16),
          AppointmentSummary(
            patient: medCarePatient,
            clinic: medCareClinic,
            doctor: medCareDoctor,
            date: _selectedDate!,
            time: _selectedTime!,
            reason: _selectedReason,
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: enabled ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline),
                      SizedBox(width: 10),
                      Text(
                        'Отправить заявку',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final clinic = _clinicAdapter(_selectedClinic!);
    final doctor = _doctorAdapter(_selectedDoctor!);
    final appointment = MedCareAppointment(
      id: _createdAppointment!.id,
      patientId: _user!.id,
      doctorId: _selectedDoctor!.user.id,
      clinicId: _selectedClinic!.id,
      reason: _createdAppointment!.complaint,
      date: DateFormat('dd.MM.yyyy').format(_createdAppointment!.appointmentDate.toLocal()),
      time: DateFormat('HH:mm').format(_createdAppointment!.appointmentDate.toLocal()),
      status: 'Ожидает подтверждения',
      createdAt: DateTime.now(),
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: AppointmentSuccessCard(
          appointment: appointment,
          clinic: clinic,
          doctor: doctor,
          onClose: () => Navigator.pop(context, true),
        ),
      ),
    );
  }

  MedCareClinic _clinicAdapter(Clinic clinic) {
    return MedCareClinic(
      id: clinic.id,
      name: clinic.name,
      address: '${clinic.address}, ${clinic.city}',
      phone: clinic.phone ?? '+7 727 000 00 00',
      status: 'Прикрепление в Halyk Health',
    );
  }

  MedCareDoctor _doctorAdapter(DoctorProfile doctor) {
    return MedCareDoctor(
      id: doctor.user.id,
      fullName: doctor.user.fullName,
      specialization: doctor.specialization,
      cabinet: doctor.roomNumber ?? 'уточняется',
      clinicId: doctor.clinic.id,
      experience: 12,
      rating: 4.9,
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _green),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _green),
          SizedBox(height: 16),
          Text(
            'Подбираем поликлинику и врача...',
            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 58, color: Color(0xFF94A3B8)),
            const SizedBox(height: 14),
            const Text(
              'Не удалось загрузить запись',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), height: 1.35),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
              style: FilledButton.styleFrom(backgroundColor: _green),
            ),
          ],
        ),
      ),
    );
  }
}
