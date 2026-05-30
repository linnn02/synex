import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';

const _green = Color(0xFF006B5B);
const _bg = Color(0xFFF5F7F8);

class MedicationScheduleScreen extends StatefulWidget {
  const MedicationScheduleScreen({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<MedicationScheduleScreen> createState() => _MedicationScheduleScreenState();
}

class _MedicationScheduleScreenState extends State<MedicationScheduleScreen> {
  List<MedicationScheduleItem> _items = [];
  List<PatientProfile> _profiles = [];
  PatientProfile? _selectedProfile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final profiles = await widget.apiService.getPatientProfiles();
      setState(() {
        _profiles = profiles;
        if (profiles.isNotEmpty) {
          _selectedProfile = profiles.firstWhere(
            (p) => p.relationType == 'SELF',
            orElse: () => profiles.first,
          );
        }
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.apiService.getMySchedule(
        patientProfileId: _selectedProfile?.id,
      );
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _markTaken(String id) async {
    try {
      await widget.apiService.markScheduleTaken(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _markMissed(String id) async {
    try {
      await widget.apiService.markScheduleMissed(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('График приёма', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: Column(
        children: [
          _buildFamilyFilter(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _green))
                : _error != null
                    ? Center(child: Text(_error!))
                    : _items.isEmpty
                        ? const Center(child: Text('График появится после анализа назначения'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return _ScheduleCard(
                                item: item,
                                onTaken: () => _markTaken(item.id),
                                onMissed: () => _markMissed(item.id),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyFilter() {
    if (_profiles.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _profiles.length,
        itemBuilder: (context, index) {
          final profile = _profiles[index];
          final isSelected = _selectedProfile?.id == profile.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(profile.fullName),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedProfile = profile);
                  _load();
                }
              },
              selectedColor: _green,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.item, required this.onTaken, required this.onMissed});
  final MedicationScheduleItem item;
  final VoidCallback onTaken;
  final VoidCallback onMissed;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: _green, size: 20),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd.MM.yyyy HH:mm').format(item.takeTime),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const Spacer(),
                _StatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${item.prescriptionMedicine.medicineName} ${item.prescriptionMedicine.dosage}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.prescriptionMedicine.frequency} · ${item.prescriptionMedicine.instruction}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            if (item.status == 'PLANNED') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onTaken,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Принял'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onMissed,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Пропустил'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB23A2F),
                        side: const BorderSide(color: Color(0xFFFBECEB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'TAKEN' => Colors.green,
      'MISSED' => Colors.red,
      _ => Colors.orange,
    };
    final label = switch (status) {
      'TAKEN' => 'Принято',
      'MISSED' => 'Пропущено',
      _ => 'Запланировано',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
