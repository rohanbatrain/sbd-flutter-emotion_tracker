import 'package:json_annotation/json_annotation.dart';

part 'webauthn_models.g.dart';

// Exception class for WebAuthn errors
class WebAuthnException implements Exception {
  final String message;
  final int? statusCode;
  final String? flutterCode;

  const WebAuthnException(this.message, {this.statusCode, this.flutterCode});

  @override
  String toString() {
    return 'WebAuthnException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${flutterCode != null ? ' (Code: $flutterCode)' : ''}';
  }
}

// Request model for beginning WebAuthn authentication
@JsonSerializable()
class WebAuthnAuthBeginRequest {
  final String? username;
  final String? email;

  const WebAuthnAuthBeginRequest({this.username, this.email});

  factory WebAuthnAuthBeginRequest.fromJson(Map<String, dynamic> json) =>
      _$WebAuthnAuthBeginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$WebAuthnAuthBeginRequestToJson(this);
}

// Supporting models for WebAuthn public key credential options
@JsonSerializable()
class WebAuthnPublicKeyCredentialDescriptor {
  final String type;
  final String id;
  final List<String>? transports;

  const WebAuthnPublicKeyCredentialDescriptor({
    required this.type,
    required this.id,
    this.transports,
  });

  factory WebAuthnPublicKeyCredentialDescriptor.fromJson(
    Map<String, dynamic> json,
  ) => _$WebAuthnPublicKeyCredentialDescriptorFromJson(json);

  Map<String, dynamic> toJson() =>
      _$WebAuthnPublicKeyCredentialDescriptorToJson(this);
}

@JsonSerializable()
class WebAuthnPublicKeyCredentialRequestOptions {
  final String challenge;
  final int timeout;
  @JsonKey(name: 'rpId')
  final String? relyingPartyId;
  final List<WebAuthnPublicKeyCredentialDescriptor>? allowCredentials;
  final String? userVerification;

  const WebAuthnPublicKeyCredentialRequestOptions({
    required this.challenge,
    required this.timeout,
    this.relyingPartyId,
    this.allowCredentials,
    this.userVerification,
  });

  factory WebAuthnPublicKeyCredentialRequestOptions.fromJson(
    Map<String, dynamic> json,
  ) => _$WebAuthnPublicKeyCredentialRequestOptionsFromJson(json);

  Map<String, dynamic> toJson() =>
      _$WebAuthnPublicKeyCredentialRequestOptionsToJson(this);
}

// Response model for WebAuthn authentication begin
@JsonSerializable()
class WebAuthnAuthBeginResponse {
  final WebAuthnPublicKeyCredentialRequestOptions publicKey;
  final String? username;
  final String? email;

  const WebAuthnAuthBeginResponse({
    required this.publicKey,
    this.username,
    this.email,
  });

  factory WebAuthnAuthBeginResponse.fromJson(Map<String, dynamic> json) =>
      _$WebAuthnAuthBeginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WebAuthnAuthBeginResponseToJson(this);
}

// Models for WebAuthn authentication completion
@JsonSerializable()
class WebAuthnAuthenticatorAssertionResponse {
  final String clientDataJSON;
  final String authenticatorData;
  final String signature;
  final String? userHandle;

  const WebAuthnAuthenticatorAssertionResponse({
    required this.clientDataJSON,
    required this.authenticatorData,
    required this.signature,
    this.userHandle,
  });

  factory WebAuthnAuthenticatorAssertionResponse.fromJson(
    Map<String, dynamic> json,
  ) => _$WebAuthnAuthenticatorAssertionResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$WebAuthnAuthenticatorAssertionResponseToJson(this);
}

@JsonSerializable()
class WebAuthnPublicKeyCredential {
  final String id;
  final String rawId;
  final WebAuthnAuthenticatorAssertionResponse response;
  final String type;

  const WebAuthnPublicKeyCredential({
    required this.id,
    required this.rawId,
    required this.response,
    required this.type,
  });

  factory WebAuthnPublicKeyCredential.fromJson(Map<String, dynamic> json) =>
      _$WebAuthnPublicKeyCredentialFromJson(json);

  Map<String, dynamic> toJson() => _$WebAuthnPublicKeyCredentialToJson(this);
}

// Request model for completing WebAuthn authentication
@JsonSerializable()
class WebAuthnAuthCompleteRequest {
  final WebAuthnPublicKeyCredential credential;
  final String? username;
  final String? email;

  const WebAuthnAuthCompleteRequest({
    required this.credential,
    this.username,
    this.email,
  });

  factory WebAuthnAuthCompleteRequest.fromJson(Map<String, dynamic> json) =>
      _$WebAuthnAuthCompleteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$WebAuthnAuthCompleteRequestToJson(this);
}

// Model for credential information used in authentication
@JsonSerializable()
class WebAuthnCredentialUsed {
  final String id;
  final String? deviceName;
  final String? deviceType;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  const WebAuthnCredentialUsed({
    required this.id,
    this.deviceName,
    this.deviceType,
    required this.createdAt,
    this.lastUsedAt,
  });

  factory WebAuthnCredentialUsed.fromJson(Map<String, dynamic> json) =>
      _$WebAuthnCredentialUsedFromJson(json);

  Map<String, dynamic> toJson() => _$WebAuthnCredentialUsedToJson(this);
}

// Response model for completed WebAuthn authentication
@JsonSerializable()
class WebAuthnAuthCompleteResponse {
  final String accessToken;
  final String tokenType;
  final bool clientSideEncryption;
  final int issuedAt;
  final int expiresAt;
  final bool isVerified;
  final String? role;
  final String? username;
  final String? email;
  final String authenticationMethod;
  final WebAuthnCredentialUsed credentialUsed;

  const WebAuthnAuthCompleteResponse({
    required this.accessToken,
    required this.tokenType,
    required this.clientSideEncryption,
    required this.issuedAt,
    required this.expiresAt,
    required this.isVerified,
    this.role,
    this.username,
    this.email,
    required this.authenticationMethod,
    required this.credentialUsed,
  });

  factory WebAuthnAuthCompleteResponse.fromJson(Map<String, dynamic> json) =>
      _$WebAuthnAuthCompleteResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WebAuthnAuthCompleteResponseToJson(this);
}

// Additional models for registration flow (supporting models)
@JsonSerializable()
class WebAuthnPublicKeyCredentialRpEntity {
  final String id;
  final String name;

  const WebAuthnPublicKeyCredentialRpEntity({
    required this.id,
    required this.name,
  });

  factory WebAuthnPublicKeyCredentialRpEntity.fromJson(
    Map<String, dynamic> json,
  ) => _$WebAuthnPublicKeyCredentialRpEntityFromJson(json);

  Map<String, dynamic> toJson() =>
      _$WebAuthnPublicKeyCredentialRpEntityToJson(this);
}

@JsonSerializable()
class WebAuthnPublicKeyCredentialUserEntity {
  final String id;
  final String name;
  final String displayName;

  const WebAuthnPublicKeyCredentialUserEntity({
    required this.id,
    required this.name,
    required this.displayName,
  });

  factory WebAuthnPublicKeyCredentialUserEntity.fromJson(
    Map<String, dynamic> json,
  ) => _$WebAuthnPublicKeyCredentialUserEntityFromJson(json);

  Map<String, dynamic> toJson() =>
      _$WebAuthnPublicKeyCredentialUserEntityToJson(this);
}

@JsonSerializable()
class WebAuthnPublicKeyCredentialParameters {
  final String type;
  final int alg;

  const WebAuthnPublicKeyCredentialParameters({
    required this.type,
    required this.alg,
  });

  factory WebAuthnPublicKeyCredentialParameters.fromJson(
    Map<String, dynamic> json,
  ) => _$WebAuthnPublicKeyCredentialParametersFromJson(json);

  Map<String, dynamic> toJson() =>
      _$WebAuthnPublicKeyCredentialParametersToJson(this);
}

@JsonSerializable()
class WebAuthnPublicKeyCredentialCreationOptions {
  final WebAuthnPublicKeyCredentialRpEntity rp;
  final WebAuthnPublicKeyCredentialUserEntity user;
  final String challenge;
  final List<WebAuthnPublicKeyCredentialParameters> pubKeyCredParams;
  final int timeout;
  final List<WebAuthnPublicKeyCredentialDescriptor>? excludeCredentials;
  final Map<String, dynamic>? authenticatorSelection;
  final String? attestation;

  const WebAuthnPublicKeyCredentialCreationOptions({
    required this.rp,
    required this.user,
    required this.challenge,
    required this.pubKeyCredParams,
    required this.timeout,
    this.excludeCredentials,
    this.authenticatorSelection,
    this.attestation,
  });

  factory WebAuthnPublicKeyCredentialCreationOptions.fromJson(
    Map<String, dynamic> json,
  ) => _$WebAuthnPublicKeyCredentialCreationOptionsFromJson(json);

  Map<String, dynamic> toJson() =>
      _$WebAuthnPublicKeyCredentialCreationOptionsToJson(this);
}
