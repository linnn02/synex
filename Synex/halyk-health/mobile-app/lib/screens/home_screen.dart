import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import '../widgets/health_card.dart';
import 'create_appointment_screen.dart';
import 'market_products_screen.dart';
import 'medication_schedule_screen.dart';
import 'my_appointments_screen.dart';
import 'my_prescriptions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.apiService,
    required this.user,
  });

  final ApiService apiService;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Halyk Health')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF003C3A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Записи, назначения, аптека и график приёма',
                  style: TextStyle(color: Color(0xFFD6F5EE)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          HealthCard(
            icon: Icons.calendar_month,
            title: 'Записаться к врачу',
            subtitle: 'Выбор клиники, врача и времени',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateAppointmentScreen(apiService: apiService)),
            ),
          ),
          HealthCard(
            icon: Icons.assignment_turned_in,
            title: 'Мои записи',
            subtitle: 'Статусы заявок и визитов',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MyAppointmentsScreen(apiService: apiService)),
            ),
          ),
          HealthCard(
            icon: Icons.medical_information,
            title: 'Мои назначения',
            subtitle: 'Назначения врача и AI-объяснение',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MyPrescriptionsScreen(apiService: apiService)),
            ),
          ),
          HealthCard(
            icon: Icons.local_pharmacy,
            title: 'Аптека',
            subtitle: 'Товары, цены и наличие',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MarketProductsScreen(apiService: apiService)),
            ),
          ),
          HealthCard(
            icon: Icons.schedule,
            title: 'График приёма',
            subtitle: 'Отметки “принял” и “пропустил”',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MedicationScheduleScreen(apiService: apiService)),
            ),
          ),
        ],
      ),
    );
  }
}

