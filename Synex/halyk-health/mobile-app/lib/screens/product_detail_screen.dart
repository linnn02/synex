import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.apiService,
    required this.product,
  });

  final ApiService apiService;
  final MarketProduct product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _adding = false;

  Future<void> _addToCart(MarketProduct product) async {
    setState(() => _adding = true);
    try {
      await widget.apiService.addToCart(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.title} добавлен в корзину')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _adding = false);
      }
    }
  }

  Future<void> _showAlternatives() async {
    final alternatives = await widget.apiService.getAlternatives(
      widget.product.activeSubstance,
    );
    if (!mounted) return;

    final items =
        alternatives.where((item) => item.id != widget.product.id).toList();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Аналоги',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Аналог не означает автоматическую замену. Перед заменой препарата проконсультируйтесь с врачом или фармацевтом.',
                    style: TextStyle(color: Color(0xFF60727F), height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  if (items.isEmpty)
                    const _InfoPanel(
                      text:
                          'Других товаров с этим действующим веществом пока нет.',
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _AlternativeTile(
                            product: item,
                            onAdd: () => _addToCart(item),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(title: const Text('Товар')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed:
              product.isInStock && !_adding ? () => _addToCart(product) : null,
          icon: const Icon(Icons.shopping_cart_outlined),
          label: Text(_adding ? 'Добавляем...' : 'Добавить в корзину'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F8F4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.medication_outlined,
                        color: Color(0xFF007F6D),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            product.category,
                            style: const TextStyle(color: Color(0xFF60727F)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.priceText,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StockBadge(stock: product.stock),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  product.pharmacyName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Самовывоз или доставка в mock-сценарии MVP',
                  style: TextStyle(color: Color(0xFF60727F)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Информация',
            rows: [
              _DetailRow('Дозировка', product.dosage),
              _DetailRow('Форма выпуска', product.form),
              _DetailRow('Действующее вещество', product.activeSubstance),
              _DetailRow('Производитель', product.manufacturer),
              _DetailRow('Аптека', product.pharmacyName),
              _DetailRow('Наличие', '${product.stock} шт.'),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _showAlternatives,
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Показать аналоги'),
          ),
          const SizedBox(height: 14),
          const _InfoPanel(
            text:
                'Перед заменой препарата проконсультируйтесь с врачом или фармацевтом.',
            highlighted: true,
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.rows});

  final String title;
  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: const TextStyle(color: Color(0xFF60727F)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
}

class _AlternativeTile extends StatelessWidget {
  const _AlternativeTile({required this.product, required this.onAdd});

  final MarketProduct product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.form} · ${product.pharmacyName}',
                  style: const TextStyle(color: Color(0xFF60727F)),
                ),
                const SizedBox(height: 4),
                Text(
                  product.priceText,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: 'В корзину',
            onPressed: product.isInStock ? onAdd : null,
            icon: const Icon(Icons.add_shopping_cart),
          ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final inStock = stock > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: inStock ? const Color(0xFFE9F8F4) : const Color(0xFFFFF0ED),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        inStock ? 'В наличии' : 'Нет в наличии',
        style: TextStyle(
          color: inStock ? const Color(0xFF007F6D) : const Color(0xFF9E2A1B),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.text, this.highlighted = false});

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFE9F8F4) : const Color(0xFFF4F7F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF425766), height: 1.4),
      ),
    );
  }
}
