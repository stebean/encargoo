import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../notifiers/clients_notifier.dart';
import '../../domain/entities/client_entity.dart';

class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});

  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(clientsProvider.notifier).loadClients());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientsProvider);
    final notifier = ref.read(clientsProvider.notifier);
    final results = notifier.search(_query);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Clientes', style: AppTextStyles.headlineMedium),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('${state.clients.length}', style: AppTextStyles.caption),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar cliente…',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline_rounded, size: 54, color: AppColors.borderLight),
                            const SizedBox(height: 14),
                            Text(_query.isEmpty ? 'No hay clientes registrados' : 'Sin resultados', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.inkFaint)),
                            if (_query.isEmpty) ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => context.go('/clientes/nuevo'),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Agregar cliente'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ClientCard(
                          client: results[i],
                          onEdit: () => context.go('/clientes/${results[i].id}/editar'),
                          onDelete: () => _confirmDelete(context, ref, results[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/clientes/nuevo'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, ClientEntity client) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Eliminar cliente', style: AppTextStyles.headlineSmall),
        content: Text('¿Eliminar a ${client.name}?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) await ref.read(clientsProvider.notifier).deleteClient(client.id);
  }
}

class _ClientCard extends StatelessWidget {
  final ClientEntity client;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClientCard({required this.client, required this.onEdit, required this.onDelete});

  Future<void> _openWhatsApp(String phone) async {
    // Remove everything but plus and digits to clean the input
    String clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check if the number does NOT start with a '+'
    if (!clean.startsWith('+')) {
      // Si no tiene código de país, le agregamos el +52 por defecto
      clean = '+52$clean';
    }
    
    // Now keep only digits for the actual link (wa.me expects only digits, no +)
    final digitsOnly = clean.replaceAll(RegExp(r'\D'), '');
    
    final uri = Uri.parse('https://wa.me/$digitsOnly');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Podrías mostrar un mensaje de error si necesitas, per fallback to browser
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: AppColors.borderLight, shape: BoxShape.circle),
            child: Center(
              child: Text(client.name[0].toUpperCase(), style: AppTextStyles.headlineSmall.copyWith(color: AppColors.accent)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.name, style: AppTextStyles.headlineSmall.copyWith(fontSize: 15)),
                if (client.phone != null && client.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(client.phone!, style: AppTextStyles.bodySmall),
                ],
                if (client.notes != null && client.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(client.notes!, style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (client.phone != null && client.phone!.isNotEmpty)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 26),
              onPressed: () => _openWhatsApp(client.phone!),
              tooltip: 'WhatsApp',
            ),
          PopupMenuButton<String>(
            color: AppColors.parchment,
            icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.inkFaint),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar', style: AppTextStyles.bodyMedium)),
              PopupMenuItem(value: 'delete', child: Text('Eliminar', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger))),
            ],
            onSelected: (v) { if (v == 'edit') {
              onEdit();
            } else {
              onDelete();
            } },
          ),
        ],
      ),
    );
  }
}
