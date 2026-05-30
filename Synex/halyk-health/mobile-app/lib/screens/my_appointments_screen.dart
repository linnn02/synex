import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  late Future<List<Appointment>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiService.getMyAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои записи')),
      body: FutureBuilder<List<Appointment>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final appointments = snapshot.data!;
          if (appointments.isEmpty) {
            return const Center(child: Text('Записей пока нет'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: Text(appointment.doctor.fullName),
                  subtitle: Text(
                    '${appointment.clinic.name}\n${DateFormat('dd.MM.yyyy HH:mm').format(appointment.appointmentDate)}',
                  ),
                  trailing: _StatusChip(status: appointment.status),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'CONFIRMED' => const Color(0xFF007F6D),
      'COMPLETED' => const Color(0xFF0D66BD),
      'CANCELLED' => const Color(0xFF9E2A1B),
      _ => const Color(0xFF936300),
    };

    return Chip(
      label: Text(status),
      labelStyle: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
    );
  }
}
