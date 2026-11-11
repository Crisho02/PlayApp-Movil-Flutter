/// Origen del mensaje dentro del Asistente PlayApp.
enum ChatSender { user, assistant }

/// Mensaje individual del chat asistente flotante.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final ChatSender sender;
  final String text;
  final DateTime timestamp;
}
