import 'package:flutter/material.dart';

class ReasonSelector extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const ReasonSelector({super.key, required this.onChanged});

  @override
  State<ReasonSelector> createState() => _ReasonSelectorState();
}

class _ReasonSelectorState extends State<ReasonSelector> {
  final List<String> _predefinedReasons = [
    'Простуда / температура',
    'Головная боль',
    'Повторный приём',
    'Хроническое заболевание',
    'Получить назначение',
    'Другое'
  ];

  String? _selectedReason;
  final _otherReasonController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  void _onReasonSelected(String reason) {
    setState(() {
      _selectedReason = reason;
      _showCustomInput = reason == 'Другое';
    });

    if (reason == 'Другое') {
      widget.onChanged(_otherReasonController.text.trim());
    } else {
      widget.onChanged(reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Причина обращения',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _predefinedReasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return ChoiceChip(
                label: Text(reason),
                selected: isSelected,
                onSelected: (_) => _onReasonSelected(reason),
                selectedColor: const Color(0xFF00A884).withOpacity(0.15),
                checkmarkColor: const Color(0xFF00A884),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF00A884) : const Color(0xFF475569),
                ),
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF00A884) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              );
            }).toList(),
          ),
          if (_showCustomInput) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _otherReasonController,
              decoration: InputDecoration(
                labelText: 'Укажите причину',
                labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                floatingLabelStyle: const TextStyle(color: Color(0xFF00A884)),
                hintText: 'Опишите ваши симптомы...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00A884), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              maxLines: 2,
              onChanged: (val) => widget.onChanged(val.trim()),
            ),
          ],
        ],
      ),
    );
  }
}
