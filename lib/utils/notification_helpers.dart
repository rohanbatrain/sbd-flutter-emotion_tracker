String renderFromForNotification(Map<String, dynamic>? notificationData) {
  final data = notificationData ?? {};

  String? fromUsername;
  try {
    fromUsername = data['from_username'] as String?;
    if (fromUsername != null && fromUsername.trim().isNotEmpty)
      return fromUsername;

    fromUsername = data['requester_username'] as String?;
    if (fromUsername != null && fromUsername.trim().isNotEmpty)
      return fromUsername;

    fromUsername = data['approver_username'] as String?;
    if (fromUsername != null && fromUsername.trim().isNotEmpty)
      return fromUsername;

    fromUsername = data['approved_by_username'] as String?;
    if (fromUsername != null && fromUsername.trim().isNotEmpty)
      return fromUsername;

    // Try common nested shapes
    if (data['requester'] is Map) {
      final req = data['requester'] as Map;
      final name = (req['username'] ?? req['user_name'] ?? req['email'])
          ?.toString();
      if (name != null && name.trim().isNotEmpty) return name;
    }

    if (data['from_user_id'] is String &&
        (data['from_user_id'] as String).isNotEmpty) {
      return data['from_user_id'] as String;
    }
  } catch (_) {
    // ignore and fallback
  }
  return 'System';
}
