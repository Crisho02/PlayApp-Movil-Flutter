import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../state/playapp_state.dart';
import '../theme/playapp_theme.dart';

/// Diálogo modal estilizado como el widget flotante WhatsApp de PlayApp (`chat-widget.css`).
class PlayAppChatSheet extends StatefulWidget {
  const PlayAppChatSheet({super.key});

  @override
  State<PlayAppChatSheet> createState() => _PlayAppChatSheetState();
}

class _PlayAppChatSheetState extends State<PlayAppChatSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  static const _quickPrompts = [
    '¿Qué bebidas frías tienen?',
    'Precio de mojarra',
    'Estado de mi pedido',
    'Métodos de pago',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = preset ?? _controller.text;
    if (text.trim().isEmpty) return;
    PlayAppScope.of(context).enviarMensajeChat(text);
    if (preset == null) {
      _controller.clear();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = PlayAppScope.of(context);
    final messages = state.chatMessages;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: PlayAppColors.chatBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildHeader(context),
            _buildQuickChips(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (context, index) => _ChatBubble(msg: messages[index]),
              ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [PlayAppColors.chatHeaderStart, PlayAppColors.chatHeaderEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            child: ClipOval(
              child: Image.asset(
                'assets/images/chatbot-button-v2.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistente PlayApp',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5,
                  ),
                ),
                Text(
                  'Te ayudo con productos, precios y pedidos.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Cerrar chat',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChips() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEDE6DD),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _quickPrompts.map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                label: Text(prompt, style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                onPressed: () => _send(prompt),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(10),
        color: const Color(0xFFF0F2F5),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Escribe tu mensaje...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: PlayAppColors.chatSendGreen,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              ),
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.msg});

  final ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    final isUser = msg.sender == ChatSender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isUser ? PlayAppColors.chatUserBubble : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 3),
            bottomRight: Radius.circular(isUser ? 3 : 12),
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                msg.text,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
