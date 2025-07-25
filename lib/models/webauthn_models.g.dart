// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webauthn_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebAuthnAuthBeginRequest _$WebAuthnAuthBeginRequestFromJson(
  Map<String, dynamic> json,
) => WebAuthnAuthBeginRequest(
  username: json['username'] as String?,
  email: json['email'] as String?,
);

Map<String, dynamic> _$WebAuthnAuthBeginRequestToJson(
  WebAuthnAuthBeginRequest instance,
) => <String, dynamic>{'username': instance.username, 'email': instance.email};

WebAuthnPublicKeyCredentialDescriptor
_$WebAuthnPublicKeyCredentialDescriptorFromJson(Map<String, dynamic> json) =>
    WebAuthnPublicKeyCredentialDescriptor(
      type: json['type'] as String,
      id: json['id'] as String,
      transports: (json['transports'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$WebAuthnPublicKeyCredentialDescriptorToJson(
  WebAuthnPublicKeyCredentialDescriptor instance,
) => <String, dynamic>{
  'type': instance.type,
  'id': instance.id,
  'transports': instance.transports,
};

WebAuthnPublicKeyCredentialRequestOptions
_$WebAuthnPublicKeyCredentialRequestOptionsFromJson(
  Map<String, dynamic> json,
) => WebAuthnPublicKeyCredentialRequestOptions(
  challenge: json['challenge'] as String,
  timeout: (json['timeout'] as num).toInt(),
  relyingPartyId: json['rpId'] as String?,
  allowCredentials: (json['allowCredentials'] as List<dynamic>?)
      ?.map(
        (e) => WebAuthnPublicKeyCredentialDescriptor.fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
  userVerification: json['userVerification'] as String?,
);

Map<String, dynamic> _$WebAuthnPublicKeyCredentialRequestOptionsToJson(
  WebAuthnPublicKeyCredentialRequestOptions instance,
) => <String, dynamic>{
  'challenge': instance.challenge,
  'timeout': instance.timeout,
  'rpId': instance.relyingPartyId,
  'allowCredentials': instance.allowCredentials,
  'userVerification': instance.userVerification,
};

WebAuthnAuthBeginResponse _$WebAuthnAuthBeginResponseFromJson(
  Map<String, dynamic> json,
) => WebAuthnAuthBeginResponse(
  publicKey: WebAuthnPublicKeyCredentialRequestOptions.fromJson(
    json['publicKey'] as Map<String, dynamic>,
  ),
  username: json['username'] as String?,
  email: json['email'] as String?,
);

Map<String, dynamic> _$WebAuthnAuthBeginResponseToJson(
  WebAuthnAuthBeginResponse instance,
) => <String, dynamic>{
  'publicKey': instance.publicKey,
  'username': instance.username,
  'email': instance.email,
};

WebAuthnAuthenticatorAssertionResponse
_$WebAuthnAuthenticatorAssertionResponseFromJson(Map<String, dynamic> json) =>
    WebAuthnAuthenticatorAssertionResponse(
      clientDataJSON: json['clientDataJSON'] as String,
      authenticatorData: json['authenticatorData'] as String,
      signature: json['signature'] as String,
      userHandle: json['userHandle'] as String?,
    );

Map<String, dynamic> _$WebAuthnAuthenticatorAssertionResponseToJson(
  WebAuthnAuthenticatorAssertionResponse instance,
) => <String, dynamic>{
  'clientDataJSON': instance.clientDataJSON,
  'authenticatorData': instance.authenticatorData,
  'signature': instance.signature,
  'userHandle': instance.userHandle,
};

WebAuthnPublicKeyCredential _$WebAuthnPublicKeyCredentialFromJson(
  Map<String, dynamic> json,
) => WebAuthnPublicKeyCredential(
  id: json['id'] as String,
  rawId: json['rawId'] as String,
  response: WebAuthnAuthenticatorAssertionResponse.fromJson(
    json['response'] as Map<String, dynamic>,
  ),
  type: json['type'] as String,
);

Map<String, dynamic> _$WebAuthnPublicKeyCredentialToJson(
  WebAuthnPublicKeyCredential instance,
) => <String, dynamic>{
  'id': instance.id,
  'rawId': instance.rawId,
  'response': instance.response,
  'type': instance.type,
};

WebAuthnAuthCompleteRequest _$WebAuthnAuthCompleteRequestFromJson(
  Map<String, dynamic> json,
) => WebAuthnAuthCompleteRequest(
  credential: WebAuthnPublicKeyCredential.fromJson(
    json['credential'] as Map<String, dynamic>,
  ),
  username: json['username'] as String?,
  email: json['email'] as String?,
);

Map<String, dynamic> _$WebAuthnAuthCompleteRequestToJson(
  WebAuthnAuthCompleteRequest instance,
) => <String, dynamic>{
  'credential': instance.credential,
  'username': instance.username,
  'email': instance.email,
};

WebAuthnCredentialUsed _$WebAuthnCredentialUsedFromJson(
  Map<String, dynamic> json,
) => WebAuthnCredentialUsed(
  id: json['id'] as String,
  deviceName: json['deviceName'] as String?,
  deviceType: json['deviceType'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  lastUsedAt: json['lastUsedAt'] == null
      ? null
      : DateTime.parse(json['lastUsedAt'] as String),
);

Map<String, dynamic> _$WebAuthnCredentialUsedToJson(
  WebAuthnCredentialUsed instance,
) => <String, dynamic>{
  'id': instance.id,
  'deviceName': instance.deviceName,
  'deviceType': instance.deviceType,
  'createdAt': instance.createdAt.toIso8601String(),
  'lastUsedAt': instance.lastUsedAt?.toIso8601String(),
};

WebAuthnAuthCompleteResponse _$WebAuthnAuthCompleteResponseFromJson(
  Map<String, dynamic> json,
) => WebAuthnAuthCompleteResponse(
  accessToken: json['accessToken'] as String,
  tokenType: json['tokenType'] as String,
  clientSideEncryption: json['clientSideEncryption'] as bool,
  issuedAt: (json['issuedAt'] as num).toInt(),
  expiresAt: (json['expiresAt'] as num).toInt(),
  isVerified: json['isVerified'] as bool,
  role: json['role'] as String?,
  username: json['username'] as String?,
  email: json['email'] as String?,
  authenticationMethod: json['authenticationMethod'] as String,
  credentialUsed: WebAuthnCredentialUsed.fromJson(
    json['credentialUsed'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$WebAuthnAuthCompleteResponseToJson(
  WebAuthnAuthCompleteResponse instance,
) => <String, dynamic>{
  'accessToken': instance.accessToken,
  'tokenType': instance.tokenType,
  'clientSideEncryption': instance.clientSideEncryption,
  'issuedAt': instance.issuedAt,
  'expiresAt': instance.expiresAt,
  'isVerified': instance.isVerified,
  'role': instance.role,
  'username': instance.username,
  'email': instance.email,
  'authenticationMethod': instance.authenticationMethod,
  'credentialUsed': instance.credentialUsed,
};

WebAuthnPublicKeyCredentialRpEntity
_$WebAuthnPublicKeyCredentialRpEntityFromJson(Map<String, dynamic> json) =>
    WebAuthnPublicKeyCredentialRpEntity(
      id: json['id'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$WebAuthnPublicKeyCredentialRpEntityToJson(
  WebAuthnPublicKeyCredentialRpEntity instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

WebAuthnPublicKeyCredentialUserEntity
_$WebAuthnPublicKeyCredentialUserEntityFromJson(Map<String, dynamic> json) =>
    WebAuthnPublicKeyCredentialUserEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String,
    );

Map<String, dynamic> _$WebAuthnPublicKeyCredentialUserEntityToJson(
  WebAuthnPublicKeyCredentialUserEntity instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'displayName': instance.displayName,
};

WebAuthnPublicKeyCredentialParameters
_$WebAuthnPublicKeyCredentialParametersFromJson(Map<String, dynamic> json) =>
    WebAuthnPublicKeyCredentialParameters(
      type: json['type'] as String,
      alg: (json['alg'] as num).toInt(),
    );

Map<String, dynamic> _$WebAuthnPublicKeyCredentialParametersToJson(
  WebAuthnPublicKeyCredentialParameters instance,
) => <String, dynamic>{'type': instance.type, 'alg': instance.alg};

WebAuthnPublicKeyCredentialCreationOptions
_$WebAuthnPublicKeyCredentialCreationOptionsFromJson(
  Map<String, dynamic> json,
) => WebAuthnPublicKeyCredentialCreationOptions(
  rp: WebAuthnPublicKeyCredentialRpEntity.fromJson(
    json['rp'] as Map<String, dynamic>,
  ),
  user: WebAuthnPublicKeyCredentialUserEntity.fromJson(
    json['user'] as Map<String, dynamic>,
  ),
  challenge: json['challenge'] as String,
  pubKeyCredParams: (json['pubKeyCredParams'] as List<dynamic>)
      .map(
        (e) => WebAuthnPublicKeyCredentialParameters.fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
  timeout: (json['timeout'] as num).toInt(),
  excludeCredentials: (json['excludeCredentials'] as List<dynamic>?)
      ?.map(
        (e) => WebAuthnPublicKeyCredentialDescriptor.fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
  authenticatorSelection:
      json['authenticatorSelection'] as Map<String, dynamic>?,
  attestation: json['attestation'] as String?,
);

Map<String, dynamic> _$WebAuthnPublicKeyCredentialCreationOptionsToJson(
  WebAuthnPublicKeyCredentialCreationOptions instance,
) => <String, dynamic>{
  'rp': instance.rp,
  'user': instance.user,
  'challenge': instance.challenge,
  'pubKeyCredParams': instance.pubKeyCredParams,
  'timeout': instance.timeout,
  'excludeCredentials': instance.excludeCredentials,
  'authenticatorSelection': instance.authenticatorSelection,
  'attestation': instance.attestation,
};
