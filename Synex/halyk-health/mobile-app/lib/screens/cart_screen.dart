import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<CartItem>> _future;
  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.apiService.getCart();
  }

  Future<void> _changeQuantity(CartItem item, int quantity) async {
    await widget.apiService.updateCartItemQuantity(item.id, quantity);
    setState(_reload);
  }

  Future<void> _checkout(List<CartItem> items) async {
    if (items.isEmpty) return;

    setState(() => _checkingOut = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _checkingOut = false);

    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Заказ оформлен'),
            content: const Text(
              'Mock-заказ создан. Оплата и доставка не подключены в MVP.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Готово'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Корзина')),
      body: FutureBuilder<List<CartItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          final total = items.fold<num>(0, (sum, item) => sum + item.lineTotal);

          if (items.isEmpty) {
            return const _EmptyCart();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _CartItemCard(
                      item: item,
                      onMinus: () => _changeQuantity(item, item.quantity - 1),
                      onPlus: () => _changeQuantity(item, item.quantity + 1),
                    );
                  },
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Итого',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Text(
                            '${total.toStringAsFixed(0)} ₸',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              _checkingOut ? null : () => _checkout(items),
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(
                            _checkingOut ? 'Оформляем...' : 'Оформить заказ',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onMinus,
    required this.onPlus,
  });

  final CartItem item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFE9F8F4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_pharmacy_outlined,
                color: Color(0xFF007F6D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.product.form} · ${item.product.pharmacyName}',
                    style: const TextStyle(color: Color(0xFF60727F)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.lineTotal.toStringAsFixed(0)} ₸',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                IconButton.outlined(
                  tooltip: 'Уменьшить',
                  onPressed: onMinus,
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                IconButton.outlined(
                  tooltip: 'Увеличить',
                  onPressed: onPlus,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 54,
              color: Color(0xFF60727F),
            ),
            const SizedBox(height: 12),
            const Text(
              'Корзина пуста',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Добавьте препараты из каталога или из назначенных лекарств.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF60727F)),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Вернуться в аптеку'),
            ),
          ],
        ),
      ),
    );
  }
}
