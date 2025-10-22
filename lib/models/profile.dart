class Profile {
  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;

  // Security-related fields for multi-account support
  final String? accessToken;
  final String? refreshToken;
  final int? expiresAtMs; // epoch ms
  final int? lastRefreshMs; // epoch ms
  final int createdAtMs; // epoch ms

  Profile({
    required this.id,
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.accessToken,
    this.refreshToken,
    this.expiresAtMs,
    this.lastRefreshMs,
    int? createdAtMs,
  }) : createdAtMs = createdAtMs ?? DateTime.now().millisecondsSinceEpoch;

  Profile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? accessToken,
    String? refreshToken,
    int? expiresAtMs,
    int? lastRefreshMs,
    int? createdAtMs,
  }) {
    return Profile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
      lastRefreshMs: lastRefreshMs ?? this.lastRefreshMs,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'email': email,
    'avatar_url': avatarUrl,
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at_ms': expiresAtMs,
    'last_refresh_ms': lastRefreshMs,
    'created_at_ms': createdAtMs,
  };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    displayName: json['display_name'] as String,
    email: json['email'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    accessToken: json['access_token'] as String?,
    refreshToken: json['refresh_token'] as String?,
    expiresAtMs: json['expires_at_ms'] is int
        ? json['expires_at_ms'] as int
        : (json['expires_at_ms'] != null
              ? int.tryParse(json['expires_at_ms'].toString())
              : null),
    lastRefreshMs: json['last_refresh_ms'] is int
        ? json['last_refresh_ms'] as int
        : (json['last_refresh_ms'] != null
              ? int.tryParse(json['last_refresh_ms'].toString())
              : null),
    createdAtMs: json['created_at_ms'] is int
        ? json['created_at_ms'] as int
        : (json['created_at_ms'] != null
              ? int.tryParse(json['created_at_ms'].toString())
              : DateTime.now().millisecondsSinceEpoch),
  );

  bool isExpired({int marginSeconds = 0}) {
    if (expiresAtMs == null) return false;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return nowMs + (marginSeconds * 1000) >= expiresAtMs!;
  }

  @override
  String toString() =>
      'Profile(id: $id, displayName: $displayName, email: $email)';
}
