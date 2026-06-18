/// Resolved SDK session scope returned by the runtime token APIs.
class SDKSessionScope {
  final String tenantId;
  final String projectId;
  final String channelId;
  final String? deploymentId;
  final List<String> permissions;
  final bool showActivityUpdates;

  const SDKSessionScope({
    required this.tenantId,
    required this.projectId,
    required this.channelId,
    this.deploymentId,
    required this.permissions,
    required this.showActivityUpdates,
  });
}
