import 'package:flutter/material.dart';
import '../services/appointment_service.dart';

class PatientInfoCard extends StatelessWidget {
  final MedCarePatient patient;

  const PatientInfoCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final isActive = patient.insuranceStatus == 'active';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Данные пациента',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                        : const Color(0xFFF44336).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? Icons.check_circle : Icons.warning_rounded,
                      size: 14,
                      color: isActive
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? 'Страховка активна' : 'Страховка неактивна',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC62828),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(Icons.person_outline, 'ФИО', patient.fullName),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildInfoRow(Icons.fingerprint_outlined, 'ИИН', patient.iin),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildInfoRow(Icons.phone_outlined, 'Телефон', patient.phone),
          if (!isActive) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFFFF9C4), // Golden/yellow alert background
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFBC02D).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFFF57F17), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Внимание! У вас отсутствует активная страховка. Доступна только запись на платной основе.',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFF57F17).withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
