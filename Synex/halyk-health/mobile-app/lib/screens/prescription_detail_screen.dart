import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import 'market_products_screen.dart';

const _green = Color(0xFF007F5F);
const _dark = Color(0xFF073E35);
const _bg = Color(0xFFF4F7F8);
const _muted = Color(0xFF64748B);

class PrescriptionDetailScreen extends StatefulWidget {
  const PrescriptionDetailScreen({
    super.key,
    required this.apiService,
    required this.prescription,
  });

  final ApiService apiService;
  final Prescription prescription;

  @override
  State<PrescriptionDetailScreen> createState() =>
      _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {
  late Prescription _prescription;
  List<MedicineProductGroup> _groups = [];
  List<MedicationScheduleItem> _scheduleItems = [];
  bool _analyzing = false;
  bool _loadingProducts = false;
  bool _loadingSchedule = false;

  @override
  void initState() {
    super.initState();
    _prescription = widget.prescription;
    if (_prescription.medicines.isNotEmpty) {
      _loadProducts();
      _loadSchedule();
    }
  }

  Future<void> _analyze() async {
    setState(() => _analyzing = true);
    try {
      final analyzed =
          await widget.apiService.analyzePrescription(_prescription.id);
      if (!mounted) return;
      setState(() => _prescription = analyzed);
      await _loadProducts();
      await _loadSchedule();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _loadSchedule() async {
    setState(() => _loadingSchedule = true);
    try {
      final schedule =
          await widget.apiService.getPrescriptionSchedule(_prescription.id);
      if (!mounted) return;
      setState(() {
        _scheduleItems = schedule;
        _loadingSchedule = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSchedule = false);
    }
  }

  Future<void> _markTaken(String id) async {
    try {
      await widget.apiService.markScheduleTaken(id);
      await _loadSchedule();
    } catch (_) {}
  }

  Future<void> _markMissed(String id) async {
    try {
      await widget.apiService.markScheduleMissed(id);
      await _loadSchedule();
    } catch (_) {}
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final groups =
          await widget.apiService.getPrescriptionMarketProducts(_prescription.id);
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProducts = false);
    }
  }

  Future<void> _addToCart(MarketProduct product) async {
    await widget.apiService.addToCart(
      product.id,
      patientProfileId: _prescription.patientProfile?.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.title} добавлен в корзину')),
    );
  }

  void _openChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiChatSheet(
        apiService: widget.apiService,
        prescription: _prescription,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAi = _prescription.aiSummary != null;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Назначение',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _dark,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          _HeaderCard(prescription: _prescription),
          const SizedBox(height: 14),
          _InfoBlock(
            step: '1',
            title: 'Назначение врача',
            text: _prescription.rawText,
            icon: Icons.edit_note_outlined,
          ),
          if (_prescription.doctorComment?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _InfoBlock(
              step: '2',
              title: 'Комментарий врача',
              text: _prescription.doctorComment!,
              icon: Icons.medical_information_outlined,
            ),
          ],
          const SizedBox(height: 12),
          _InfoBlock(
            step: hasAi ? '3' : 'AI',
            title: hasAi ? 'Расшифровка AI простым языком' : 'AI ещё не расшифровал',
            text: hasAi
                ? _prescription.aiSummary!
                : 'Нажмите кнопку ниже. AI структурирует только текст врача: лекарства, дозировки, график и товары в аптеке.',
            icon: Icons.auto_awesome_outlined,
            highlighted: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _analyzing ? null : _analyze,
              icon: _analyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_analyzing ? 'Анализируем...' : 'Расшифровать AI'),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'График лечения',
            action: _loadingSchedule ? '...' : 'Сегодня',
            onAction: () {},
          ),
          const SizedBox(height: 10),
          if (_loadingSchedule && _scheduleItems.isEmpty)
            const Center(child: CircularProgressIndicator(color: _green))
          else if (_scheduleItems.isEmpty)
            const _SmallEmpty(
              icon: Icons.calendar_today_outlined,
              title: 'График пуст',
              text: 'Расписание появится после проведения AI-анализа.',
            )
          else
            _PrescriptionScheduleBlock(
              items: _scheduleItems,
              onTaken: _markTaken,
              onMissed: _markMissed,
            ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_bubble_outline, color: _green),
              label: const Text('Спросить ИИ по назначению',
                  style: TextStyle(color: _green)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _green, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Лекарства из назначения',
            action: 'Открыть аптеку',
            onAction: () => _openMarket(),
          ),
          const SizedBox(height: 10),
          if (_prescription.medicines.isEmpty)
            const _EmptyMedicines()
          else
            ..._prescription.medicines.map((medicine) => _MedicineCard(medicine: medicine)),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Предложения в аптеке',
            action: _loadingProducts ? 'Загрузка...' : 'Все товары',
            onAction: _openMarket,
          ),
          const SizedBox(height: 10),
          if (_loadingProducts && _groups.isEmpty)
            const Center(child: CircularProgressIndicator(color: _green))
          else if (_groups.isEmpty)
             const _ProductsEmpty()
          else
            ..._groups.map(
              (group) => _ProductGroup(
                group: group,
                onAdd: _addToCart,
              ),
            ),
          const SizedBox(height: 14),
          _SafetyBox(
            text: _prescription.aiDisclaimer ??
                'ИИ-агент не заменяет врача. Он объясняет назначение, созданное врачом. Перед заменой препарата проконсультируйтесь с врачом или фармацевтом.',
          ),
        ],
      ),
    );
  }

  void _openMarket() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarketProductsScreen(
          apiService: widget.apiService,
          prescriptionId: _prescription.id,
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.prescription});

  final Prescription prescription;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_dark, _green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Цифровое назначение',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  prescription.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (prescription.patientProfile != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 14, color: Colors.white.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(
                  '${prescription.patientProfile!.fullName} (${prescription.patientProfile!.relationLabel})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            prescription.diagnosis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${prescription.medicines.length} препаратов · AI ${prescription.aiSummary == null ? 'ожидает анализа' : 'готов'}',
            style: const TextStyle(color: Color(0xD9FFFFFF)),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.step,
    required this.title,
    required this.text,
    required this.icon,
    this.highlighted = false,
  });

  final String step;
  final String title;
  final String text;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFEAF7F2) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? const Color(0xFFBDE8D9) : const Color(0xFFE2EAEC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: highlighted ? _green : const Color(0xFFF1F5F9),
                child: Text(
                  step,
                  style: TextStyle(
                    color: highlighted ? Colors.white : _dark,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 20, color: highlighted ? _green : _muted),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(height: 1.45)),
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({required this.medicine});

  final PrescriptionMedicine medicine;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.medication_outlined, color: _green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${medicine.medicineName} ${medicine.dosage}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  '${medicine.frequency} · ${medicine.duration}\n${medicine.instruction}',
                  style: const TextStyle(color: _muted, height: 1.35),
                ),
              ],
            ),
          ),
          Text(
            'x${medicine.quantityNeeded}',
            style: const TextStyle(fontWeight: FontWeight.w900, color: _green),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionScheduleBlock extends StatelessWidget {
  const _PrescriptionScheduleBlock({
    required this.items,
    required this.onTaken,
    required this.onMissed,
  });

  final List<MedicationScheduleItem> items;
  final Function(String id) onTaken;
  final Function(String id) onMissed;

  @override
  Widget build(BuildContext context) {
    final morning = items.where((i) => i.takeTime.hour < 12).toList();
    final day = items.where((i) => i.takeTime.hour >= 12 && i.takeTime.hour < 17).toList();
    final evening = items.where((i) => i.takeTime.hour >= 17).toList();

    return Column(
      children: [
        if (morning.isNotEmpty) _PeriodBlock(title: "Утро", items: morning, onTaken: onTaken, onMissed: onMissed),
        if (day.isNotEmpty) _PeriodBlock(title: "День", items: day, onTaken: onTaken, onMissed: onMissed),
        if (evening.isNotEmpty) _PeriodBlock(title: "Вечер", items: evening, onTaken: onTaken, onMissed: onMissed),
      ],
    );
  }
}

class _PeriodBlock extends StatelessWidget {
  const _PeriodBlock({
    required this.title,
    required this.items,
    required this.onTaken,
    required this.onMissed,
  });

  final String title;
  final List<MedicationScheduleItem> items;
  final Function(String id) onTaken;
  final Function(String id) onMissed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: _muted)),
        ),
        ...items.take(3).map((item) => _ScheduleRow(item: item, onTaken: onTaken, onMissed: onMissed)),
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.item, required this.onTaken, required this.onMissed});
  final MedicationScheduleItem item;
  final Function(String id) onTaken;
  final Function(String id) onMissed;

  @override
  Widget build(BuildContext context) {
    final taken = item.status == "TAKEN";
    final missed = item.status == "MISSED";

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAEC).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.prescriptionMedicine.medicineName, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text("${item.takeTime.hour}:00 · ${item.prescriptionMedicine.dosage}", style: const TextStyle(fontSize: 12, color: _muted)),
              ],
            ),
          ),
          if (!taken && !missed) ...[
            IconButton(onPressed: () => onMissed(item.id), icon: const Icon(Icons.close, color: Colors.redAccent, size: 20)),
            IconButton(onPressed: () => onTaken(item.id), icon: const Icon(Icons.check, color: _green, size: 20)),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: taken ? const Color(0xFFEAF7F2) : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(taken ? "Принято" : "Пропущено", 
                style: TextStyle(color: taken ? _green : Colors.red, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}

class _ProductGroup extends StatelessWidget {
  const _ProductGroup({
    required this.group,
    required this.onAdd,
  });

  final MedicineProductGroup group;
  final Future<void> Function(MarketProduct product) onAdd;

  @override
  Widget build(BuildContext context) {
    final products = group.products.take(2).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.prescriptionMedicine.medicineName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Подобрано по действующему веществу. Аналог не означает автоматическую замену.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 10),
          if (products.isEmpty)
            const Text('Товары пока не найдены', style: TextStyle(color: _muted))
          else
            ...products.map((product) => _InlineProduct(product: product, onAdd: onAdd)),
        ],
      ),
    );
  }
}

class _InlineProduct extends StatelessWidget {
  const _InlineProduct({
    required this.product,
    required this.onAdd,
  });

  final MarketProduct product;
  final Future<void> Function(MarketProduct product) onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  '${product.form} · ${product.pharmacyName} · ${product.stock} шт.',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(product.priceText, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              FilledButton(
                onPressed: () => onAdd(product),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('В корзину'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(action)),
      ],
    );
  }
}

class _SafetyBox extends StatelessWidget {
  const _SafetyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE08A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF9A6B00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF6F4D00),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMedicines extends StatelessWidget {
  const _EmptyMedicines();

  @override
  Widget build(BuildContext context) {
    return const _SmallEmpty(
      icon: Icons.medication_outlined,
      title: 'Лекарства ещё не выделены',
      text: 'Запустите AI-анализ или дождитесь структурированного назначения врача.',
    );
  }
}

class _ProductsEmpty extends StatelessWidget {
  const _ProductsEmpty();

  @override
  Widget build(BuildContext context) {
    return const _SmallEmpty(
      icon: Icons.local_pharmacy_outlined,
      title: 'Товары появятся после анализа',
      text: 'Когда будут выделены лекарства, маркет покажет цены, наличие и аналоги.',
    );
  }
}

class _SmallEmpty extends StatelessWidget {
  const _SmallEmpty({
    required this.icon,
    required this.title,
    required this.text,
  });

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
      ),
      child: Row(
        children: [
          Icon(icon, color: _muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: _muted, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiChatSheet extends StatefulWidget {
  const _AiChatSheet({required this.apiService, required this.prescription});
  final ApiService apiService;
  final Prescription prescription;

  @override
  State<_AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<_AiChatSheet> {
  final _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'content': 'Здравствуйте! Я ваш ИИ-ассистент по назначению. Могу объяснить дозировки, график или помочь с поиском лекарств. О чем вы хотели бы узнать?'}
  ];
  bool _loading = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
    });
    _controller.clear();

    try {
      final response = await widget.apiService.explainPrescription(widget.prescription.id);
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Простите, возникла ошибка при обращении к ИИ.'});
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: _green),
              const SizedBox(width: 10),
              const Expanded(child: Text('Чат с ИИ по назначению', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? _green : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(m['content']!, style: TextStyle(color: isUser ? Colors.white : _dark)),
                  ),
                );
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(color: _green),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Ваш вопрос...',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _send, icon: const Icon(Icons.send, color: _green)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('ИИ может ошибаться. Не меняйте лечение без врача.', style: TextStyle(fontSize: 10, color: _muted)),
        ],
      ),
    );
  }
}
