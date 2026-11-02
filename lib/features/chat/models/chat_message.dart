import 'package:local_ai_kit/local_ai_kit.dart';

/// A single message exchanged in the conversation.
class ChatMessage {
  const ChatMessage({
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.sources = const [],
    this.isError = false,
  });

  /// Whether the message was written by the user.
  final bool isUser;

  /// Text content displayed inside the bubble.
  final String text;

  /// When the message was created.
  final DateTime timestamp;

  /// Passages retrieved from the local index that supported the answer.
  final List<RetrievalResult> sources;

  /// Whether the message reports a failure instead of an answer.
  final bool isError;
}
