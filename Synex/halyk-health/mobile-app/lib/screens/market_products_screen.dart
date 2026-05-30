import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';

class MarketProductsScreen extends StatefulWidget {
  const MarketProductsScreen({
    super.key,
    required this.apiService,
    this.prescriptionId,
  });

  final ApiService apiService;
  final String? prescriptionId;

  @override
  State<MarketProductsScreen> createState() => _MarketProductsScreenState();
}

class _MarketProductsScreenState extends State<MarketProductsScreen> {
  late Future<Object> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.prescriptionId == null
        ? widget.apiService.getMarketProducts()
        : widget.apiService.getPrescriptionMarketProducts(widget.prescriptionId!);
  }

  Future<void> _addToCart(MarketProduct product) async {
    try {
      await widget.apiService.addToCart(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.title} добавлен в корзину')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _showAlternatives(String activeSubstance) async {
    final alternatives = await widget.apiService.getAlternatives(activeSubstance);
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Аналоги', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...alternatives.map((product) => _ProductCard(product: product, onAdd: _addToCart, onAlternatives: null)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Аптека')),
      body: FutureBuilder<Object>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          if (data is List<MedicineProductGroup>) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final group in data) ...[
                  Text(
                    group.prescriptionMedicine.medicineName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...group.products.map(
                    (product) => _ProductCard(
                      product: product,
                      onAdd: _addToCart,
                      onAlternatives: () => _showAlternatives(product.activeSubstance),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ],
            );
          }

          final products = data as List<MarketProduct>;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _ProductCard(
              product: products[index],
              onAdd: _addToCart,
              onAlternatives: () => _showAlternatives(products[index].activeSubstance),
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onAdd,
    required this.onAlternatives,
  });

  final MarketProduct product;
  final ValueChanged<MarketProduct> onAdd;
  final VoidCallback? onAlternatives;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('${product.form} · ${product.manufacturer} · ${product.pharmacyName}'),
            const SizedBox(height: 6),
            Text('${product.price.toStringAsFixed(0)} ₸ · в наличии ${product.stock}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => onAdd(product),
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('В корзину'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Аналоги',
                  onPressed: onAlternatives,
                  icon: const Icon(Icons.compare_arrows),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

