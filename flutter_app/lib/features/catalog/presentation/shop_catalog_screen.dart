import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/catalog_provider.dart';
import '../domain/product.dart';

class ShopCatalogScreen extends ConsumerWidget {
  const ShopCatalogScreen({super.key});

  static const _accent = Color(0xFFD9381E);
  static const _bg = Color(0xFFF9F6F0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catalogProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Каталог',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(catalogProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductSheet(context, ref, null),
        backgroundColor: _accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Добавить',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.read(catalogProvider.notifier).refresh(),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (products) => products.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🍣', style: TextStyle(fontSize: 56)),
                    SizedBox(height: 12),
                    Text('Каталог пуст — добавьте первый товар',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(catalogProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ShopProductTile(
                    product: products[i],
                    onEdit: () =>
                        _showProductSheet(context, ref, products[i]),
                    onDelete: () => _confirmDelete(context, ref, products[i]),
                  ),
                ),
              ),
      ),
    );
  }

  void _showProductSheet(BuildContext context, WidgetRef ref, Product? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProductFormSheet(existing: existing, ref: ref),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Product p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить товар?'),
        content: Text('«${p.name}» будет удалён из каталога.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(catalogProvider.notifier).delete(p.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class _ShopProductTile extends StatelessWidget {
  const _ShopProductTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _accent = Color(0xFFD9381E);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: product.imageUrl.isNotEmpty
              ? Image.network(
                  product.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _Placeholder(),
                )
              : const _Placeholder(),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          product.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${product.price.toStringAsFixed(0)} ₽',
              style: const TextStyle(
                color: _accent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Удалить',
                        style: TextStyle(color: Colors.red))),
              ],
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      color: const Color(0xFFEEE8E0),
      child: const Center(child: Text('🍱', style: TextStyle(fontSize: 22))),
    );
  }
}

class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet({required this.existing, required this.ref});

  final Product? existing;
  final WidgetRef ref;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  static const _accent = Color(0xFFD9381E);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _imageCtrl;
  late String _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl =
        TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _imageCtrl = TextEditingController(text: p?.imageUrl ?? '');
    _type = p?.type ?? 'sushi';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final product = Product(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim()),
      imageUrl: _imageCtrl.text.trim(),
      type: _type,
    );

    try {
      if (widget.existing == null) {
        await widget.ref.read(catalogProvider.notifier).create(product);
      } else {
        await widget.ref
            .read(catalogProvider.notifier)
            .editProduct(widget.existing!.id, product);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Редактировать товар' : 'Новый товар',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const SizedBox(height: 16),
            _Field(ctrl: _nameCtrl, label: 'Название', required: true),
            const SizedBox(height: 10),
            _Field(ctrl: _descCtrl, label: 'Описание'),
            const SizedBox(height: 10),
            _Field(
              ctrl: _priceCtrl,
              label: 'Цена (₽)',
              required: true,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Обязательное поле';
                if (double.tryParse(v) == null) return 'Введите число';
                return null;
              },
            ),
            const SizedBox(height: 10),
            _Field(ctrl: _imageCtrl, label: 'URL изображения'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(
                labelText: 'Тип',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accent, width: 1.8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
              ),
              items: const [
                DropdownMenuItem(value: 'sushi', child: Text('Суши')),
                DropdownMenuItem(value: 'roll', child: Text('Роллы')),
                DropdownMenuItem(value: 'drink', child: Text('Напитки')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'sushi'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        isEdit ? 'Сохранить' : 'Добавить',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl,
    required this.label,
    this.required = false,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController ctrl;
  final String label;
  final bool required;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator ??
          (required
              ? (v) => (v == null || v.isEmpty) ? 'Обязательное поле' : null
              : null),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFD9381E), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
