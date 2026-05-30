import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/appointment_service.dart';
import '../widgets/patient_info_card.dart';
import '../widgets/clinic_info_card.dart';
import '../widgets/doctor_info_card.dart';
import '../widgets/reason_selector.dart';
import '../widgets/slot_picker.dart';
import '../widgets/appointment_summary.dart';
import '../widgets/appointment_success_card.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final ApiService apiService;

  const CreateAppointmentScreen({super.key, required this.apiService});

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _appointmentService = AppointmentService();

  // App State
  bool _loading = true;
  String? _error;
  MedCarePatient? _patient;
  MedCareClinic? _clinic;
  MedCareDoctor? _doctor;
  List<AppointmentSlot> _slots = [];

  // Form State
  String _selectedReason = '';
  String? _selectedDate;
  String? _selectedTime;
  bool _submitting = false;

  // Created Appointment State for Success Card
  MedCareAppointment? _createdAppointment;

  @override
  void initState() {
    super.initState();
    _loadMedCareData();
  }

  Future<void> _loadMedCareData() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedDate = null;
      _selectedTime = null;
      _selectedReason = '';
    });

    try {
      final patient = await _appointmentService.getCurrentPatient();
      if (patient == null) {
        throw Exception('Данные пациента не найдены по указанному ИИН.');
      }

      final clinic = await _appointmentService.getPatientClinic(patient.clinicId);
      final doctor = await _appointmentService.getPatientDoctor(patient.doctorId);
      final slots = await _appointmentService.getAvailableSlots(patient.doctorId);

      setState(() {
        _patient = patient;
        _clinic = clinic;
        _doctor = doctor;
        _slots = slots;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception:', '').trim();
        _loading = false;
      });
    }
  }

  void _onReasonChanged(String reason) {
    setState(() {
      _selectedReason = reason;
    });
  }

  void _onSlotSelected(String date, String time) {
    setState(() {
      _selectedDate = date;
      _selectedTime = time;
    });
  }

  Future<void> _submitAppointment() async {
    if (_patient == null || _clinic == null || _doctor == null || _selectedDate == null || _selectedTime == null || _selectedReason.isEmpty) {
      return;
    }

    setState(() => _submitting = true);

    try {
      final appointment = await _appointmentService.createAppointment(
        patientId: _patient!.id,
        doctorId: _doctor!.id,
        clinicId: _clinic!.id,
        reason: _selectedReason,
        date: _selectedDate!,
        time: _selectedTime!,
      );

      setState(() {
        _createdAppointment = appointment;
        _submitting = false;
      });
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при отправке заявки: $e')),
      );
    }
  }

  // Switcher for testing active/inactive insurance
  Widget _buildTestIinSelector() {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Тест ИИН:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          Row(
            children: [
              _buildTestButton('920815350112', 'Активный', true),
              const SizedBox(width: 6),
              _buildTestButton('950101450231', 'Неактивный', false),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTestButton(String iin, String label, bool isActive) {
    final isSelected = _patient?.iin == iin;
    return GestureDetector(
      onTap: () {
        _appointmentService.setFakePatientIin(iin);
        _loadMedCareData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A884) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A884) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isButtonEnabled = _selectedReason.isNotEmpty && _selectedDate != null && _selectedTime != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Halyk MedCare',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: _buildTestIinSelector(),
        ),
      ),
      body: _createdAppointment != null
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: AppointmentSuccessCard(
                  appointment: _createdAppointment!,
                  clinic: _clinic!,
                  doctor: _doctor!,
                  onClose: () => Navigator.pop(context),
                ),
              ),
            )
          : _loading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A884)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Подтягиваем данные по ИИН...',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _loadMedCareData,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A884)),
                              child: const Text('Попробовать снова'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Description
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00A884), Color(0xFF008966)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Записаться к врачу',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Система автоматически определит вашу поликлинику и лечащего врача по данным страховки.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xE6FFFFFF),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Patient info
                          PatientInfoCard(patient: _patient!),
                          const SizedBox(height: 16),

                          // Clinic info
                          ClinicInfoCard(clinic: _clinic!),
                          const SizedBox(height: 16),

                          // Doctor info
                          DoctorInfoCard(doctor: _doctor!),
                          const SizedBox(height: 16),

                          // Reason selector
                          ReasonSelector(onChanged: _onReasonChanged),
                          const SizedBox(height: 16),

                          // Slot picker
                          SlotPicker(slots: _slots, onSelected: _onSlotSelected),
                          const SizedBox(height: 16),

                          // Summary (Visible when inputs are selected)
                          if (_selectedDate != null && _selectedTime != null) ...[
                            AppointmentSummary(
                              patient: _patient!,
                              clinic: _clinic!,
                              doctor: _doctor!,
                              date: _selectedDate!,
                              time: _selectedTime!,
                              reason: _selectedReason,
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Action button
                          SizedBox(
                            height: 54,
                            child: FilledButton(
                              onPressed: (isButtonEnabled && !_submitting) ? _submitAppointment : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF00A884),
                                disabledBackgroundColor: const Color(0xFFCBD5E1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check, size: 20),
                                        SizedBox(width: 10),
                                        Text(
                                          'Отправить заявку',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }
}
