import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../presentation/notifiers/orders_notifier.dart';
import '../../../clients/presentation/notifiers/clients_notifier.dart';
import '../../domain/entities/order_entity.dart';
import '../../../../core/utils/date_helper.dart';

class OrderFormPage extends ConsumerStatefulWidget {
  final String? orderId;
  const OrderFormPage({super.key, this.orderId});

  @override
  ConsumerState<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends ConsumerState<OrderFormPage> {
  final _notesCtrl = TextEditingController();
  String? _selectedClientId;
  DateTime? _deliveryDate;
  bool _clearDelivery = false;
  final _photos = <(File, String)>[];
  final _picker = ImagePicker();
  bool _loading = false;
  final _form = GlobalKey<FormState>();

  OrderEntity? get _existing {
    if (widget.orderId == null) return null;
    return ref.read(ordersProvider).orders.where((o) => o.id == widget.orderId).firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientsProvider.notifier).loadClients();
      final ex = _existing;
      if (ex != null) {
        _notesCtrl.text = ex.notes ?? '';
        _selectedClientId = ex.clientId;
        _deliveryDate = ex.deliveryDate;
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
    if (xfile == null) return;
    setState(() => _photos.add((File(xfile.path), '')));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.symmetric(vertical: 12)),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.accent),
              title: const Text('Tomar foto', style: AppTextStyles.bodyMedium),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
              title: const Text('Elegir de galería', style: AppTextStyles.bodyMedium),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    bool ok;
    if (widget.orderId == null) {
      ok = await ref.read(ordersProvider.notifier).createOrder(
        clientId: _selectedClientId,
        deliveryDate: _deliveryDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        photos: _photos,
      );
    } else {
      ok = await ref.read(ordersProvider.notifier).updateOrder(
        widget.orderId!,
        clientId: _selectedClientId,
        deliveryDate: _deliveryDate,
        clearDeliveryDate: _clearDelivery,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    }
    setState(() => _loading = false);
    if (ok && mounted) context.pop();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      initialDate: _deliveryDate ?? DateTime.now(),
      locale: const Locale('es'),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.accent, surface: AppColors.parchment)), child: child!),
    );
    if (date != null) setState(() { _deliveryDate = date; _clearDelivery = false; });
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider).clients;
    final isEdit = widget.orderId != null;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(isEdit ? 'Editar encargo' : 'Nuevo encargo', style: AppTextStyles.headlineMedium)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Client selector
            const Text('Cliente', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedClientId,
              decoration: const InputDecoration(hintText: 'Selecciona un cliente', prefixIcon: Icon(Icons.person_outline_rounded, size: 18)),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin cliente')),
                ...clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) => setState(() => _selectedClientId = v),
              dropdownColor: AppColors.parchment,
            ),
            const SizedBox(height: 20),
            // Delivery date
            const Text('Fecha de entrega', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.inkLight),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _deliveryDate != null ? DateHelper.formatFull(_deliveryDate!) : 'Sin fecha de entrega (opcional)',
                        style: AppTextStyles.bodyMedium.copyWith(color: _deliveryDate != null ? AppColors.ink : AppColors.inkFaint),
                      ),
                    ),
                    if (_deliveryDate != null)
                      GestureDetector(
                        onTap: () => setState(() { _deliveryDate = null; _clearDelivery = true; }),
                        child: const Icon(Icons.clear_rounded, size: 16, color: AppColors.inkFaint),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Notes
            const Text('Notas adicionales', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Detalles del encargo…', alignLabelWithHint: true),
            ),
            if (!isEdit) ...[
              const SizedBox(height: 24),
              // Photos section
              Row(
                children: [
                  const Text('Fotos', style: AppTextStyles.headlineSmall),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showImageSourceSheet,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              if (_photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._photos.asMap().entries.map((e) => _PhotoEditItem(
                  file: e.value.$1,
                  description: e.value.$2,
                  onDescriptionChanged: (d) => setState(() => _photos[e.key] = (e.value.$1, d)),
                  onRemove: () => setState(() => _photos.removeAt(e.key)),
                )),
              ] else ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.parchment,
                      border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined, color: AppColors.inkFaint, size: 30),
                        const SizedBox(height: 6),
                        Text('Toca para agregar fotos', style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : Text(isEdit ? 'Guardar cambios' : 'Crear encargo'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Removes the unused formatDate method
}

class _PhotoEditItem extends StatefulWidget {
  final File file;
  final String description;
  final ValueChanged<String> onDescriptionChanged;
  final VoidCallback onRemove;

  const _PhotoEditItem({required this.file, required this.description, required this.onDescriptionChanged, required this.onRemove});

  @override
  State<_PhotoEditItem> createState() => _PhotoEditItemState();
}

class _PhotoEditItemState extends State<_PhotoEditItem> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.description);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(widget.file, width: 72, height: 72, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(hintText: 'Descripción de la foto…', filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, contentPadding: EdgeInsets.zero),
              style: AppTextStyles.bodySmall,
              maxLines: 3,
              onChanged: widget.onDescriptionChanged,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.danger),
            onPressed: widget.onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
