/// Client messages sent over the WebSocket transport.
abstract class TransportClientMessage {
  Map<String, dynamic> toJson();
}

class ChatMessageTransport extends TransportClientMessage {
  final String text;
  final String? messageId;
  final String? sessionId;
  final List<String>? attachmentIds;
  final Map<String, dynamic>? metadata;

  ChatMessageTransport({
    required this.text,
    this.messageId,
    this.sessionId,
    this.attachmentIds,
    this.metadata,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'chat_message',
      'text': text,
      if (messageId != null) 'messageId': messageId,
      if (sessionId != null) 'sessionId': sessionId,
      if (attachmentIds != null) 'attachmentIds': attachmentIds,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

class EndSessionTransport extends TransportClientMessage {
  final String? sessionId;

  EndSessionTransport({this.sessionId});

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'end_session',
      if (sessionId != null) 'sessionId': sessionId,
    };
  }
}

/// Server messages received from the WebSocket transport.
class TransportServerMessage {
  final String type;
  final Map<String, dynamic> raw;

  const TransportServerMessage({
    required this.type,
    required this.raw,
  });

  factory TransportServerMessage.fromJson(Map<String, dynamic> json) {
    return TransportServerMessage(
      type: json['type'] as String? ?? 'unknown',
      raw: json,
    );
  }
}

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}
