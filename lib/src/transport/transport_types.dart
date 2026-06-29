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
  final Map<String, dynamic>? customData;

  ChatMessageTransport({
    required this.text,
    this.messageId,
    this.sessionId,
    this.attachmentIds,
    this.metadata,
    this.customData,
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
      if (customData != null && customData!.isNotEmpty) 'customData': customData,
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

class ActionSubmitTransport extends TransportClientMessage {
  final String actionId;
  final String? value;
  final Map<String, String>? formData;
  final String? renderId;

  ActionSubmitTransport({
    required this.actionId,
    this.value,
    this.formData,
    this.renderId,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'action_submit',
      'actionId': actionId,
      if (value != null) 'value': value,
      if (formData != null) 'formData': formData,
      if (renderId != null) 'renderId': renderId,
    };
  }
}

class FeedbackSubmitTransport extends TransportClientMessage {
  final String messageId;
  final String ratingType;
  final int ratingValue;
  final String? feedbackText;
  final String? actionRenderId;

  FeedbackSubmitTransport({
    required this.messageId,
    required this.ratingType,
    required this.ratingValue,
    this.feedbackText,
    this.actionRenderId,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'feedback.submit',
      'messageId': messageId,
      'ratingType': ratingType,
      'ratingValue': ratingValue,
      if (feedbackText != null) 'feedbackText': feedbackText,
      if (actionRenderId != null) 'actionRenderId': actionRenderId,
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
