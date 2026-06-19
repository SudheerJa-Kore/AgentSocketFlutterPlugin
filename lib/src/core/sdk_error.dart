import '../events/sdk_events.dart';

/// Internal exception that tags an underlying error with the [SDKErrorCode]
/// stage where it occurred.
///
/// Thrown deep in the SDK (token, ws-ticket, socket, etc.) and unwrapped by
/// [AgentSDK] into a coded [SDKErrorEvent] so host apps can pinpoint failures.
class SdkStageException implements Exception {
  final SDKErrorCode code;
  final Object cause;
  final StackTrace? stackTrace;

  SdkStageException(this.code, this.cause, [this.stackTrace]);

  @override
  String toString() => 'SdkStageException(${code.name}): $cause';
}
