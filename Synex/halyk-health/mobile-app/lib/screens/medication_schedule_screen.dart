import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';

class MedicationScheduleScreen extends StatefulWidget {
  const MedicationScheduleScreen({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<MedicationScheduleScreen> createState() => _MedicationScheduleScreenState();
}

class _MedicationScheduleScreenState extends State<MedicationScheduleScreen> {
  late Future<List<MedicationScheduleItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiService.getMySchedule();
  }

  void _reload() {
    setState(() {
      _future = widget.apiService.getMySchedule();
    });
  }

  Future<void> _markTaken(String id) async {
    await widget.apiService.markScheduleTaken(id);
    _reload();
  }

  Future<void> _markMissed(String id) async {
    await widget.apiService.markScheduleMissed(id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('График приёма')),
      body: FutureBuilder<List<MedicationScheduleItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('График появится после AI-анализа назначения'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: Color(0xFF007F6D)),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd.MM.yyyy HH:mm').format(item.takeTime),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const Spacer(),
                          Chip(label: Text(item.status), side: BorderSide.none),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${item.prescriptionMedicine.medicineName} ${item.prescriptionMedicine.dosage}'),
                      Text(
                        '${item.prescriptionMedicine.frequency} · ${item.prescriptionMedicine.instruction}',
                        style: const TextStyle(color: Color(0xFF60727F)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _markTaken(item.id),
                              icon: const Icon(Icons.check),
                              label: const Text('Принял'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _markMissed(item.id),
                              icon: const Icon(Icons.close),
                              label: const Text('Пропустил'),
                            ),
                          ),
                        ],
                      ),
                    ],
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

