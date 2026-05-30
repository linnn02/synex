import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import 'create_appointment_screen.dart';
import 'prescription_detail_screen.dart';

// ─── Halyk color palette ───────────────────────────────────────────────────
const _green = Color(0xFF006B5B);
const _greenDark = Color(0xFF004D3E);
const _greenLight = Color(0xFFE6F4F1);
const _gold = Color(0xFFF0A500);
const _goldLight = Color(0xFFFFF8E7);
const _bg = Color(0xFFF5F7F8);
const _dark = Color(0xFF073E35);

// ─── Status helpers ────────────────────────────────────────────────────────
enum _Filter { all, active, pending, history, cancelled }

extension _FilterLabel on _Filter {
  String get label => switch (this) {
        _Filter.all => 'Все',
        _Filter.active => 'Активные',
        _Filter.pending => 'Ожидают',
        _Filter.history => 'История',
        _Filter.cancelled => 'Отменённые',
      };

  bool matches(Appointment a) => switch (this) {
        _Filter.all => true,
        _Filter.active => a.status == 'CONFIRMED' || a.status == 'RESCHEDULED',
        _Filter.pending => a.status == 'PENDING',
        _Filter.history => a.status == 'COMPLETED',
        _Filter.cancelled => a.status == 'CANCELLED',
      };
}

String _statusLabel(String s) => switch (s) {
      'PENDING' => 'Ожидает',
      'CONFIRMED' => 'Подтверждён',
      'RESCHEDULED' => 'Перенесён',
      'COMPLETED' => 'Завершён',
      'CANCELLED' => 'Отменён',
      _ => s,
    };

Color _statusColor(String s) => switch (s) {
      'PENDING' => _gold,
      'CONFIRMED' => _green,
      'RESCHEDULED' => const Color(0xFF1E7FBA),
      'COMPLETED' => const Color(0xFF4A6741),
      'CANCELLED' => const Color(0xFFB23A2F),
      _ => Colors.grey,
    };

Color _statusBg(String s) => switch (s) {
      'PENDING' => _goldLight,
      'CONFIRMED' => _greenLight,
      'RESCHEDULED' => const Color(0xFFE3F2FB),
      'COMPLETED' => const Color(0xFFEDF4EC),
      'CANCELLED' => const Color(0xFFFBECEB),
      _ => const Color(0xFFF0F0F0),
    };

// ──────────────────────────────────────────────────────────────────────────
class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  List<Appointment> _appointments = [];
  List<PatientProfile> _profiles = [];
  PatientProfile? _selectedProfile;
  bool _loading = true;
  String? _error;
  _Filter _activeFilter = _Filter.all;

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
        // Don't pre-select any specific profile to show "All" by default, 
        // or we can just keep _selectedProfile as null for "All family".
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
      final data = await widget.apiService.getMyAppointments(
        patientProfileId: _selectedProfile?.id,
      );
      if (!mounted) return;
      setState(() {
        _appointments = data;
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

  Future<void> _openCreateAppointment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAppointmentScreen(apiService: widget.apiService),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  // ─── Cancel ──────────────────────────────────────────────────────────────
  Future<void> _cancelAppointment(Appointment apt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Отменить запись?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'Приём у ${apt.doctor.fullName}\n'
          '${DateFormat('dd MMMM, HH:mm', 'ru').format(apt.appointmentDate.toLocal())}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Нет')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB23A2F)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Отменить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _showLoading('Отменяем запись…');
    try {
      final updated = await widget.apiService.cancelAppointment(apt.id);
      _updateLocal(updated);
      await _load();
      if (!mounted) return;
      Navigator.pop(context); // close loading
      _showSnack('Запись отменена', isError: false);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  // ─── Reschedule ──────────────────────────────────────────────────────────
  Future<void> _rescheduleAppointment(Appointment apt) async {
    DateTime? pickedDate;
    TimeOfDay? pickedTime;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RescheduleSheet(
        onConfirm: (date, time) {
          pickedDate = date;
          pickedTime = time;
          Navigator.pop(ctx, true);
        },
      ),
    );

    if (result != true ||
        pickedDate == null ||
        pickedTime == null ||
        !mounted) {
      return;
    }

    final newDateTime = DateTime(
      pickedDate!.year,
      pickedDate!.month,
      pickedDate!.day,
      pickedTime!.hour,
      pickedTime!.minute,
    );

    _showLoading('Переносим запись…');
    try {
      final updated =
          await widget.apiService.rescheduleAppointment(apt.id, newDateTime);
      _updateLocal(updated);
      await _load();
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Запись успешно перенесена', isError: false);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  // ─── Repeat appointment ───────────────────────────────────────────────────
  Future<void> _repeatAppointment(Appointment apt) async {
    _showLoading('Создаём новую запись…');
    try {
      await widget.apiService.createAppointment(
        patientProfileId: apt.patientProfile?.id ?? '',
        doctorId: apt.doctor.id,
        clinicId: apt.clinic.id,
        appointmentDate: DateTime.now().add(const Duration(days: 1)),
        complaint: 'Повторный приём',
      );
      await _load();
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Новая запись создана', isError: false);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  // ─── Open prescription ────────────────────────────────────────────────────
  Future<void> _openPrescription(Appointment apt) async {
    if (apt.prescriptionId == null) {
      _showSnack('Назначение пока не добавлено', isError: false);
      return;
    }
    _showLoading('Загружаем назначение…');
    try {
      final prescription =
          await widget.apiService.getPrescriptionById(apt.prescriptionId!);
      if (!mounted) return;
      Navigator.pop(context); // close loading
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrescriptionDetailScreen(
            apiService: widget.apiService,
            prescription: prescription,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showAppointmentDetails(Appointment apt) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final localDate = apt.appointmentDate.toLocal();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      apt.doctor.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A2B33),
                      ),
                    ),
                  ),
                  _StatusBadge(status: apt.status),
                ],
              ),
              const SizedBox(height: 16),
              if (apt.patientProfile != null) ...[
                _DetailRow(
                  icon: Icons.person_outline,
                  label: apt.patientProfile!.fullName,
                  sub: apt.patientProfile!.relationLabel,
                ),
                const SizedBox(height: 10),
              ],
              _DetailRow(
                icon: Icons.medical_services_outlined,
                label: apt.specialization ?? 'Врач',
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.local_hospital_outlined,
                label: apt.clinic.name,
                sub: apt.clinic.address,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.event_available_outlined,
                label:
                    DateFormat('dd MMMM yyyy, HH:mm', 'ru').format(localDate),
                sub:
                    apt.roomNumber == null ? null : 'Кабинет ${apt.roomNumber}',
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.chat_bubble_outline,
                label: 'Причина обращения',
                sub: apt.complaint,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(backgroundColor: _green),
                  child: const Text('Закрыть'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  void _updateLocal(Appointment updated) {
    setState(() {
      final idx = _appointments.indexWhere((a) => a.id == updated.id);
      if (idx != -1) _appointments[idx] = updated;
    });
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFB23A2F) : _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showLoading(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: _green),
              const SizedBox(height: 14),
              Text(msg, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _appointments.where(_activeFilter.matches).toList();

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          SliverToBoxAdapter(child: _buildFamilyFilter()),
          SliverToBoxAdapter(child: _buildFilterBar()),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _green)),
            )
          else if (_error != null)
            SliverFillRemaining(
                child: _ErrorState(error: _error!, onRetry: _load))
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                filter: _activeFilter,
                onNewAppointment: _openCreateAppointment,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AppointmentCard(
                      appointment: filtered[i],
                      onCancel: () => _cancelAppointment(filtered[i]),
                      onReschedule: () => _rescheduleAppointment(filtered[i]),
                      onDetails: () => _showAppointmentDetails(filtered[i]),
                      onOpenPrescription: () => _openPrescription(filtered[i]),
                      onRepeat: () => _repeatAppointment(filtered[i]),
                    ),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_greenDark, _green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 20,
          right: 20,
          bottom: 24,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Мои записи',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Следите за статусом приёмов и историей всей семьи',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _GoldButton(
              label: 'Новая\nзапись',
              icon: Icons.add_circle_outline,
              onTap: _openCreateAppointment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyFilter() {
    if (_profiles.isEmpty) return const SizedBox.shrink();
    
    return Container(
      color: Colors.white,
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _profiles.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final profile = isAll ? null : _profiles[index - 1];
          final isSelected = _selectedProfile == profile;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(isAll ? 'Все' : profile!.fullName),
              selected: isSelected,
              onSelected: (val) {
                setState(() => _selectedProfile = profile);
                _load();
              },
              selectedColor: _greenLight,
              checkmarkColor: _green,
              labelStyle: TextStyle(
                color: isSelected ? _greenDark : const Color(0xFF5A6A72),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              backgroundColor: _bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? _green : const Color(0xFFDDE3E5),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _Filter.values.map((f) {
            final isActive = f == _activeFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _activeFilter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? _green : _bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? _green : const Color(0xFFDDE3E5),
                    ),
                  ),
                  child: Text(
                    f.label,
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF5A6A72),
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Appointment Card ──────────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onCancel,
    required this.onReschedule,
    required this.onDetails,
    required this.onOpenPrescription,
    required this.onRepeat,
  });

  final Appointment appointment;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;
  final VoidCallback onDetails;
  final VoidCallback onOpenPrescription;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final apt = appointment;
    final localDate = apt.appointmentDate.toLocal();
    final dateStr = DateFormat('dd MMMM yyyy', 'ru').format(localDate);
    final timeStr = DateFormat('HH:mm').format(localDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _statusBg(apt.status),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor(apt.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusLabel(apt.status),
                  style: TextStyle(
                    color: _statusColor(apt.status),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 13, color: Color(0xFF8A9BA3)),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A9BA3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (apt.patientProfile != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: _green),
                      const SizedBox(width: 6),
                      Text(
                        '${apt.patientProfile!.fullName} (${apt.patientProfile!.relationLabel})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                // Doctor info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _greenLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person, color: _green, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apt.doctor.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF1A2B33),
                            ),
                          ),
                          if (apt.specialization != null)
                            Text(
                              apt.specialization!,
                              style: const TextStyle(
                                color: _green,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Details grid
                _DetailRow(
                  icon: Icons.local_hospital_outlined,
                  label: apt.clinic.name,
                  sub: apt.clinic.address,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(
                        icon: Icons.access_time,
                        label: 'Время',
                        value: timeStr,
                      ),
                    ),
                    if (apt.roomNumber != null)
                      Expanded(
                        child: _DetailItem(
                          icon: Icons.door_front_door_outlined,
                          label: 'Кабинет',
                          value: 'Каб. ${apt.roomNumber}',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.chat_bubble_outline,
                  label: 'Причина',
                  sub: apt.complaint,
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF0F3F4)),
                const SizedBox(height: 12),

                // Action buttons
                _buildActions(apt),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(Appointment apt) {
    switch (apt.status) {
      case 'PENDING':
        return Row(
          children: [
            Expanded(
                child: _OutlineBtn(
                    label: 'Отменить',
                    icon: Icons.close,
                    color: const Color(0xFFB23A2F),
                    onTap: onCancel)),
            const SizedBox(width: 8),
            Expanded(
                child: _FilledBtn(
                    label: 'Перенести',
                    icon: Icons.schedule,
                    onTap: onReschedule)),
          ],
        );
      case 'CONFIRMED':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _OutlineBtn(
                        label: 'Детали',
                        icon: Icons.info_outline,
                        color: _green,
                        onTap: onDetails)),
                const SizedBox(width: 8),
                Expanded(
                    child: _FilledBtn(
                        label: 'Перенести',
                        icon: Icons.schedule,
                        onTap: onReschedule)),
              ],
            ),
            const SizedBox(height: 8),
            _OutlineBtn(
              label: 'Отменить',
              icon: Icons.close,
              color: const Color(0xFFB23A2F),
              onTap: onCancel,
            ),
          ],
        );
      case 'RESCHEDULED':
        return Row(
          children: [
            Expanded(
                child: _OutlineBtn(
                    label: 'Детали',
                    icon: Icons.info_outline,
                    color: _green,
                    onTap: onDetails)),
            const SizedBox(width: 8),
            Expanded(
                child: _OutlineBtn(
                    label: 'Отменить',
                    icon: Icons.close,
                    color: const Color(0xFFB23A2F),
                    onTap: onCancel)),
          ],
        );
      case 'COMPLETED':
        return Row(
          children: [
            Expanded(
                child: _OutlineBtn(
                    label: 'Назначение',
                    icon: Icons.description_outlined,
                    color: _green,
                    onTap: onOpenPrescription)),
            const SizedBox(width: 8),
            Expanded(
                child: _FilledBtn(
                    label: 'Повторить', icon: Icons.refresh, onTap: onRepeat)),
          ],
        );
      case 'CANCELLED':
        return _FilledBtn(
            label: 'Записаться снова', icon: Icons.add, onTap: onRepeat);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Small UI components ───────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, this.sub});

  final IconData icon;
  final String label;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8A9BA3)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2B33),
                ),
              ),
              if (sub != null)
                Text(
                  sub!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A9BA3),
                    height: 1.3,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8A9BA3)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF8A9BA3)),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2B33),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusBg(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: _statusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FilledBtn extends StatelessWidget {
  const _FilledBtn({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _gold,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.onNewAppointment});
  final _Filter filter;
  final VoidCallback onNewAppointment;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.event_busy, size: 64, color: Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 24),
            Text(
              filter == _Filter.all ? 'Записей пока нет' : 'Нет записей в этой категории',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Вы можете записаться к врачу прямо сейчас через Halyk Health',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onNewAppointment,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Записаться на прием'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFB23A2F)),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({required this.onConfirm});
  final Function(DateTime date, TimeOfDay time) onConfirm;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  DateTime? _date;
  TimeOfDay? _time;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          const Text('Выберите новое время', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: _green),
            title: Text(_date == null ? 'Выберите дату' : DateFormat('dd.MM.yyyy').format(_date!)),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time, color: _green),
            title: Text(_time == null ? 'Выберите время' : _time!.format(context)),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
              if (t != null) setState(() => _time = t);
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: (_date != null && _time != null) ? () => widget.onConfirm(_date!, _time!) : null,
              style: FilledButton.styleFrom(backgroundColor: _green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Подтвердить перенос'),
            ),
          ),
        ],
      ),
    );
  }
}
