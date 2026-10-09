import 'package:flutter/material.dart';

import '../../core/theme/shop_theme.dart';
import '../../core/utils/product_validators.dart';
import '../../models/shop_product.dart';
import '../../services/shop_product_service.dart';

/// Add (CREATE) or edit (UPDATE) a piece of equipment.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  /// When null the form creates a new product, otherwise it edits this one.
  final ShopProduct? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  static const _categories = [
    'Mountain Bikes',
    'Cricket',
    'Football',
    'Camping',
    'Gym',
    'Water Sports',
    'Racket Sports',
    'Other',
  ];
  static const _conditions = ['Excellent', 'Good', 'Fair'];

  final _formKey = GlobalKey<FormState>();
  final _service = ShopProductService();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _deposit;
  late final TextEditingController _quantity;
  late final TextEditingController _imageUrl;
  late String _category;
  late String _condition;
  late bool _available;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(
        text: p == null ? '' : p.pricePerDay.toStringAsFixed(2));
    _deposit = TextEditingController(
        text: p == null ? '' : p.deposit.toStringAsFixed(2));
    _quantity = TextEditingController(text: p == null ? '1' : '${p.quantity}');
    _imageUrl = TextEditingController(text: p?.imageUrl ?? '');
    _category = p?.category ?? _categories.first;
    _condition = p?.condition ?? 'Excellent';
    _available = p?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _deposit.dispose();
    _quantity.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  String? _required(String? v) => ProductValidators.requiredField(v);

  String? _money(String? v) => ProductValidators.money(v);

  String? _quantityRule(String? v) => ProductValidators.quantity(v);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final product = ShopProduct(
        id: widget.product?.id ?? '',
        ownerId: widget.product?.ownerId ?? '',
        name: _name.text.trim(),
        category: _category,
        description: _description.text.trim(),
        condition: _condition,
        pricePerDay: double.parse(_price.text.trim()),
        deposit: double.parse(_deposit.text.trim()),
        quantity: int.parse(_quantity.text.trim()),
        isAvailable: _available,
        imageUrl: _imageUrl.text.trim(),
      );
      if (_isEdit) {
        await _service.updateProduct(product);
      } else {
        await _service.addProduct(product);
      }
      nav.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Equipment updated' : 'Equipment added'),
      ));
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit equipment' : 'Add equipment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Equipment name',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            Text('Category', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _categories
                  .map((c) => ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Condition', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _conditions
                  .map((c) => ChoiceChip(
                        label: Text(c),
                        selected: _condition == c,
                        onSelected: (_) => setState(() => _condition = c),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Condition notes / description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Price per day',
                      border: OutlineInputBorder(),
                    ),
                    validator: _money,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _deposit,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Refundable deposit',
                      border: OutlineInputBorder(),
                    ),
                    validator: _money,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity in stock',
                border: OutlineInputBorder(),
              ),
              validator: _quantityRule,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available for rent'),
              value: _available,
              onChanged: (v) => setState(() => _available = v),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEdit ? 'Save changes' : 'Add to inventory'),
          ),
        ),
      ),
    );
  }
}
