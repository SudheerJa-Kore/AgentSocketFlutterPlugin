/// SDK-level events
library;

abstract class SDKEvent {}

class SDKConnectedEvent extends SDKEvent {
  final String sessionId;

  SDKConnectedEvent(this.sessionId);

  @override
  String toString() => 'SDKConnectedEvent(sessionId: $sessionId)';
}

class SDKDisconnectedEvent extends SDKEvent {
  final String? reason;

  SDKDisconnectedEvent({this.reason});

  @override
  String toString() => 'SDKDisconnectedEvent(reason: $reason)';
}

class SDKReconnectingEvent extends SDKEvent {
  final int attempt;
  final int maxAttempts;

  SDKReconnectingEvent(this.attempt, this.maxAttempts);

  @override
  String toString() =>
      'SDKReconnectingEvent(attempt: $attempt/$maxAttempts)';
}

class SDKErrorEvent extends SDKEvent {
  final Object error;
  final StackTrace? stackTrace;

  SDKErrorEvent(this.error, [this.stackTrace]);

  @override
  String toString() => 'SDKErrorEvent(error: $error)';
}

class SDKIdleTimeoutEvent extends SDKEvent {
  final Duration timeout;

  SDKIdleTimeoutEvent(this.timeout);

  @override
  String toString() => 'SDKIdleTimeoutEvent(timeout: $timeout)';
}
