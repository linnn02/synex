import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import 'prescription_detail_screen.dart';

class MyPrescriptionsScreen extends StatefulWidget {
  const MyPrescriptionsScreen({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<MyPrescriptionsScreen> createState() => _MyPrescriptionsScreenState();
}

class _MyPrescriptionsScreenState extends State<MyPrescriptionsScreen> {
  late Future<List<Prescription>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiService.getMyPrescriptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои назначения')),
      body: FutureBuilder<List<Prescription>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final prescriptions = snapshot.data!;
          if (prescriptions.isEmpty) {
            return const Center(child: Text('Назначений пока нет'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: prescriptions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final prescription = prescriptions[index];
              return Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.medical_information),
                  title: Text(prescription.diagnosis),
                  subtitle: Text(prescription.aiSummary ?? prescription.rawText),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrescriptionDetailScreen(
                        apiService: widget.apiService,
                        prescription: prescription,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

