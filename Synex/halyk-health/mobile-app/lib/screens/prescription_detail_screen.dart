import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import 'market_products_screen.dart';

class PrescriptionDetailScreen extends StatefulWidget {
  const PrescriptionDetailScreen({
    super.key,
    required this.apiService,
    required this.prescription,
  });

  final ApiService apiService;
  final Prescription prescription;

  @override
  State<PrescriptionDetailScreen> createState() => _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {
  late Prescription _prescription;
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    _prescription = widget.prescription;
  }

  Future<void> _analyze() async {
    setState(() => _analyzing = true);
    try {
      final analyzed = await widget.apiService.analyzePrescription(_prescription.id);
      setState(() => _prescription = analyzed);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _analyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Назначение')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoBlock(title: 'Диагноз', text: _prescription.diagnosis),
          _InfoBlock(title: 'Текст врача', text: _prescription.rawText),
          if (_prescription.doctorComment != null)
            _InfoBlock(title: 'Комментарий врача', text: _prescription.doctorComment!),
          _InfoBlock(
            title: 'ИИ-объяснение',
            text: _prescription.aiSummary ?? 'AI-анализ ещё не выполнен.',
            highlighted: true,
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _analyzing ? null : _analyze,
            icon: const Icon(Icons.auto_awesome),
            label: Text(_analyzing ? 'Анализ...' : 'Расшифровать AI'),
          ),
          const SizedBox(height: 16),
          Text('Лекарства', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ..._prescription.medicines.map(
            (medicine) => Card(
              elevation: 0,
              child: ListTile(
                title: Text('${medicine.medicineName} ${medicine.dosage}'),
                subtitle: Text(
                  '${medicine.frequency} · ${medicine.duration}\n${medicine.instruction}',
                ),
                trailing: Text('x${medicine.quantityNeeded}'),
                isThreeLine: true,
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MarketProductsScreen(
                  apiService: widget.apiService,
                  prescriptionId: _prescription.id,
                ),
              ),
            ),
            icon: const Icon(Icons.local_pharmacy),
            label: const Text('Найти лекарства'),
          ),
          const SizedBox(height: 14),
          Text(
            _prescription.aiDisclaimer ??
                'ИИ-агент не заменяет врача. Он объясняет назначение, созданное врачом. Перед заменой препарата проконсультируйтесь с врачом или фармацевтом.',
            style: const TextStyle(color: Color(0xFF60727F), height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.text,
    this.highlighted = false,
  });

  final String title;
  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFE9F8F4) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(text, style: const TextStyle(height: 1.45)),
        ],
      ),
    );
  }
}

