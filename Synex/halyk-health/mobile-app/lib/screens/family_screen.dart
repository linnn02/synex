import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';

const _green = Color(0xFF007F5F);
const _dark = Color(0xFF073E35);
const _bg = Color(0xFFF4F7F8);

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  List<PatientProfile> _profiles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.apiService.getPatientProfiles();
      if (!mounted) return;
      setState(() {
        _profiles = data;
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

  void _showAddMember() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMemberSheet(
        onAdd: (name, relation, insurance, iin) async {
          await widget.apiService.createPatientProfile(
            fullName: name,
            relationType: relation,
            insuranceStatus: insurance,
            iin: iin.isEmpty ? null : iin,
          );
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Моя семья', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: _dark,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Члены семьи',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    ..._profiles.map((p) => _FamilyMemberCard(profile: p)),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _showAddMember,
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Добавить родственника'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _InfoBox(
                      icon: Icons.shield_outlined,
                      title: 'Общая страховка',
                      text: 'Если у вас семейная страховка Halyk Health, данные подтянутся автоматически при добавлении ИИН родственника.',
                    ),
                  ],
                ),
    );
  }
}

class _FamilyMemberCard extends StatelessWidget {
  const _FamilyMemberCard({required this.profile});
  final PatientProfile profile;

  @override
  Widget build(BuildContext context) {
    final isSelf = profile.relationType == 'SELF';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAEC)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelf ? _green.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSelf ? Icons.person : Icons.people_outline,
              color: isSelf ? _green : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Text(
                  profile.relationLabel,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ),
          _InsuranceBadge(status: profile.insuranceStatus),
        ],
      ),
    );
  }
}

class _InsuranceBadge extends StatelessWidget {
  const _InsuranceBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final active = status == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEAF7F2) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        active ? 'Застрахован' : 'Без страховки',
        style: TextStyle(
          color: active ? _green : const Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet({required this.onAdd});
  final Function(String name, String relation, String insurance, String iin) onAdd;

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _nameController = TextEditingController();
  final _iinController = TextEditingController();
  String _relation = 'CHILD';
  String _insurance = 'ACTIVE';
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Новый профиль',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Кем вам приходится?', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _relation,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: const [
              DropdownMenuItem(value: 'CHILD', child: Text('Ребёнок')),
              DropdownMenuItem(value: 'MOTHER', child: Text('Мама')),
              DropdownMenuItem(value: 'FATHER', child: Text('Папа')),
              DropdownMenuItem(value: 'GRANDMOTHER', child: Text('Бабушка')),
              DropdownMenuItem(value: 'GRANDFATHER', child: Text('Дедушка')),
              DropdownMenuItem(value: 'OTHER', child: Text('Другое')),
            ],
            onChanged: (v) => setState(() => _relation = v!),
          ),
          const SizedBox(height: 16),
          const Text('ФИО', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Иван Иванов',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          const Text('ИИН (необязательно)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _iinController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '12 цифр',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _submitting ? null : () async {
                if (_nameController.text.isEmpty) return;
                setState(() => _submitting = true);
                try {
                  await widget.onAdd(_nameController.text, _relation, _insurance, _iinController.text);
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  setState(() => _submitting = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Создать профиль'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAEC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: Color(0xFF64748B), height: 1.35, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
