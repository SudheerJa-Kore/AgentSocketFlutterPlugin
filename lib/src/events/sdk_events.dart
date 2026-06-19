/// SDK-level events
library;

/// Identifies the exact stage/operation where an SDK error occurred.
///
/// Lets host apps pinpoint failures (auth bootstrap vs. socket vs. send, etc.)
/// instead of receiving an undifferentiated error.
enum SDKErrorCode {
  /// Acquiring the initial SDK session token failed (`POST /api/v1/sdk/init`).
  tokenInit,

  /// Refreshing the SDK session token failed (`POST /api/v1/sdk/refresh`).
  tokenRefresh,

  /// Obtaining the WebSocket ticket failed (`POST /api/v1/sdk/ws-ticket`).
  wsTicket,

  /// The WebSocket connection failed to open or errored.
  socketConnection,

  /// The socket opened but the server never sent `session_start` in time.
  sessionStartTimeout,

  /// Sending a message failed (e.g. not connected).
  sendFailed,

  /// Fetching persisted history failed.
  historyFetch,

  /// Any error that does not map to a specific stage.
  unknown,
}

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

  /// The stage where the error occurred.
  final SDKErrorCode code;

  SDKErrorEvent(
    this.error, {
    this.stackTrace,
    this.code = SDKErrorCode.unknown,
  });

  @override
  String toString() => 'SDKErrorEvent(code: ${code.name}, error: $error)';
}

class SDKIdleTimeoutEvent extends SDKEvent {
  final Duration timeout;

  SDKIdleTimeoutEvent(this.timeout);

  @override
  String toString() => 'SDKIdleTimeoutEvent(timeout: $timeout)';
}
