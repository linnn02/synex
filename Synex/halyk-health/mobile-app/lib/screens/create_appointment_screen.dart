import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';

const _green = Color(0xFF006B5B);
const _greenLight = Color(0xFFE6F4F1);
const _bg = Color(0xFFF5F7F8);

class CreateAppointmentScreen extends StatefulWidget {
  const CreateAppointmentScreen({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _reasons = const [
    'Плановый осмотр',
    'Температура и слабость',
    'Боль в горле',
    'Головная боль',
    'Повторный приём',
  ];
  final _times = const [
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

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<Clinic> _clinics = [];
  List<DoctorProfile> _doctors = [];
  Clinic? _clinic;
  DoctorProfile? _doctor;
  DateTime? _date;
  String? _time;
  String? _reason;
  Appointment? _created;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final clinics = await widget.apiService.getClinics();
      if (!mounted) return;

      setState(() {
        _clinics = clinics;
        _clinic = clinics.isEmpty ? null : clinics.first;
      });

      if (_clinic != null) {
        await _loadDoctors(_clinic!.id);
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadDoctors(String clinicId) async {
    final doctors = await widget.apiService.getClinicDoctors(clinicId);
    if (!mounted) return;
    setState(() {
      _doctors = doctors;
      _doctor = doctors.isEmpty ? null : doctors.first;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _green),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submit() async {
    if (_clinic == null ||
        _doctor == null ||
        _date == null ||
        _time == null ||
        _reason == null) {
      return;
    }

    final parts = _time!.split(':');
    final appointmentDate = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    setState(() => _submitting = true);
    try {
      final appointment = await widget.apiService.createAppointment(
        doctorId: _doctor!.user.id,
        clinicId: _clinic!.id,
        appointmentDate: appointmentDate,
        complaint: _reason!,
      );
      if (!mounted) return;
      setState(() {
        _created = appointment;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: const Text('Новая запись')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _loadClinics)
              : _created != null
                  ? _SuccessState(appointment: _created!)
                  : _buildForm(),
    );
  }

  Widget _buildForm() {
    final canSubmit = _clinic != null &&
        _doctor != null &&
        _date != null &&
        _time != null &&
        _reason != null &&
        !_submitting;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Записаться к врачу',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Выберите поликлинику, врача, дату и время приёма',
                style: TextStyle(color: Color(0xFF60727F), height: 1.35),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<Clinic>(
                value: _clinic,
                decoration: const InputDecoration(labelText: 'Поликлиника'),
                items: _clinics
                    .map(
                      (clinic) => DropdownMenuItem(
                        value: clinic,
                        child: Text(clinic.name),
                      ),
                    )
                    .toList(),
                onChanged: (clinic) async {
                  if (clinic == null) return;
                  setState(() {
                    _clinic = clinic;
                    _doctor = null;
                    _doctors = [];
                  });
                  await _loadDoctors(clinic.id);
                },
              ),
              if (_clinic != null) ...[
                const SizedBox(height: 8),
                Text(
                  _clinic!.address,
                  style:
                      const TextStyle(color: Color(0xFF60727F), fontSize: 13),
                ),
              ],
              const SizedBox(height: 14),
              DropdownButtonFormField<DoctorProfile>(
                value: _doctor,
                decoration: const InputDecoration(labelText: 'Врач'),
                items: _doctors
                    .map(
                      (doctor) => DropdownMenuItem(
                        value: doctor,
                        child: Text(
                          '${doctor.user.fullName} · ${doctor.specialization}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (doctor) => setState(() => _doctor = doctor),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _reason,
                decoration:
                    const InputDecoration(labelText: 'Причина обращения'),
                items: _reasons
                    .map(
                      (reason) => DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      ),
                    )
                    .toList(),
                onChanged: (reason) => setState(() => _reason = reason),
              ),
              const SizedBox(height: 16),
              _DateButton(date: _date, onTap: _pickDate),
              const SizedBox(height: 16),
              const Text(
                'Время',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _times
                    .map(
                      (time) => ChoiceChip(
                        label: Text(time),
                        selected: _time == time,
                        selectedColor: _greenLight,
                        checkmarkColor: _green,
                        onSelected: (_) => setState(() => _time = time),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: canSubmit ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              disabledBackgroundColor: const Color(0xFFCFDDE2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(_submitting ? 'Отправляем...' : 'Отправить заявку'),
          ),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.date, required this.onTap});

  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: date == null ? Colors.white : _greenLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: date == null ? const Color(0xFFCFDDE2) : _green,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: _green, size: 18),
            const SizedBox(width: 10),
            Text(
              date == null
                  ? 'Выбрать дату'
                  : DateFormat('dd MMMM yyyy', 'ru').format(date!),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final localDate = appointment.appointmentDate.toLocal();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _greenLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check_circle, color: _green, size: 42),
            ),
            const SizedBox(height: 18),
            const Text(
              'Заявка создана',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '${appointment.doctor.fullName}\n${DateFormat('dd MMMM yyyy, HH:mm', 'ru').format(localDate)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF60727F), height: 1.4),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(backgroundColor: _green),
                child: const Text('Готово'),
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: Color(0xFFCFD8DC)),
            const SizedBox(height: 16),
            const Text(
              'Не удалось загрузить данные',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF60727F)),
            ),
            const SizedBox(height: 22),
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
