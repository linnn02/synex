import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import 'create_appointment_screen.dart';
import 'market_products_screen.dart';
import 'medication_schedule_screen.dart';
import 'my_appointments_screen.dart';
import 'my_prescriptions_screen.dart';
import 'prescription_detail_screen.dart';

const _halykGreen = Color(0xFF007F5F);
const _halykDark = Color(0xFF073E35);
const _halykGold = Color(0xFFF2B705);
const _softGreen = Color(0xFFEAF7F2);
const _surfaceBg = Color(0xFFF4F7F8);
const _textMuted = Color(0xFF64747D);

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.apiService,
    required this.user,
  });

  final ApiService apiService;
  final AppUser user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  Future<void> _openAppointmentFlow() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAppointmentScreen(
          apiService: widget.apiService,
          currentUser: widget.user,
        ),
      ),
    );
    if (mounted) {
      setState(() => _index = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeOverview(
        apiService: widget.apiService,
        user: widget.user,
        onBook: _openAppointmentFlow,
        onOpenAppointments: () => setState(() => _index = 1),
        onOpenPrescriptions: () => setState(() => _index = 2),
        onOpenMarket: () => setState(() => _index = 3),
        onOpenSchedule: () => setState(() => _index = 4),
      ),
      MyAppointmentsScreen(apiService: widget.apiService),
      MyPrescriptionsScreen(apiService: widget.apiService),
      MarketProductsScreen(apiService: widget.apiService),
      MedicationScheduleScreen(apiService: widget.apiService),
    ];

    return Scaffold(
      backgroundColor: _surfaceBg,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: _softGreen,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Записи',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Назначения',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_pharmacy_outlined),
            selectedIcon: Icon(Icons.local_pharmacy),
            label: 'Аптека',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm),
            label: 'График',
          ),
        ],
      ),
    );
  }
}

class _HomeOverview extends StatefulWidget {
  const _HomeOverview({
    required this.apiService,
    required this.user,
    required this.onBook,
    required this.onOpenAppointments,
    required this.onOpenPrescriptions,
    required this.onOpenMarket,
    required this.onOpenSchedule,
  });

  final ApiService apiService;
  final AppUser user;
  final VoidCallback onBook;
  final VoidCallback onOpenAppointments;
  final VoidCallback onOpenPrescriptions;
  final VoidCallback onOpenMarket;
  final VoidCallback onOpenSchedule;

  @override
  State<_HomeOverview> createState() => _HomeOverviewState();
}

class _HomeOverviewState extends State<_HomeOverview> {
  late Future<_HomeSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeSnapshot> _load() async {
    final appointmentsFuture = widget.apiService
        .getMyAppointments()
        .catchError((_) => <Appointment>[]);
    final prescriptionsFuture = widget.apiService
        .getMyPrescriptions()
        .catchError((_) => <Prescription>[]);
    final scheduleFuture =
        widget.apiService.getMySchedule().catchError((_) => <MedicationScheduleItem>[]);

    return _HomeSnapshot(
      appointments: await appointmentsFuture,
      prescriptions: await prescriptionsFuture,
      schedule: await scheduleFuture,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _future = _load());
        await _future;
      },
      color: _halykGreen,
      child: FutureBuilder<_HomeSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const _HomeSnapshot();
          final nextAppointment = data.nextAppointment;
          final latestPrescription = data.latestPrescription;
          final nextSchedule = data.nextScheduleItem;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeroHeader(
                  user: widget.user,
                  nextAppointment: nextAppointment,
                  onBook: widget.onBook,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                sliver: SliverList.list(
                  children: [
                    _QuickActions(
                      onBook: widget.onBook,
                      onOpenAppointments: widget.onOpenAppointments,
                      onOpenPrescriptions: widget.onOpenPrescriptions,
                      onOpenMarket: widget.onOpenMarket,
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(
                      title: 'Персонально для вас',
                      action: 'Обновить',
                      onAction: () => setState(() => _future = _load()),
                    ),
                    const SizedBox(height: 10),
                    _OfferCarousel(
                      prescription: latestPrescription,
                      nextSchedule: nextSchedule,
                      onOpenMarket: widget.onOpenMarket,
                      onOpenSchedule: widget.onOpenSchedule,
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle(
                      title: 'Ваше здоровье',
                      action: 'Все записи',
                      onAction: widget.onOpenAppointments,
                    ),
                    const SizedBox(height: 10),
                    if (nextAppointment == null)
                      _EmptyHealthCard(onBook: widget.onBook)
                    else
                      _AppointmentPreview(appointment: nextAppointment),
                    const SizedBox(height: 14),
                    if (latestPrescription != null)
                      _PrescriptionPreview(
                        prescription: latestPrescription,
                        apiService: widget.apiService,
                      )
                    else
                      _InfoBanner(
                        icon: Icons.auto_awesome_outlined,
                        title: 'AI объяснит назначение',
                        text:
                            'После визита врач отправит назначение, а AI покажет понятное резюме и лекарства в аптеке.',
                      ),
                    const SizedBox(height: 14),
                    _InfoBanner(
                      icon: Icons.shield_outlined,
                      title: 'Медицинская безопасность',
                      text:
                          'ИИ-агент не заменяет врача. Перед заменой препарата проконсультируйтесь с врачом или фармацевтом.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeSnapshot {
  const _HomeSnapshot({
    this.appointments = const [],
    this.prescriptions = const [],
    this.schedule = const [],
  });

  final List<Appointment> appointments;
  final List<Prescription> prescriptions;
  final List<MedicationScheduleItem> schedule;

  Appointment? get nextAppointment {
    final now = DateTime.now();
    final upcoming = appointments
        .where((item) =>
            item.appointmentDate.isAfter(now) &&
            item.status != 'CANCELLED' &&
            item.status != 'COMPLETED')
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Prescription? get latestPrescription =>
      prescriptions.isEmpty ? null : prescriptions.first;

  MedicationScheduleItem? get nextScheduleItem {
    final planned = schedule.where((item) => item.status == 'PLANNED').toList()
      ..sort((a, b) => a.takeTime.compareTo(b.takeTime));
    return planned.isEmpty ? null : planned.first;
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.user,
    required this.nextAppointment,
    required this.onBook,
  });

  final AppUser user;
  final Appointment? nextAppointment;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 14, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_halykDark, _halykGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'HH',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halyk Health',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Медицина внутри super app',
                      style: TextStyle(color: Color(0xD9FFFFFF)),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                ),
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Здравствуйте, ${user.fullName.split(' ').first}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nextAppointment == null
                ? 'Запишитесь к врачу, получите назначение и закажите лекарства в одном месте.'
                : 'Ближайший приём уже запланирован. Мы напомним о визите и графике лечения.',
            style: const TextStyle(
              color: Color(0xD9FFFFFF),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onBook,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Записаться к врачу'),
              style: FilledButton.styleFrom(
                backgroundColor: _halykGold,
                foregroundColor: _halykDark,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onBook,
    required this.onOpenAppointments,
    required this.onOpenPrescriptions,
    required this.onOpenMarket,
  });

  final VoidCallback onBook;
  final VoidCallback onOpenAppointments;
  final VoidCallback onOpenPrescriptions;
  final VoidCallback onOpenMarket;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _ActionTile(
          icon: Icons.add_circle_outline,
          title: 'Новая запись',
          text: 'Врач, дата и время',
          onTap: onBook,
        ),
        _ActionTile(
          icon: Icons.event_available_outlined,
          title: 'Мои записи',
          text: 'Статусы и перенос',
          onTap: onOpenAppointments,
        ),
        _ActionTile(
          icon: Icons.assignment_outlined,
          title: 'Назначения',
          text: 'Врач + AI объяснение',
          onTap: onOpenPrescriptions,
        ),
        _ActionTile(
          icon: Icons.local_pharmacy_outlined,
          title: 'Аптека',
          text: 'Лекарства и аналоги',
          onTap: onOpenMarket,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2EAEC)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _halykGreen),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
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

class _OfferCarousel extends StatelessWidget {
  const _OfferCarousel({
    required this.prescription,
    required this.nextSchedule,
    required this.onOpenMarket,
    required this.onOpenSchedule,
  });

  final Prescription? prescription;
  final MedicationScheduleItem? nextSchedule;
  final VoidCallback onOpenMarket;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final scheduleText = nextSchedule == null
        ? 'Появится после назначения врача и AI-анализа.'
        : '${nextSchedule!.prescriptionMedicine.medicineName} · ${DateFormat('HH:mm').format(nextSchedule!.takeTime)}';
    final cards = [
      _OfferCard(
        color: _halykGold,
        icon: Icons.local_pharmacy_outlined,
        title: prescription == null ? 'Аптечный маркет' : 'Лекарства по назначению',
        text: prescription == null
            ? 'Проверьте цены, наличие и аналоги препаратов.'
            : 'AI выделил препараты, можно открыть подходящие товары.',
        onTap: onOpenMarket,
      ),
      _OfferCard(
        color: _halykGreen,
        icon: Icons.alarm_outlined,
        title: nextSchedule == null ? 'График приёма' : 'Следующий приём лекарства',
        text: scheduleText,
        onTap: onOpenSchedule,
      ),
    ];

    return SizedBox(
      height: 142,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) => cards[index],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color == _halykGold ? _halykDark : Colors.white),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: color == _halykGold ? _halykDark : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color == _halykGold
                    ? _halykDark.withValues(alpha: 0.76)
                    : Colors.white.withValues(alpha: 0.82),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentPreview extends StatelessWidget {
  const _AppointmentPreview({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final date = appointment.appointmentDate.toLocal();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAEC)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _softGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                DateFormat('dd').format(date),
                style: const TextStyle(
                  color: _halykGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctor.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${appointment.clinic.name} · ${DateFormat('HH:mm').format(date)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _textMuted),
        ],
      ),
    );
  }
}

class _PrescriptionPreview extends StatelessWidget {
  const _PrescriptionPreview({
    required this.prescription,
    required this.apiService,
  });

  final Prescription prescription;
  final ApiService apiService;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrescriptionDetailScreen(
            apiService: apiService,
            prescription: prescription,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2EAEC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_outlined, color: _halykGreen),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Последнее назначение',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: _softGreen,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    prescription.status,
                    style: const TextStyle(
                      color: _halykGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              prescription.diagnosis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              prescription.aiSummary ?? prescription.rawText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _textMuted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHealthCard extends StatelessWidget {
  const _EmptyHealthCard({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return _InfoBanner(
      icon: Icons.calendar_month_outlined,
      title: 'Запланируйте визит',
      text:
          'Выберите прикреплённую поликлинику, лечащего врача и удобный слот.',
      action: 'Записаться',
      onAction: onBook,
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.text,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String text;
  final String? action;
  final VoidCallback? onAction;

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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _softGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _halykGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(color: _textMuted, height: 1.35),
                ),
                if (action != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(action!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
