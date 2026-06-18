import '../models/message.dart';

/// Chat-specific events

abstract class ChatEvent {}

class MessageReceivedEvent extends ChatEvent {
  final Message message;

  MessageReceivedEvent(this.message);

  @override
  String toString() => 'MessageReceivedEvent(message: ${message.id})';
}

class MessageStartEvent extends ChatEvent {
  final String messageId;

  MessageStartEvent(this.messageId);

  @override
  String toString() => 'MessageStartEvent(messageId: $messageId)';
}

class MessageChunkEvent extends ChatEvent {
  final String messageId;
  final String chunk;

  MessageChunkEvent(this.messageId, this.chunk);

  @override
  String toString() =>
      'MessageChunkEvent(messageId: $messageId, chunk length: ${chunk.length})';
}

class MessageEndEvent extends ChatEvent {
  final String messageId;
  final Message message;

  MessageEndEvent(this.messageId, this.message);

  @override
  String toString() => 'MessageEndEvent(messageId: $messageId)';
}

class TypingIndicatorEvent extends ChatEvent {
  final bool isTyping;

  TypingIndicatorEvent(this.isTyping);

  @override
  String toString() => 'TypingIndicatorEvent(isTyping: $isTyping)';
}

class ThoughtEvent extends ChatEvent {
  final String content;

  ThoughtEvent(this.content);

  @override
  String toString() =>
      'ThoughtEvent(content length: ${content.length})';
}

class ChatErrorEvent extends ChatEvent {
  final Object error;
  final StackTrace? stackTrace;

  ChatErrorEvent(this.error, [this.stackTrace]);

  @override
  String toString() => 'ChatErrorEvent(error: $error)';
}
