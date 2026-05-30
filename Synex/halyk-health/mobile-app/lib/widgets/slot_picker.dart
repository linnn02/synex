import 'package:flutter/material.dart';
import '../services/appointment_service.dart';

class SlotPicker extends StatefulWidget {
  final List<AppointmentSlot> slots;
  final Function(String date, String time) onSelected;

  const SlotPicker({
    super.key,
    required this.slots,
    required this.onSelected,
  });

  @override
  State<SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends State<SlotPicker> {
  String? _selectedDate;
  String? _selectedTime;

  @override
  void didUpdateWidget(covariant SlotPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset selection if slots list changes
    if (widget.slots != oldWidget.slots) {
      setState(() {
        _selectedDate = null;
        _selectedTime = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Group unique dates
    final uniqueDates = widget.slots
        .map((s) => s.date)
        .toSet()
        .toList();

    // 2. Filter slots for selected date
    final dailySlots = _selectedDate == null
        ? <AppointmentSlot>[]
        : widget.slots.where((s) => s.date == _selectedDate).toList();

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
            'Выбор даты и времени',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          
          // Date Picker (Horizontal list)
          const Text(
            'Доступные даты',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          uniqueDates.isEmpty
              ? const Text('Нет доступных дат для записи', style: TextStyle(color: Colors.red, fontSize: 13))
              : SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: uniqueDates.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final dateStr = uniqueDates[index];
                      final isSelected = _selectedDate == dateStr;

                      // Format date label (e.g. "31" above "Май")
                      final parts = dateStr.split('.');
                      String day = parts[0];
                      String monthStr = 'Месяц';
                      if (parts.length > 1) {
                        final mNum = int.tryParse(parts[1]) ?? 1;
                        const months = ['', 'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];
                        monthStr = months[mNum];
                      }

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = dateStr;
                            _selectedTime = null; // reset time
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 60,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00A884) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF00A884) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                monthStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white.withOpacity(0.8) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          
          // Time Picker (Grid of slots)
          if (_selectedDate != null) ...[
            const SizedBox(height: 20),
            const Text(
              'Свободное время',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.0,
              ),
              itemCount: dailySlots.length,
              itemBuilder: (context, index) {
                final slot = dailySlots[index];
                final isAvailable = slot.isAvailable;
                final isSelected = _selectedTime == slot.time;

                return GestureDetector(
                  onTap: isAvailable
                      ? () {
                          setState(() {
                            _selectedTime = slot.time;
                          });
                          widget.onSelected(_selectedDate!, slot.time);
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFB300) // Golden / Accent highlight
                          : (isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFFB300)
                            : (isAvailable ? const Color(0xFF00A884).withOpacity(0.3) : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Text(
                      slot.time,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isAvailable ? const Color(0xFF2E7D32) : const Color(0xFF94A3B8)),
                        decoration: isAvailable ? null : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
