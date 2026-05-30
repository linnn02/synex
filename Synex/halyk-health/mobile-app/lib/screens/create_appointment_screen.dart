import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';

class CreateAppointmentScreen extends StatefulWidget {
  const CreateAppointmentScreen({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _complaintController = TextEditingController();
  List<Clinic> _clinics = [];
  List<DoctorProfile> _doctors = [];
  Clinic? _selectedClinic;
  DoctorProfile? _selectedDoctor;
  DateTime _appointmentDate = DateTime.now().add(const Duration(days: 1));
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _loadClinics() async {
    final clinics = await widget.apiService.getClinics();
    setState(() {
      _clinics = clinics;
      _selectedClinic = clinics.isNotEmpty ? clinics.first : null;
      _loading = false;
    });
    if (_selectedClinic != null) {
      await _loadDoctors(_selectedClinic!.id);
    }
  }

  Future<void> _loadDoctors(String clinicId) async {
    final doctors = await widget.apiService.getClinicDoctors(clinicId);
    setState(() {
      _doctors = doctors;
      _selectedDoctor = doctors.isNotEmpty ? doctors.first : null;
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      initialDate: _appointmentDate,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_appointmentDate),
    );
    if (time == null) return;

    setState(() {
      _appointmentDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (_selectedClinic == null || _selectedDoctor == null || _complaintController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заполните заявку')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.apiService.createAppointment(
        doctorId: _selectedDoctor!.user.id,
        clinicId: _selectedClinic!.id,
        appointmentDate: _appointmentDate,
        complaint: _complaintController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заявка отправлена')));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Записаться к врачу')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<Clinic>(
                  initialValue: _selectedClinic,
                  decoration: const InputDecoration(labelText: 'Клиника'),
                  items: _clinics
                      .map((clinic) => DropdownMenuItem(value: clinic, child: Text(clinic.name)))
                      .toList(),
                  onChanged: (clinic) {
                    if (clinic == null) return;
                    setState(() => _selectedClinic = clinic);
                    _loadDoctors(clinic.id);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<DoctorProfile>(
                  initialValue: _selectedDoctor,
                  decoration: const InputDecoration(labelText: 'Врач'),
                  items: _doctors
                      .map(
                        (doctor) => DropdownMenuItem(
                          value: doctor,
                          child: Text('${doctor.user.fullName} · ${doctor.specialization}'),
                        ),
                      )
                      .toList(),
                  onChanged: (doctor) => setState(() => _selectedDoctor = doctor),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickDateTime,
                  icon: const Icon(Icons.event),
                  label: Text(DateFormat('dd.MM.yyyy HH:mm').format(_appointmentDate)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _complaintController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Жалоба'),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: const Icon(Icons.send),
                  label: Text(_submitting ? 'Отправка...' : 'Отправить заявку'),
                ),
              ],
            ),
    );
  }
}
