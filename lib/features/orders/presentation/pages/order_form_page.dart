import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  bool _clientError = false;
  DateTime? _deliveryDate;
  bool _clearDelivery = false;
  // New photos to upload: (file, description, price)
  final _photos = <(File, String, double)>[];
  // Local cache of edited fields for existing photos
  final _photoDescChanges = <String, String>{};
  final _photoPriceChanges = <String, double>{};
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
    setState(() => _photos.add((File(xfile.path), '', 0.0)));
  }

  // ── Client picker bottom sheet ──────────────────────────────────────────
  void _showClientSheet(List clients) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClientPickerSheet(
        clients: clients,
        selectedId: _selectedClientId,
        onSelected: (id) {
          setState(() { _selectedClientId = id; _clientError = false; });
          Navigator.pop(context);
        },
        onAddNew: () async {
          Navigator.pop(context);
          // ClientFormPage devuelve el ID del cliente creado
          final newId = await context.push<String>('/clientes/nuevo');
          await ref.read(clientsProvider.notifier).loadClients();
          if (newId != null && mounted) {
            setState(() { _selectedClientId = newId; _clientError = false; });
          }
        },
      ),
    );
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
    // Validate client (required)
    if (_selectedClientId == null) {
      setState(() => _clientError = true);
      return;
    }
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _clientError = false; });
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
      if (ok) {
        // Save description + price changes for existing photos
        for (final entry in _photoDescChanges.entries) {
          await ref.read(ordersProvider.notifier).updatePhotoDescription(entry.key, entry.value);
        }
        for (final entry in _photoPriceChanges.entries) {
          await ref.read(ordersProvider.notifier).updatePhotoPrice(entry.key, entry.value);
        }
        // Upload any new photos added in edit mode
        for (final (file, desc, price) in _photos) {
          await ref.read(ordersProvider.notifier).addPhotoToOrder(widget.orderId!, file, desc, price: price);
        }
        // Reload to reflect all changes
        await ref.read(ordersProvider.notifier).loadOrders();
      }
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
            // Client selector (required)
            Row(
              children: [
                const Text('Cliente', style: AppTextStyles.labelLarge),
                const SizedBox(width: 4),
                Text('*', style: AppTextStyles.labelLarge.copyWith(color: AppColors.danger)),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showClientSheet(clients),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  border: Border.all(
                    color: _clientError ? AppColors.danger : AppColors.border,
                    width: _clientError ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: _clientError ? AppColors.danger : AppColors.inkLight,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedClientId != null
                            ? (clients.where((c) => c.id == _selectedClientId).firstOrNull?.name ?? 'Cliente')
                            : 'Selecciona un cliente',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _selectedClientId != null ? AppColors.ink : (_clientError ? AppColors.danger : AppColors.inkFaint),
                        ),
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded, size: 20, color: AppColors.inkFaint),
                  ],
                ),
              ),
            ),
            if (_clientError) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.danger),
                  const SizedBox(width: 4),
                  Text('Debes seleccionar un cliente', style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger)),
                ],
              ),
            ],
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
            // Photos section (both create and edit)
            const SizedBox(height: 24),
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
            // Existing photos (edit mode)
            if (isEdit) ...[
              ...(_existing?.photos ?? []).map((photo) => _ExistingPhotoEditItem(
                photo: photo,
                // Store changes locally — saved to DB only on submit
                onDescriptionChanged: (desc) => _photoDescChanges[photo.id] = desc,
                onPriceChanged: (price) => _photoPriceChanges[photo.id] = price,
                onRemove: () =>
                    ref.read(ordersProvider.notifier).deletePhoto(photo.id, photo.photoUrl),
              )),
            ],
            // New photos to upload
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 4),
              ..._photos.asMap().entries.map((e) => _PhotoEditItem(
                file: e.value.$1,
                description: e.value.$2,
                price: e.value.$3,
                onDescriptionChanged: (d) => setState(() => _photos[e.key] = (e.value.$1, d, e.value.$3)),
                onPriceChanged: (p) => setState(() => _photos[e.key] = (e.value.$1, e.value.$2, p)),
                onRemove: () => setState(() => _photos.removeAt(e.key)),
              )),
            ] else if (!isEdit) ...[
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

// ── Client Picker Bottom Sheet ──────────────────────────────────────────────
class _ClientPickerSheet extends StatefulWidget {
  final List clients;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final VoidCallback onAddNew;

  const _ClientPickerSheet({
    required this.clients,
    required this.selectedId,
    required this.onSelected,
    required this.onAddNew,
  });

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.clients
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Seleccionar cliente', style: AppTextStyles.headlineSmall),
                const Spacer(),
                if (widget.selectedId != null)
                  GestureDetector(
                    onTap: () => widget.onSelected(null),
                    child: Text(
                      'Limpiar',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Buscar cliente…',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
                filled: true,
                fillColor: AppColors.parchment,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          // Client list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                // Sin cliente option
                _ClientTile(
                  name: 'Sin cliente',
                  subtitle: null,
                  isSelected: widget.selectedId == null,
                  icon: Icons.person_off_outlined,
                  onTap: () => widget.onSelected(null),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No se encontraron clientes',
                        style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  )
                else
                  ...filtered.map((c) => _ClientTile(
                    name: c.name,
                    subtitle: c.phone,
                    isSelected: widget.selectedId == c.id,
                    icon: Icons.person_outline_rounded,
                    onTap: () => widget.onSelected(c.id),
                  )),
              ],
            ),
          ),
          // Divider
          const Divider(height: 1),
          // Add new client button
          InkWell(
            onTap: widget.onAddNew,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_outlined, size: 18, color: AppColors.accent),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Agregar nuevo cliente',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.accent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  final String name;
  final String? subtitle;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _ClientTile({
    required this.name,
    required this.subtitle,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.accent : AppColors.inkFaint),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? AppColors.accent : AppColors.ink,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}


// ── Photo edit item with fullscreen viewer ───────────────────────────────────
class _PhotoEditItem extends StatefulWidget {
  final File file;
  final String description;
  final double price;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<double> onPriceChanged;
  final VoidCallback onRemove;

  const _PhotoEditItem({
    required this.file,
    required this.description,
    this.price = 0,
    required this.onDescriptionChanged,
    required this.onPriceChanged,
    required this.onRemove,
  });

  @override
  State<_PhotoEditItem> createState() => _PhotoEditItemState();
}

class _PhotoEditItemState extends State<_PhotoEditItem> {
  late final TextEditingController _ctrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.description);
    _priceCtrl = TextEditingController(text: widget.price > 0 ? widget.price.toStringAsFixed(widget.price == widget.price.toInt() ? 0 : 2) : '');
  }

  @override
  void didUpdateWidget(_PhotoEditItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.description != widget.description && _ctrl.text != widget.description) {
      _ctrl.text = widget.description;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _PhotoFullscreenView(
          file: widget.file,
          description: _ctrl.text,
          onDescriptionChanged: (d) {
            widget.onDescriptionChanged(d);
            setState(() => _ctrl.text = d);
          },
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
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
          // Tappable thumbnail
          GestureDetector(
            onTap: _openFullscreen,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(widget.file, width: 80, height: 80, fit: BoxFit.cover),
                ),
                Positioned(
                  bottom: 4, right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                    child: const Icon(Icons.fullscreen_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Descripción…',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  onChanged: widget.onDescriptionChanged,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'Precio',
                    prefixText: r'$',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent, width: 1)),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.accent),
                  onChanged: (v) {
                    final parsed = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                    widget.onPriceChanged(parsed);
                  },
                ),
              ],
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

// ── Existing photo editor (network image) ─────────────────────────────────────
class _ExistingPhotoEditItem extends StatefulWidget {
  final OrderPhotoEntity photo;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<double> onPriceChanged;
  final Future<bool> Function() onRemove;

  const _ExistingPhotoEditItem({
    required this.photo,
    required this.onDescriptionChanged,
    required this.onPriceChanged,
    required this.onRemove,
  });

  @override
  State<_ExistingPhotoEditItem> createState() => _ExistingPhotoEditItemState();
}

class _ExistingPhotoEditItemState extends State<_ExistingPhotoEditItem> {
  late final TextEditingController _ctrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.photo.description);
    _priceCtrl = TextEditingController(
      text: widget.photo.price > 0
          ? widget.photo.price.toStringAsFixed(widget.photo.price == widget.photo.price.toInt() ? 0 : 2)
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _ExistingPhotoFullscreenView(
          photo: widget.photo,
          description: _ctrl.text,
          onDescriptionChanged: (d) {
            setState(() => _ctrl.text = d);
            widget.onDescriptionChanged(d);
          },
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
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
          GestureDetector(
            onTap: _openFullscreen,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.photo.photoUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.borderLight,
                      child: const Icon(Icons.image_outlined, color: AppColors.inkFaint),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                    child: const Icon(Icons.fullscreen_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Descripción de la foto…',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  onChanged: widget.onDescriptionChanged,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'Precio',
                    prefixText: r'$',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent, width: 1)),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.accent),
                  onChanged: (v) {
                    final parsed = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                    widget.onPriceChanged(parsed);
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.danger),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.cream,
                  title: const Text('Eliminar foto', style: AppTextStyles.headlineSmall),
                  content: const Text('¿Eliminar esta foto del encargo?', style: AppTextStyles.bodyMedium),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Eliminar', style: AppTextStyles.labelLarge.copyWith(color: AppColors.danger))),
                  ],
                ),
              );
              if (ok == true) widget.onRemove();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Existing photo fullscreen (editable) ──────────────────────────────────────
class _ExistingPhotoFullscreenView extends StatefulWidget {
  final OrderPhotoEntity photo;
  final String description;
  final ValueChanged<String> onDescriptionChanged;

  const _ExistingPhotoFullscreenView({required this.photo, required this.description, required this.onDescriptionChanged});

  @override
  State<_ExistingPhotoFullscreenView> createState() => _ExistingPhotoFullscreenViewState();
}

class _ExistingPhotoFullscreenViewState extends State<_ExistingPhotoFullscreenView> {
  late final TextEditingController _ctrl;
  bool _showOverlay = true;

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => setState(() => _showOverlay = !_showOverlay),
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: widget.photo.photoUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white54)),
                errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48)),
              ),
            ),
            AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              bottom: _showOverlay ? 0 : -250,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xDD000000), Color(0x88000000), Colors.transparent],
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: 20, right: 20, top: 32,
                    bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [
                        const Icon(Icons.edit_outlined, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text('Descripción', style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
                      ]),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ctrl,
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: 'Agrega una descripción…',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white38),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white60)),
                          contentPadding: const EdgeInsets.only(bottom: 4),
                        ),
                        onChanged: widget.onDescriptionChanged,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fullscreen photo viewer with editable description overlay ─────────────────
class _PhotoFullscreenView extends StatefulWidget {
  final File file;
  final String description;
  final ValueChanged<String> onDescriptionChanged;

  const _PhotoFullscreenView({
    required this.file,
    required this.description,
    required this.onDescriptionChanged,
  });

  @override
  State<_PhotoFullscreenView> createState() => _PhotoFullscreenViewState();
}

class _PhotoFullscreenViewState extends State<_PhotoFullscreenView> {
  late final TextEditingController _ctrl;
  bool _showOverlay = true;

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => setState(() => _showOverlay = !_showOverlay),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full image
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.file(
                widget.file,
                fit: BoxFit.contain,
              ),
            ),
            // Top bar: close button
            AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom overlay: editable description
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              bottom: _showOverlay ? 0 : -200,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {}, // prevent toggle when tapping overlay
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xDD000000), Color(0x88000000), Colors.transparent],
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 32,
                    bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            'Descripción',
                            style: AppTextStyles.labelMedium.copyWith(color: Colors.white70, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ctrl,
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: 'Agrega una descripción…',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white38),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white60),
                          ),
                          contentPadding: const EdgeInsets.only(bottom: 4),
                        ),
                        onChanged: widget.onDescriptionChanged,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
