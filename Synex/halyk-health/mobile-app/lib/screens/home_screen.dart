import 'dart:async';

import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';

const _halykGreen = Color(0xFF20A957);
const _halykDark = Color(0xFF111827);
const _surfaceBg = Color(0xFFF5F6F8);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.apiService,
    required this.user,
    this.enablePrescriptionPolling = true,
  });

  final ApiService apiService;
  final AppUser user;
  final bool enablePrescriptionPolling;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomePrescriptionState> _future;
  Timer? _pollTimer;
  Timer? _notificationTimer;
  String? _latestPrescriptionId;
  Prescription? _popupPrescription;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _future.then((state) => _latestPrescriptionId = state.prescription?.id);
    if (widget.enablePrescriptionPolling) {
      _pollTimer = Timer.periodic(
        const Duration(seconds: 4),
        (_) => _pollForNewPrescription(),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<_HomePrescriptionState> _load() async {
    final prescriptions = await widget.apiService.getMyPrescriptions();
    final selected = prescriptions.isEmpty
        ? null
        : prescriptions.firstWhere(
            (item) => item.medicines.isNotEmpty || item.aiSummary != null,
            orElse: () => prescriptions.first,
          );

    return _HomePrescriptionState(prescription: selected);
  }

  Future<void> _pollForNewPrescription() async {
    if (!mounted) return;

    try {
      final state = await _load();
      final prescription = state.prescription;
      final previousId = _latestPrescriptionId;

      if (prescription == null) {
        return;
      }

      if (previousId == null) {
        _latestPrescriptionId = prescription.id;
        return;
      }

      if (prescription.id != previousId) {
        _latestPrescriptionId = prescription.id;
        setState(() {
          _future = Future.value(state);
          _popupPrescription = prescription;
        });
        _showPrescriptionBanner(prescription);
        _schedulePopupDismiss(prescription);
      }
    } catch (_) {
      // Polling should never interrupt the patient app if backend is offline.
    }
  }

  Future<void> _openPrescription(Prescription prescription) async {
    _notificationTimer?.cancel();
    if (_popupPrescription != null) {
      setState(() => _popupPrescription = null);
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrescriptionJourneyScreen(
          apiService: widget.apiService,
          initialPrescription: prescription,
        ),
      ),
    );

    if (mounted) {
      setState(() => _future = _load());
    }
  }

  void _schedulePopupDismiss(Prescription prescription) {
    _notificationTimer?.cancel();
    _notificationTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && _popupPrescription?.id == prescription.id) {
        setState(() => _popupPrescription = null);
      }
    });
  }

  void _showPrescriptionBanner(Prescription prescription) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        elevation: 6,
        backgroundColor: Colors.white,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7EF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            color: _halykGreen,
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Вам выписали назначение',
              style: TextStyle(
                color: _halykDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              prescription.diagnosis,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              messenger.clearMaterialBanners();
              _openPrescription(prescription);
            },
            child: const Text('Открыть'),
          ),
        ],
      ),
    );

    Timer(const Duration(seconds: 7), messenger.clearMaterialBanners);
  }

  void _showStub(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('$title: раздел не входит в текущий MVP-сценарий')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final popup = _popupPrescription;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _surfaceBg,
          body: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth =
                    constraints.maxWidth > 430 ? 430.0 : constraints.maxWidth;

                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    height: constraints.maxHeight,
                    child: FutureBuilder<_HomePrescriptionState>(
                      future: _future,
                      builder: (context, snapshot) {
                        final prescription = snapshot.data?.prescription;

                        return RefreshIndicator(
                          color: _halykGreen,
                          onRefresh: () async {
                            setState(() => _future = _load());
                            await _future;
                          },
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                            children: [
                              if (popup != null) ...[
                                _HomePrescriptionToast(
                                  prescription: popup,
                                  onTap: () => _openPrescription(popup),
                                ),
                                const SizedBox(height: 12),
                              ],
                              _HalykTopBar(user: widget.user),
                              const SizedBox(height: 16),
                              _PromoStrip(onTap: () => _showStub('Маркет')),
                              const SizedBox(height: 14),
                              _CoreServicesGrid(onService: _showStub),
                              const SizedBox(height: 16),
                              _PrescriptionNotificationCard(
                                loading: !snapshot.hasData,
                                prescription: prescription,
                                onOpen: prescription == null
                                    ? null
                                    : () => _openPrescription(prescription),
                              ),
                              const SizedBox(height: 16),
                              _AllServicesRow(onService: _showStub),
                              const SizedBox(height: 16),
                              _MarketSwitch(onService: _showStub),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          bottomNavigationBar: SizedBox(
            height: 92,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: _HalykBottomBar(onTap: _showStub),
              ),
            ),
          ),
        ),
        if (popup != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            right: 16,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: _HomePrescriptionToast(
                  prescription: popup,
                  onTap: () => _openPrescription(popup),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomePrescriptionState {
  const _HomePrescriptionState({required this.prescription});

  final Prescription? prescription;
}

class _HomePrescriptionToast extends StatelessWidget {
  const _HomePrescriptionToast({
    required this.prescription,
    required this.onTap,
  });

  final Prescription prescription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFCDEFD9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: _halykGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Halyk Health',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Вам выписали назначение',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _halykDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      prescription.diagnosis,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _halykGreen),
            ],
          ),
        ),
      ),
    );
  }
}

class _HalykTopBar extends StatelessWidget {
  const _HalykTopBar({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(label: 'AШ', onTap: () {}),
        const SizedBox(width: 12),
        const Expanded(
          child: _SearchPill(),
        ),
        const SizedBox(width: 12),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              Icon(Icons.eco, color: _halykGreen),
              SizedBox(width: 8),
              Text(
                '26.51',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline, color: _halykGreen),
            ),
            Positioned(
              right: 0,
              top: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Color(0xFF98A2B3)),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Поиск',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF98A2B3),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFFEDEFF4),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: _halykDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoStrip extends StatelessWidget {
  const _PromoStrip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _PromoCard(
            width: 330,
            color: const Color(0xFF233B35),
            title: 'Halyk Health',
            subtitle: 'Назначение врача, AI-выжимка и Appteka в одном сценарии',
            icon: Icons.local_hospital,
            onTap: onTap,
          ),
          const SizedBox(width: 12),
          _PromoCard(
            width: 190,
            color: const Color(0xFF7C5CFF),
            title: '+10%',
            subtitle: 'Бонусы на аптечный заказ',
            icon: Icons.shopping_cart_outlined,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.width,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final double width;
  final Color color;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -14,
              bottom: -20,
              child: Icon(
                icon,
                size: 118,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CoreServicesGrid extends StatelessWidget {
  const _CoreServicesGrid({required this.onService});

  final ValueChanged<String> onService;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.credit_card, 'Карты'),
      (Icons.savings_outlined, 'Депозиты'),
      (Icons.payments_outlined, 'Кредиты'),
      (Icons.shopping_bag_outlined, 'Рассрочка'),
      (Icons.storefront_outlined, 'Маркет'),
      (Icons.flight_takeoff, 'Travel'),
      (Icons.shield_outlined, 'Страховка'),
      (Icons.grid_view_rounded, 'QR'),
      (Icons.eco_outlined, 'Halyk+'),
      (Icons.account_balance_outlined, 'Госуслуги'),
      (Icons.show_chart, 'Invest'),
      (Icons.local_pharmacy_outlined, 'Appteka'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        runSpacing: 10,
        children: items.map((item) {
          return SizedBox(
            width: (MediaQuery.sizeOf(context).width.clamp(0, 430) - 56) / 4,
            child: _ServiceIcon(
              icon: item.$1,
              label: item.$2,
              onTap: () => onService(item.$2),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ServiceIcon extends StatelessWidget {
  const _ServiceIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _halykGreen, size: 34),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _halykDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionNotificationCard extends StatelessWidget {
  const _PrescriptionNotificationCard({
    required this.loading,
    required this.prescription,
    required this.onOpen,
  });

  final bool loading;
  final Prescription? prescription;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final hasPrescription = prescription != null;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: hasPrescription ? const Color(0xFF102B23) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: hasPrescription ? Colors.transparent : _border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: hasPrescription
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFE8F7EF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                color: hasPrescription ? Colors.white : _halykGreen,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loading
                        ? 'Проверяем назначения'
                        : hasPrescription
                            ? 'Вам выписали назначение'
                            : 'Новых назначений нет',
                    style: TextStyle(
                      color: hasPrescription ? Colors.white : _halykDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasPrescription
                        ? '${prescription!.diagnosis}. Откройте назначение врача, AI-выжимку и готовую корзину Appteka.'
                        : 'Когда поликлиника отправит назначение, оно появится здесь как банковское уведомление.',
                    style: TextStyle(
                      color: hasPrescription
                          ? Colors.white.withValues(alpha: 0.78)
                          : _muted,
                      height: 1.35,
                    ),
                  ),
                  if (hasPrescription) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      runSpacing: 8,
                      spacing: 8,
                      children: [
                        const _LightBadge(text: 'Поликлиника'),
                        _LightBadge(
                            text:
                                '${prescription!.medicines.length} препарата'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: hasPrescription ? Colors.white : _muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _LightBadge extends StatelessWidget {
  const _LightBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AllServicesRow extends StatelessWidget {
  const _AllServicesRow({required this.onService});

  final ValueChanged<String> onService;

  @override
  Widget build(BuildContext context) {
    final services = [
      (const Color(0xFF62BD3D), 'Airba fresh', 'fresh'),
      (const Color(0xFFB9FF00), 'inDrive', 'iD'),
      (_halykGreen, 'Appteka', '+'),
      (const Color(0xFFE7F4EA), 'Рестораны', 'NEW'),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Все сервисы',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _halykDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onService('Все сервисы'),
                icon: const Icon(Icons.chevron_right, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: services.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final service = services[index];
                return _MiniService(
                  color: service.$1,
                  title: service.$2,
                  mark: service.$3,
                  onTap: () => onService(service.$2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniService extends StatelessWidget {
  const _MiniService({
    required this.color,
    required this.title,
    required this.mark,
    required this.onTap,
  });

  final Color color;
  final String title;
  final String mark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 92,
        child: Column(
          children: [
            Container(
              width: 82,
              height: 58,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  mark,
                  style: TextStyle(
                    color: color.computeLuminance() > 0.5
                        ? _halykDark
                        : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _halykDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketSwitch extends StatelessWidget {
  const _MarketSwitch({required this.onService});

  final ValueChanged<String> onService;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAEE),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => onService('Market'),
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Market'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _halykDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextButton.icon(
              onPressed: () => onService('Kino.kz'),
              icon: const Icon(Icons.movie_outlined, color: _halykDark),
              label: const Text('Kino.kz'),
              style: TextButton.styleFrom(foregroundColor: _halykDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _HalykBottomBar extends StatelessWidget {
  const _HalykBottomBar({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          _NavItem(
              icon: Icons.home, label: 'Главная', active: true, onTap: () {}),
          _NavItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Мой банк',
              onTap: () => onTap('Мой банк')),
          Expanded(
            child: Center(
              child: InkWell(
                onTap: () => onTap('QR'),
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: _halykGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner,
                      color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
          _NavItem(
              icon: Icons.swap_horiz,
              label: 'Переводы',
              onTap: () => onTap('Переводы')),
          _NavItem(
              icon: Icons.receipt_long_outlined,
              label: 'Платежи',
              onTap: () => onTap('Платежи')),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? _halykGreen : const Color(0xFF5B6068)),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? _halykGreen : _halykDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrescriptionJourneyScreen extends StatefulWidget {
  const PrescriptionJourneyScreen({
    super.key,
    required this.apiService,
    required this.initialPrescription,
  });

  final ApiService apiService;
  final Prescription initialPrescription;

  @override
  State<PrescriptionJourneyScreen> createState() =>
      _PrescriptionJourneyScreenState();
}

class _PrescriptionJourneyScreenState extends State<PrescriptionJourneyScreen> {
  late Future<_PrescriptionJourneyData> _future;
  bool _buying = false;
  bool _remindersEnabled = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PrescriptionJourneyData> _load() async {
    var prescription = widget.initialPrescription;

    if (prescription.medicines.isEmpty) {
      prescription =
          await widget.apiService.analyzePrescription(prescription.id);
    }

    final groups =
        await widget.apiService.getPrescriptionMarketProducts(prescription.id);
    final allProducts = await widget.apiService
        .getMarketProducts()
        .catchError((_) => <MarketProduct>[]);
    final schedule = await widget.apiService
        .getPrescriptionSchedule(prescription.id)
        .catchError((_) => <MedicationScheduleItem>[]);

    final cartLines = <ApptekaDraftLine>[];
    final missing = <MissingMedicineSuggestion>[];
    for (final medicine in prescription.medicines) {
      final matchingGroup = groups.where(
        (group) => group.prescriptionMedicine.id == medicine.id,
      );
      final products = matchingGroup.isEmpty
          ? <MarketProduct>[]
          : matchingGroup.first.products;

      final exactProducts = products
          .where((product) => _isExactMatch(product, medicine))
          .toList()
        ..sort(_productSort);
      final sameActiveProducts = products
          .where((product) => _sameActiveSubstance(product, medicine))
          .toList()
        ..sort(_productSort);

      if (exactProducts.isNotEmpty) {
        cartLines.add(
          ApptekaDraftLine(
            medicine: medicine,
            product: exactProducts.first,
            quantity: medicine.quantityNeeded < 1 ? 1 : medicine.quantityNeeded,
            matchLabel: 'Точное совпадение',
            reason: 'Товар найден по названию и назначению врача.',
          ),
        );
        continue;
      }

      if (sameActiveProducts.isNotEmpty) {
        cartLines.add(
          ApptekaDraftLine(
            medicine: medicine,
            product: sameActiveProducts.first,
            quantity: medicine.quantityNeeded < 1 ? 1 : medicine.quantityNeeded,
            selected: false,
            isAlternative: true,
            matchLabel: 'Аналог',
            reason:
                'Назначенный товар не найден в наличии. Предложен препарат с тем же действующим веществом.',
          ),
        );
        continue;
      }

      final fallbackProducts = _samePurposeProducts(medicine, allProducts);
      if (fallbackProducts.isNotEmpty) {
        cartLines.add(
          ApptekaDraftLine(
            medicine: medicine,
            product: fallbackProducts.first,
            quantity: medicine.quantityNeeded < 1 ? 1 : medicine.quantityNeeded,
            selected: false,
            isAlternative: true,
            matchLabel: 'Замена по категории',
            reason:
                'В маркетплейсе нет назначенного препарата. Показан товар с похожим назначением: ${_purposeForMedicine(medicine)}.',
          ),
        );
      } else {
        missing.add(
          MissingMedicineSuggestion(
            medicine: medicine,
            purpose: _purposeForMedicine(medicine),
          ),
        );
      }
    }

    return _PrescriptionJourneyData(
      prescription: prescription,
      groups: groups,
      schedule: schedule,
      cartLines: cartLines,
      missingSuggestions: missing,
    );
  }

  bool _isExactMatch(MarketProduct product, PrescriptionMedicine medicine) {
    return product.title
        .toLowerCase()
        .contains(medicine.medicineName.toLowerCase());
  }

  bool _sameActiveSubstance(
    MarketProduct product,
    PrescriptionMedicine medicine,
  ) {
    return product.activeSubstance.toLowerCase() ==
        medicine.activeSubstance.toLowerCase();
  }

  int _productSort(MarketProduct a, MarketProduct b) {
    final stockCompare = b.stock.compareTo(a.stock);
    if (stockCompare != 0) return stockCompare;
    return a.price.compareTo(b.price);
  }

  List<MarketProduct> _samePurposeProducts(
    PrescriptionMedicine medicine,
    List<MarketProduct> products,
  ) {
    final purpose = _purposeForMedicine(medicine);
    if (purpose == 'Другое') return [];

    return products
        .where((product) => product.category == purpose && product.stock > 0)
        .toList()
      ..sort(_productSort);
  }

  Future<void> _buy(_PrescriptionJourneyData data) async {
    final selected = data.cartLines.where((line) => line.selected).toList();
    if (selected.isEmpty || _buying) return;

    setState(() => _buying = true);
    try {
      for (final line in selected) {
        await widget.apiService.addToCart(
          line.product.id,
          patientProfileId: data.prescription.patientProfile?.id,
          quantity: line.quantity,
        );
      }
      if (!mounted) return;
      final remindersEnabled = await _showReminderDialog(data);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ApptekaSelectionScreen(
            prescription: data.prescription,
            lines: data.cartLines,
            missingSuggestions: data.missingSuggestions,
            remindersEnabled: remindersEnabled,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _buying = false);
      }
    }
  }

  Future<bool> _showReminderDialog(_PrescriptionJourneyData data) async {
    final enabled = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Напоминания о приеме'),
        content: Text(
          'Хотели бы вы получать уведомления о приеме лекарств по времени на основе назначения? '
          'Мы подготовили ${data.schedule.length} напоминаний.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Не сейчас'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Включить'),
          ),
        ],
      ),
    );

    if (!mounted) return false;
    setState(() => _remindersEnabled = enabled == true);
    return enabled == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceBg,
      appBar: AppBar(
        title: const Text('Назначение врача'),
        backgroundColor: _surfaceBg,
        foregroundColor: _halykDark,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth =
              constraints.maxWidth > 430 ? 430.0 : constraints.maxWidth;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: contentWidth,
              height: constraints.maxHeight,
              child: FutureBuilder<_PrescriptionJourneyData>(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(color: _halykGreen));
                  }

                  final data = snapshot.data!;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    children: [
                      _PrescriptionJourneyHeader(data: data),
                      const SizedBox(height: 12),
                      _MedicalDocumentCard(prescription: data.prescription),
                      const SizedBox(height: 12),
                      _DoctorRecommendationCard(
                          prescription: data.prescription),
                      const SizedBox(height: 12),
                      _AiSummaryCard(prescription: data.prescription),
                      const SizedBox(height: 12),
                      _MedicineScheduleCard(
                        prescription: data.prescription,
                        schedule: data.schedule,
                      ),
                      const SizedBox(height: 12),
                      _ApptekaDraftCart(
                        lines: data.cartLines,
                        missingSuggestions: data.missingSuggestions,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      if (_remindersEnabled) const _ReminderEnabledCard(),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SizedBox(
        height: 86,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: FutureBuilder<_PrescriptionJourneyData>(
              future: _future,
              builder: (context, snapshot) {
                final data = snapshot.data;
                final total = data?.selectedTotal ?? 0;
                final count =
                    data?.cartLines.where((line) => line.selected).length ?? 0;

                return SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: data == null || count == 0 || _buying
                          ? null
                          : () => _buy(data),
                      style: FilledButton.styleFrom(
                        backgroundColor: _halykGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _buying
                            ? 'Оформляем...'
                            : 'Купить лекарства · ${total.toStringAsFixed(0)} ₸',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PrescriptionJourneyHeader extends StatelessWidget {
  const _PrescriptionJourneyHeader({required this.data});

  final _PrescriptionJourneyData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF102B23),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.local_hospital_outlined,
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Назначение получено',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      data.prescription.diagnosis,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  value: '${data.prescription.medicines.length}',
                  label: 'препарата',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeaderMetric(
                  value: '${data.selectedCount}',
                  label: 'в корзине',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeaderMetric(
                  value: '${data.schedule.length}',
                  label: 'напоминаний',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ApptekaSelectionScreen extends StatelessWidget {
  const ApptekaSelectionScreen({
    super.key,
    required this.prescription,
    required this.lines,
    required this.missingSuggestions,
    required this.remindersEnabled,
  });

  final Prescription prescription;
  final List<ApptekaDraftLine> lines;
  final List<MissingMedicineSuggestion> missingSuggestions;
  final bool remindersEnabled;

  @override
  Widget build(BuildContext context) {
    final selectedLines = lines.where((line) => line.selected).toList();
    final alternativeLines =
        lines.where((line) => !line.selected && line.isAlternative).toList();
    final total = selectedLines.fold<num>(
      0,
      (sum, line) => sum + line.product.price * line.quantity,
    );

    return Scaffold(
      backgroundColor: _surfaceBg,
      appBar: AppBar(
        title: const Text('Appteka'),
        backgroundColor: _surfaceBg,
        foregroundColor: _halykDark,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth =
              constraints.maxWidth > 430 ? 430.0 : constraints.maxWidth;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: contentWidth,
              height: constraints.maxHeight,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _halykGreen,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Подборка готова',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Товары из назначения добавлены в корзину Appteka. Можно убрать лишнее уже в Appteka перед оплатой.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.84),
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _WhitePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _BlockTitle(
                            icon: Icons.shopping_bag_outlined,
                            title: 'В корзине'),
                        const SizedBox(height: 12),
                        if (selectedLines.isEmpty)
                          const Text(
                            'Вы не выбрали товары из назначения.',
                            style: TextStyle(color: _muted),
                          )
                        else
                          ...selectedLines.map(
                            (line) => _ApptekaSummaryLine(line: line),
                          ),
                        const Divider(height: 26),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Итого',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              '${total.toStringAsFixed(0)} ₸',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (alternativeLines.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _WhitePanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _BlockTitle(
                              icon: Icons.compare_arrows,
                              title: 'Аналоги и замены'),
                          const SizedBox(height: 10),
                          const Text(
                            'Эти товары не добавлены автоматически. Их можно рассмотреть только после консультации.',
                            style: TextStyle(color: _muted, height: 1.35),
                          ),
                          const SizedBox(height: 12),
                          ...alternativeLines.map(
                            (line) => _ApptekaSummaryLine(line: line),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (missingSuggestions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _WhitePanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _BlockTitle(
                              icon: Icons.warning_amber_outlined,
                              title: 'Не найдено'),
                          const SizedBox(height: 12),
                          ...missingSuggestions.map(
                            (item) => _MissingMedicineTile(suggestion: item),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _WhitePanel(
                    child: Row(
                      children: [
                        Icon(
                          remindersEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off_outlined,
                          color: _halykGreen,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            remindersEnabled
                                ? 'Напоминания о приеме включены по графику назначения.'
                                : 'Напоминания не включены. Их можно включить позже в разделе здоровья.',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SizedBox(
        height: 88,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Заказ оформлен в mock-режиме. Реальная оплата не подключена.',
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _halykGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Оформить заказ',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ApptekaSummaryLine extends StatelessWidget {
  const _ApptekaSummaryLine({required this.line});

  final ApptekaDraftLine line;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: line.isAlternative
                  ? const Color(0xFFFFF7E6)
                  : const Color(0xFFE8F7EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              line.isAlternative ? Icons.compare_arrows : Icons.check,
              color: line.isAlternative ? const Color(0xFFB45309) : _halykGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${line.quantity} шт · ${line.product.pharmacyName}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${(line.product.price * line.quantity).toStringAsFixed(0)} ₸',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionJourneyData {
  const _PrescriptionJourneyData({
    required this.prescription,
    required this.groups,
    required this.schedule,
    required this.cartLines,
    required this.missingSuggestions,
  });

  final Prescription prescription;
  final List<MedicineProductGroup> groups;
  final List<MedicationScheduleItem> schedule;
  final List<ApptekaDraftLine> cartLines;
  final List<MissingMedicineSuggestion> missingSuggestions;

  num get selectedTotal => cartLines.fold<num>(
        0,
        (sum, line) =>
            line.selected ? sum + line.product.price * line.quantity : sum,
      );

  int get selectedCount => cartLines.where((line) => line.selected).length;
}

class ApptekaDraftLine {
  ApptekaDraftLine({
    required this.medicine,
    required this.product,
    required this.quantity,
    required this.matchLabel,
    required this.reason,
    this.selected = true,
    this.isAlternative = false,
  });

  final PrescriptionMedicine medicine;
  final MarketProduct product;
  final String matchLabel;
  final String reason;
  final bool isAlternative;
  int quantity;
  bool selected;
}

class MissingMedicineSuggestion {
  const MissingMedicineSuggestion({
    required this.medicine,
    required this.purpose,
  });

  final PrescriptionMedicine medicine;
  final String purpose;
}

String _purposeForMedicine(PrescriptionMedicine medicine) {
  final normalized =
      '${medicine.medicineName} ${medicine.activeSubstance}'.toLowerCase();

  if (normalized.contains('amoxicillin') ||
      normalized.contains('azithromycin') ||
      normalized.contains('амоксициллин') ||
      normalized.contains('азитромицин')) {
    return 'Антибиотики';
  }

  if (normalized.contains('ibuprofen') ||
      normalized.contains('paracetamol') ||
      normalized.contains('ибупрофен') ||
      normalized.contains('парацетамол')) {
    return 'Температура и боль';
  }

  if (normalized.contains('loratadine') ||
      normalized.contains('cetirizine') ||
      normalized.contains('лоратадин') ||
      normalized.contains('цетиризин')) {
    return 'Аллергия';
  }

  if (normalized.contains('спрей') ||
      normalized.contains('горла') ||
      normalized.contains('throat')) {
    return 'Горло';
  }

  if (normalized.contains('vitamin') || normalized.contains('витамин')) {
    return 'Витамины';
  }

  return 'Другое';
}

class _MedicalDocumentCard extends StatelessWidget {
  const _MedicalDocumentCard({required this.prescription});

  final Prescription prescription;

  @override
  Widget build(BuildContext context) {
    return _WhitePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    const Icon(Icons.description_outlined, color: _halykGreen),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Электронное назначение',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 2),
                    Text('Форма назначения РК',
                        style: TextStyle(color: _muted)),
                  ],
                ),
              ),
              const _StatusChip(text: 'Получено'),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Диагноз', value: prescription.diagnosis),
          _InfoRow(
              label: 'Пациент',
              value: prescription.patientProfile?.fullName ??
                  'Пациент Halyk Health'),
          const _InfoRow(label: 'Источник', value: 'Городская поликлиника №5'),
          const Divider(height: 28),
          const Text(
            'Назначение врача',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            prescription.rawText,
            style: const TextStyle(height: 1.45, color: _halykDark),
          ),
        ],
      ),
    );
  }
}

class _DoctorRecommendationCard extends StatelessWidget {
  const _DoctorRecommendationCard({required this.prescription});

  final Prescription prescription;

  @override
  Widget build(BuildContext context) {
    return _WhitePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BlockTitle(
              icon: Icons.medical_information_outlined,
              title: 'Рекомендации врача'),
          const SizedBox(height: 10),
          Text(
            prescription.doctorComment?.isNotEmpty == true
                ? prescription.doctorComment!
                : 'Следуйте назначению врача. При ухудшении состояния обратитесь в поликлинику повторно.',
            style: const TextStyle(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _AiSummaryCard extends StatelessWidget {
  const _AiSummaryCard({required this.prescription});

  final Prescription prescription;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCDEFD9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BlockTitle(icon: Icons.auto_awesome, title: 'Кратко от AI'),
          const SizedBox(height: 10),
          Text(
            prescription.aiSummary ??
                'AI объяснит назначение простым языком после обработки текста врача.',
            style: const TextStyle(height: 1.45, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            prescription.aiDisclaimer ??
                'ИИ-агент не заменяет врача. Он объясняет назначение, созданное врачом.',
            style: const TextStyle(color: _muted, height: 1.35, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MedicineScheduleCard extends StatelessWidget {
  const _MedicineScheduleCard({
    required this.prescription,
    required this.schedule,
  });

  final Prescription prescription;
  final List<MedicationScheduleItem> schedule;

  @override
  Widget build(BuildContext context) {
    return _WhitePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BlockTitle(
              icon: Icons.alarm_outlined, title: 'Прием препаратов'),
          const SizedBox(height: 10),
          ...prescription.medicines.map(
            (medicine) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: _halykGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${medicine.medicineName} ${medicine.dosage}: ${medicine.frequency}, ${medicine.duration}. ${medicine.instruction}.',
                      style: const TextStyle(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (schedule.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              'График готов: ${schedule.length} напоминаний по времени назначения.',
              style:
                  const TextStyle(color: _muted, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

class _ApptekaDraftCart extends StatelessWidget {
  const _ApptekaDraftCart({
    required this.lines,
    required this.missingSuggestions,
    required this.onChanged,
  });

  final List<ApptekaDraftLine> lines;
  final List<MissingMedicineSuggestion> missingSuggestions;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty && missingSuggestions.isEmpty) {
      return const _WhitePanel(
        child: Text('Appteka не нашла товары по назначению.'),
      );
    }

    return _WhitePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _halykGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Корзина Appteka',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Товары подобраны по назначению',
                      style: TextStyle(color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...lines.map(
            (line) => _DraftCartLine(
              line: line,
              onChanged: onChanged,
            ),
          ),
          if (missingSuggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...missingSuggestions.map(
              (item) => _MissingMedicineTile(suggestion: item),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Аналог не означает автоматическую замену. Перед заменой препарата проконсультируйтесь с врачом или фармацевтом.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _DraftCartLine extends StatelessWidget {
  const _DraftCartLine({
    required this.line,
    required this.onChanged,
  });

  final ApptekaDraftLine line;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            line.selected ? const Color(0xFFF8FAFC) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: line.selected,
            activeColor: _halykGreen,
            onChanged: (value) {
              line.selected = value == true;
              onChanged();
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TinyBadge(
                      text: line.matchLabel,
                      color: line.isAlternative
                          ? const Color(0xFFFFF7E6)
                          : const Color(0xFFE8F7EF),
                      textColor: line.isAlternative
                          ? const Color(0xFFB45309)
                          : _halykGreen,
                    ),
                    _TinyBadge(
                      text: line.product.stock > 0
                          ? 'В наличии: ${line.product.stock}'
                          : 'Нет в наличии',
                      color: line.product.stock > 0
                          ? const Color(0xFFE8F7EF)
                          : const Color(0xFFFEE2E2),
                      textColor: line.product.stock > 0
                          ? _halykGreen
                          : const Color(0xFFB91C1C),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${line.product.form} · ${line.product.dosage} · ${line.product.pharmacyName}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                if (line.isAlternative) ...[
                  const SizedBox(height: 6),
                  Text(
                    line.reason,
                    style: const TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${line.product.price.toStringAsFixed(0)} ₸',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'нужно ${line.medicine.quantityNeeded}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              _QuantityButton(
                icon: Icons.remove,
                onTap: () {
                  if (line.quantity > 1) {
                    line.quantity--;
                    onChanged();
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '${line.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              _QuantityButton(
                icon: Icons.add,
                onTap: () {
                  line.quantity++;
                  onChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissingMedicineTile extends StatelessWidget {
  const _MissingMedicineTile({required this.suggestion});

  final MissingMedicineSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${suggestion.medicine.medicineName} не найден в Appteka. Категория: ${suggestion.purpose}. Добавьте вручную или уточните замену у врача/фармацевта.',
              style: const TextStyle(
                color: Color(0xFF78350F),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({
    required this.text,
    required this.color,
    required this.textColor,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _ReminderEnabledCard extends StatelessWidget {
  const _ReminderEnabledCard();

  @override
  Widget build(BuildContext context) {
    return const _WhitePanel(
      child: Row(
        children: [
          Icon(Icons.notifications_active, color: _halykGreen),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Напоминания о приеме лекарств включены.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhitePanel extends StatelessWidget {
  const _WhitePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }
}

class _BlockTitle extends StatelessWidget {
  const _BlockTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _halykGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: const TextStyle(color: _muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _halykGreen,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
