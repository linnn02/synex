import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import 'prescription_detail_screen.dart';

const _green = Color(0xFF006B5B);
const _bg = Color(0xFFF5F7F8);

class MyPrescriptionsScreen extends StatefulWidget {
  const MyPrescriptionsScreen({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<MyPrescriptionsScreen> createState() => _MyPrescriptionsScreenState();
}

class _MyPrescriptionsScreenState extends State<MyPrescriptionsScreen> {
  List<Prescription> _prescriptions = [];
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
      final data = await widget.apiService.getMyPrescriptions(
        patientProfileId: _selectedProfile?.id,
      );
      if (!mounted) return;
      setState(() {
        _prescriptions = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Мои назначения', style: TextStyle(fontWeight: FontWeight.w800)),
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
                    : _prescriptions.isEmpty
                        ? const Center(child: Text('Назначений пока нет'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _prescriptions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final p = _prescriptions[index];
                              return _PrescriptionCard(
                                prescription: p,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PrescriptionDetailScreen(
                                      apiService: widget.apiService,
                                      prescription: p,
                                    ),
                                  ),
                                ),
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
        itemCount: _profiles.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final profile = isAll ? null : _profiles[index - 1];
          final isSelected = _selectedProfile == profile;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(isAll ? 'Все' : profile!.fullName),
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

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.prescription, required this.onTap});
  final Prescription prescription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (prescription.patientProfile != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: _green),
                    const SizedBox(width: 6),
                    Text(
                      '${prescription.patientProfile!.fullName} (${prescription.patientProfile!.relationLabel})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Icon(Icons.assignment_outlined, color: _green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prescription.diagnosis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prescription.aiSummary ?? prescription.rawText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
