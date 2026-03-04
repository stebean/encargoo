import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kMsgTemplateKey = 'whatsapp_message_template';
const String defaultMessageTemplate =
    'Hola {nombre}, su encargo está listo 🎉\nEl total es \${total}.\n\n¡Gracias por su preferencia!';

// Provider that loads and exposes the message template
final messageTemplateProvider = AsyncNotifierProvider<MessageTemplateNotifier, String>(
  MessageTemplateNotifier.new,
);

class MessageTemplateNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kMsgTemplateKey) ?? defaultMessageTemplate;
  }

  Future<void> save(String template) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMsgTemplateKey, template);
    state = AsyncData(template);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kMsgTemplateKey);
    state = const AsyncData(defaultMessageTemplate);
  }

  /// Replaces {nombre} and ${total} with actual values
  String buildMessage(String clientName, double total) {
    final template = state.value ?? defaultMessageTemplate;
    final totalStr = '\$${total.toStringAsFixed(total == total.toInt() ? 0 : 2)}';
    return template
        .replaceAll('{nombre}', clientName)
        .replaceAll('\${total}', totalStr)
        .replaceAll('{total}', totalStr);
  }
}
