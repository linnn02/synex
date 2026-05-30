import 'package:flutter/material.dart';
import '../services/appointment_service.dart';

class AppointmentSuccessCard extends StatelessWidget {
  final MedCareAppointment appointment;
  final MedCareClinic clinic;
  final MedCareDoctor doctor;
  final VoidCallback onClose;

  const AppointmentSuccessCard({
    super.key,
    required this.appointment,
    required this.clinic,
    required this.doctor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A884).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lottie-like Animated Checkmark Container
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFC8E6C9),
                width: 4,
              ),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF00A884),
              size: 48,
            ),
          ),
          const SizedBox(height: 18),

          // Success Titles
          const Text(
            'Заявка успешно отправлена!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1), // Golden yellow background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFB300), // Golden circle indicator
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Статус: Ожидает подтверждения',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB78103),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Beautiful Styled Summary Ticket
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTicketRow(
                    Icons.local_hospital_outlined, 'Поликлиника', clinic.name),
                const Divider(height: 20, color: Color(0xFFE2E8F0)),
                _buildTicketRow(Icons.person_outline, 'Лечащий врач',
                    '${doctor.fullName} (${doctor.specialization})'),
                const Divider(height: 20, color: Color(0xFFE2E8F0)),
                _buildTicketRow(
                  Icons.event_available_outlined,
                  'Дата и время приёма',
                  '${appointment.date} в ${appointment.time}',
                  valueColor: const Color(0xFF00A884),
                  fontWeight: FontWeight.bold,
                ),
                const Divider(height: 20, color: Color(0xFFE2E8F0)),
                _buildTicketRow(Icons.healing_outlined, 'Причина обращения',
                    appointment.reason),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onClose,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00A884),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Вернуться на главную',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    FontWeight? fontWeight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: valueColor ?? const Color(0xFF334155),
                  fontWeight: fontWeight ?? FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
