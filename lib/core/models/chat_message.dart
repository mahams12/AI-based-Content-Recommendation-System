class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final List<String>? options;

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.options,
  });
}

