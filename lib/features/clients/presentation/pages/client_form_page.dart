import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../notifiers/clients_notifier.dart';

class ClientFormPage extends ConsumerStatefulWidget {
  final String? clientId;
  const ClientFormPage({super.key, this.clientId});

  @override
  ConsumerState<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends ConsumerState<ClientFormPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.clientId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final client = ref.read(clientsProvider).clients.where((c) => c.id == widget.clientId).firstOrNull;
        if (client != null) {
          _nameCtrl.text = client.name;
          _phoneCtrl.text = client.phone ?? '';
          _notesCtrl.text = client.notes ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    bool ok;
    final notifier = ref.read(clientsProvider.notifier);
    final phone = _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();
    final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    if (widget.clientId == null) {
      ok = await notifier.createClient(name: _nameCtrl.text.trim(), phone: phone, notes: notes);
    } else {
      ok = await notifier.updateClient(widget.clientId!, name: _nameCtrl.text.trim(), phone: phone, notes: notes);
    }
    setState(() => _loading = false);
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.clientId != null;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(isEdit ? 'Editar cliente' : 'Nuevo cliente', style: AppTextStyles.headlineMedium)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre completo *', prefixIcon: Icon(Icons.person_outline_rounded, size: 18)),
              validator: (v) => (v?.isEmpty ?? true) ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono (WhatsApp)',
                prefixIcon: Icon(Icons.phone_outlined, size: 18),
                hintText: '+52 000 000 0000',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notas', prefixIcon: Icon(Icons.notes_rounded, size: 18), alignLabelWithHint: true),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : Text(isEdit ? 'Guardar cambios' : 'Agregar cliente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
