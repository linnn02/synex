import 'dart:async';

import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

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
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<MarketProduct> _catalogProducts = [];
  List<MarketProduct> _searchProducts = [];
  List<MarketProduct> _visibleProducts = [];
  List<PrescriptionMedicine> _prescribedMedicines = [];
  List<MedicineProductGroup> _prescriptionGroups = [];

  bool _loading = true;
  bool _searching = false;
  bool _onlyInStock = false;
  String _query = '';
  String _selectedCategory = 'Все';
  String _selectedPharmacy = 'Все';
  String _selectedSubstance = 'Все';
  RangeValues _priceRange = const RangeValues(0, 5000);
  double _maxPrice = 5000;

  @override
  void initState() {
    super.initState();
    _loadMarket();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMarket() async {
    setState(() => _loading = true);

    try {
      final products = await widget.apiService.getMarketProducts();
      final prescriptions = await widget.apiService
          .getMyPrescriptions()
          .catchError((_) => <Prescription>[]);
      final groups =
          widget.prescriptionId == null
              ? <MedicineProductGroup>[]
              : await widget.apiService.getPrescriptionMarketProducts(
                widget.prescriptionId!,
              );

      final prescribed = <String, PrescriptionMedicine>{};
      for (final prescription in prescriptions) {
        for (final medicine in prescription.medicines) {
          prescribed[medicine.activeSubstance] = medicine;
        }
      }
      for (final group in groups) {
        prescribed[group.prescriptionMedicine.activeSubstance] =
            group.prescriptionMedicine;
      }

      final maxPrice =
          products.isEmpty
              ? 5000.0
              : products
                  .map((product) => product.price.toDouble())
                  .reduce((a, b) => a > b ? a : b);

      setState(() {
        _catalogProducts = products;
        _searchProducts = products;
        _prescriptionGroups = groups;
        _prescribedMedicines = prescribed.values.toList();
        _maxPrice = maxPrice < 1000 ? 1000 : maxPrice;
        _priceRange = RangeValues(0, _maxPrice);
        _loading = false;
      });
      _applyFilters();
    } catch (error) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _runSearch(value.trim()),
    );
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _query = query;
      _searching = query.isNotEmpty;
    });

    try {
      final nextProducts =
          query.isEmpty
              ? _catalogProducts
              : await widget.apiService.searchMarketProducts(query);
      setState(() {
        _searchProducts = nextProducts;
        _searching = false;
      });
      _applyFilters();
    } catch (error) {
      setState(() => _searching = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _applyFilters() {
    final source = _query.isEmpty ? _catalogProducts : _searchProducts;
    final nextProducts =
        source.where((product) {
            final categoryMatches =
                _selectedCategory == 'Все' ||
                product.category == _selectedCategory;
            final pharmacyMatches =
                _selectedPharmacy == 'Все' ||
                product.pharmacyName == _selectedPharmacy;
            final substanceMatches =
                _selectedSubstance == 'Все' ||
                product.activeSubstance == _selectedSubstance;
            final stockMatches = !_onlyInStock || product.isInStock;
            final priceMatches =
                product.price >= _priceRange.start &&
                product.price <= _priceRange.end;
            return categoryMatches &&
                pharmacyMatches &&
                substanceMatches &&
                stockMatches &&
                priceMatches;
          }).toList()
          ..sort((a, b) {
            if (a.isInStock != b.isInStock) return a.isInStock ? -1 : 1;
            return a.price.compareTo(b.price);
          });

    setState(() => _visibleProducts = nextProducts);
  }

  List<String> get _categories {
    final values =
        _catalogProducts.map((product) => product.category).toSet().toList()
          ..sort();
    return ['Все', ...values];
  }

  List<String> get _pharmacies {
    final values =
        _catalogProducts.map((product) => product.pharmacyName).toSet().toList()
          ..sort();
    return ['Все', ...values];
  }

  List<String> get _substances {
    final values =
        _catalogProducts
            .map((product) => product.activeSubstance)
            .toSet()
            .toList()
          ..sort();
    return ['Все', ...values];
  }

  List<MarketProduct> get _recommendedProducts {
    final products = [..._catalogProducts]
      ..sort((a, b) => b.stock.compareTo(a.stock));
    return products.take(4).toList();
  }

  Future<void> _addToCart(MarketProduct product) async {
    try {
      await widget.apiService.addToCart(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.title} добавлен в корзину'),
          action: SnackBarAction(label: 'Корзина', onPressed: _openCart),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _showAlternatives(MarketProduct product) async {
    final alternatives = await widget.apiService.getAlternatives(
      product.activeSubstance,
    );
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder:
          (context) => _AlternativesSheet(
            product: product,
            alternatives: alternatives,
            onAdd: _addToCart,
            onOpenProduct: _openProduct,
          ),
    );
  }

  void _openProduct(MarketProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ProductDetailScreen(
              apiService: widget.apiService,
              product: product,
            ),
      ),
    );
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(apiService: widget.apiService),
      ),
    );
  }

  void _showFilters() {
    var draftCategory = _selectedCategory;
    var draftPharmacy = _selectedPharmacy;
    var draftSubstance = _selectedSubstance;
    var draftOnlyInStock = _onlyInStock;
    var draftPrice = _priceRange;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Фильтры',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Только в наличии'),
                        value: draftOnlyInStock,
                        onChanged:
                            (value) =>
                                setModalState(() => draftOnlyInStock = value),
                      ),
                      const SizedBox(height: 8),
                      Text('Цена до ${draftPrice.end.toStringAsFixed(0)} ₸'),
                      RangeSlider(
                        min: 0,
                        max: _maxPrice,
                        divisions: 20,
                        values: draftPrice,
                        labels: RangeLabels(
                          draftPrice.start.toStringAsFixed(0),
                          draftPrice.end.toStringAsFixed(0),
                        ),
                        onChanged:
                            (value) => setModalState(() => draftPrice = value),
                      ),
                      _FilterWrap(
                        title: 'Категория',
                        values: _categories,
                        selected: draftCategory,
                        onSelected:
                            (value) =>
                                setModalState(() => draftCategory = value),
                      ),
                      _FilterWrap(
                        title: 'Аптека',
                        values: _pharmacies,
                        selected: draftPharmacy,
                        onSelected:
                            (value) =>
                                setModalState(() => draftPharmacy = value),
                      ),
                      _FilterWrap(
                        title: 'Действующее вещество',
                        values: _substances,
                        selected: draftSubstance,
                        onSelected:
                            (value) =>
                                setModalState(() => draftSubstance = value),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = 'Все';
                                  _selectedPharmacy = 'Все';
                                  _selectedSubstance = 'Все';
                                  _onlyInStock = false;
                                  _priceRange = RangeValues(0, _maxPrice);
                                });
                                _applyFilters();
                                Navigator.pop(context);
                              },
                              child: const Text('Сбросить'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = draftCategory;
                                  _selectedPharmacy = draftPharmacy;
                                  _selectedSubstance = draftSubstance;
                                  _onlyInStock = draftOnlyInStock;
                                  _priceRange = draftPrice;
                                });
                                _applyFilters();
                                Navigator.pop(context);
                              },
                              child: const Text('Применить'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аптека'),
        actions: [
          IconButton(
            tooltip: 'Корзина',
            onPressed: _openCart,
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadMarket,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _MarketHero(
                      controller: _searchController,
                      searching: _searching,
                      onChanged: _onSearchChanged,
                      onFilterTap: _showFilters,
                    ),
                    const SizedBox(height: 16),
                    _CategoryStrip(
                      categories: _categories,
                      selected: _selectedCategory,
                      onSelected: (category) {
                        setState(() => _selectedCategory = category);
                        _applyFilters();
                      },
                    ),
                    if (_prescribedMedicines.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _PrescribedMedicinesBlock(
                        medicines: _prescribedMedicines,
                        groups: _prescriptionGroups,
                        onSearchMedicine: (medicine) {
                          _searchController.text = medicine.medicineName;
                          _runSearch(medicine.medicineName);
                        },
                      ),
                    ],
                    const SizedBox(height: 18),
                    _SectionHeader(
                      title: 'Популярное',
                      subtitle: 'Часто выбирают в аптечном маркете',
                      trailing: '${_recommendedProducts.length} товара',
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 184,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recommendedProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final product = _recommendedProducts[index];
                          return _CompactProductCard(
                            product: product,
                            onTap: () => _openProduct(product),
                            onAdd: () => _addToCart(product),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    _SectionHeader(
                      title:
                          _query.isEmpty
                              ? 'Каталог лекарств'
                              : 'Результаты поиска',
                      subtitle:
                          _query.isEmpty
                              ? 'Цены, наличие и аптеки рядом'
                              : 'По запросу “$_query”',
                      trailing: '${_visibleProducts.length}',
                    ),
                    const SizedBox(height: 10),
                    if (_searching)
                      const _LoadingList()
                    else if (_visibleProducts.isEmpty)
                      _EmptyMarketState(
                        onReset: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _searchProducts = _catalogProducts;
                            _selectedCategory = 'Все';
                            _selectedPharmacy = 'Все';
                            _selectedSubstance = 'Все';
                            _onlyInStock = false;
                            _priceRange = RangeValues(0, _maxPrice);
                          });
                          _applyFilters();
                        },
                      )
                    else
                      ..._visibleProducts.map(
                        (product) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MarketProductCard(
                            product: product,
                            onTap: () => _openProduct(product),
                            onAdd: () => _addToCart(product),
                            onAlternatives: () => _showAlternatives(product),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}

class _MarketHero extends StatelessWidget {
  const _MarketHero({
    required this.controller,
    required this.searching,
    required this.onChanged,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final bool searching;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF003C3A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Аптечный маркет',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Поиск назначенных препаратов, цены, наличие и аналоги',
            style: TextStyle(color: Color(0xFFD6F5EE), height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: 'Поиск лекарства',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        searching
                            ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                            : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'Фильтры',
                onPressed: onFilterTap,
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          return ChoiceChip(
            label: Text(category),
            selected: selected == category,
            onSelected: (_) => onSelected(category),
          );
        },
      ),
    );
  }
}

class _PrescribedMedicinesBlock extends StatelessWidget {
  const _PrescribedMedicinesBlock({
    required this.medicines,
    required this.groups,
    required this.onSearchMedicine,
  });

  final List<PrescriptionMedicine> medicines;
  final List<MedicineProductGroup> groups;
  final ValueChanged<PrescriptionMedicine> onSearchMedicine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Назначенные лекарства',
            subtitle: 'Из цифровых назначений врача',
            trailing: '${medicines.length}',
          ),
          const SizedBox(height: 12),
          ...medicines.map((medicine) {
            final matchedCount = groups
                .where(
                  (group) =>
                      group.prescriptionMedicine.activeSubstance ==
                      medicine.activeSubstance,
                )
                .fold<int>(0, (sum, group) => sum + group.products.length);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSearchMedicine(medicine),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.medication_outlined,
                        color: Color(0xFF007F6D),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${medicine.medicineName} ${medicine.dosage}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${medicine.frequency} · ${medicine.duration}',
                              style: const TextStyle(color: Color(0xFF60727F)),
                            ),
                          ],
                        ),
                      ),
                      _SoftBadge(
                        label:
                            matchedCount > 0
                                ? '$matchedCount найдено'
                                : 'Найти',
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Color(0xFF60727F))),
            ],
          ),
        ),
        _SoftBadge(label: trailing),
      ],
    );
  }
}

class _MarketProductCard extends StatelessWidget {
  const _MarketProductCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
    required this.onAlternatives,
  });

  final MarketProduct product;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onAlternatives;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductIcon(category: product.category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            _StockBadge(stock: product.stock),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${product.dosage} · ${product.form}',
                          style: const TextStyle(color: Color(0xFF425766)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ДВ: ${product.activeSubstance} · ${product.manufacturer}',
                          style: const TextStyle(
                            color: Color(0xFF60727F),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.priceText,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          product.pharmacyName,
                          style: const TextStyle(color: Color(0xFF60727F)),
                        ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: 'Аналоги',
                    onPressed: onAlternatives,
                    icon: const Icon(Icons.compare_arrows),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: product.isInStock ? onAdd : null,
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('В корзину'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactProductCard extends StatelessWidget {
  const _CompactProductCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  final MarketProduct product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 174,
      child: Card(
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ProductIcon(category: product.category, compact: true),
                    const Spacer(),
                    _StockBadge(stock: product.stock, compact: true),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  product.form,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF60727F),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.priceText,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton.filled(
                      tooltip: 'В корзину',
                      onPressed: product.isInStock ? onAdd : null,
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlternativesSheet extends StatelessWidget {
  const _AlternativesSheet({
    required this.product,
    required this.alternatives,
    required this.onAdd,
    required this.onOpenProduct,
  });

  final MarketProduct product;
  final List<MarketProduct> alternatives;
  final ValueChanged<MarketProduct> onAdd;
  final ValueChanged<MarketProduct> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final items = alternatives.where((item) => item.id != product.id).toList();

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder:
            (context, controller) => ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              children: [
                Text(
                  'Аналоги',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Аналог не означает автоматическую замену. Перед заменой препарата проконсультируйтесь с врачом или фармацевтом.',
                  style: TextStyle(color: Color(0xFF60727F), height: 1.4),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const _InlineEmptyState(
                    text:
                        'По этому действующему веществу пока нет других товаров.',
                  )
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MarketProductCard(
                        product: item,
                        onTap: () {
                          Navigator.pop(context);
                          onOpenProduct(item);
                        },
                        onAdd: () => onAdd(item),
                        onAlternatives: () {},
                      ),
                    ),
                  ),
              ],
            ),
      ),
    );
  }
}

class _FilterWrap extends StatelessWidget {
  const _FilterWrap({
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                values.map((value) {
                  return ChoiceChip(
                    label: Text(value),
                    selected: selected == value,
                    onSelected: (_) => onSelected(value),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ProductIcon extends StatelessWidget {
  const _ProductIcon({required this.category, this.compact = false});

  final String category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final icon = switch (category) {
      'Антибиотики' => Icons.biotech_outlined,
      'Температура и боль' => Icons.thermostat_outlined,
      'Аллергия' => Icons.air_outlined,
      'Горло' => Icons.healing_outlined,
      'Витамины' => Icons.spa_outlined,
      _ => Icons.medication_outlined,
    };

    return Container(
      width: compact ? 38 : 48,
      height: compact ? 38 : 48,
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF007F6D),
        size: compact ? 20 : 24,
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock, this.compact = false});

  final int stock;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final inStock = stock > 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: 5),
      decoration: BoxDecoration(
        color: inStock ? const Color(0xFFE9F8F4) : const Color(0xFFFFF0ED),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        inStock ? 'В наличии' : 'Нет',
        style: TextStyle(
          color: inStock ? const Color(0xFF007F6D) : const Color(0xFF9E2A1B),
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF425766),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          height: 118,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _EmptyMarketState extends StatelessWidget {
  const _EmptyMarketState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 44, color: Color(0xFF60727F)),
          const SizedBox(height: 10),
          const Text(
            'Ничего не найдено',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Попробуйте изменить запрос или сбросить фильтры.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF60727F)),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onReset,
            child: const Text('Сбросить фильтры'),
          ),
        ],
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF60727F))),
    );
  }
}
