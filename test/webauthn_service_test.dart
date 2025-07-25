import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/webauthn_service.dart';
import 'package:emotion_tracker/models/webauthn_models.dart';
import 'package:emotion_tracker/core/error_constants.dart';
import 'package:emotion_tracker/providers/api_token_service.dart'
    show UnauthorizedException, RateLimitException;

void main() {
  late ProviderContainer container;
  late WebAuthnService service;

  setUp(() {
    container = ProviderContainer();
    service = container.read(webAuthnServiceProvider);
  });

  tearDown(() {
    container.dispose();
  });

  group('WebAuthn Service', () {
    group('Error Handling', () {
      test(
        'should format WebAuthnException with status code and flutter code',
        () {
          final exception = WebAuthnException(
            'Test error',
            statusCode: 404,
            flutterCode: 'CREDENTIAL_NOT_FOUND',
          );
          expect(exception.message, 'Test error');
          expect(exception.statusCode, 404);
          expect(exception.flutterCode, 'CREDENTIAL_NOT_FOUND');
          expect(
            exception.toString(),
            'WebAuthnException: Test error (Status: 404) (Code: CREDENTIAL_NOT_FOUND)',
          );
        },
      );

      test('should format WebAuthnException without status code', () {
        final exception = WebAuthnException('Test error');
        expect(exception.message, 'Test error');
        expect(exception.statusCode, isNull);
        expect(exception.flutterCode, isNull);
        expect(exception.toString(), 'WebAuthnException: Test error');
      });

      test('should format UnauthorizedException', () {
        final exception = UnauthorizedException('Session expired');
        expect(exception.toString(), 'Session expired');
      });

      test('should format RateLimitException', () {
        final exception = RateLimitException('Too many requests');
        expect(exception.toString(), 'Too many requests');
      });
    });

    group('Constants Validation', () {
      test('should have all required error message constants', () {
        expect(ErrorConstants.sessionExpired, isNotEmpty);
        expect(ErrorConstants.networkError, isNotEmpty);
        expect(ErrorConstants.timeout, isNotEmpty);
        expect(ErrorConstants.unknown, isNotEmpty);
        expect(ErrorConstants.passkeyNotSupported, isNotEmpty);
        expect(ErrorConstants.challengeExpired, isNotEmpty);
        expect(ErrorConstants.userCancelled, isNotEmpty);
        expect(ErrorConstants.noCredentials, isNotEmpty);
        expect(ErrorConstants.credentialNotFound, isNotEmpty);
        expect(ErrorConstants.authenticatorError, isNotEmpty);
        expect(ErrorConstants.registrationFailed, isNotEmpty);
        expect(ErrorConstants.authenticationFailed, isNotEmpty);
      });
    });

    group('Registration Methods', () {
      test('should have beginRegistration method available', () {
        expect(service.beginRegistration, isNotNull);
      });

      test('should have completeRegistration method available', () {
        expect(service.completeRegistration, isNotNull);
      });
    });

    group('Credential Management Methods', () {
      test('should have listCredentials method available', () {
        expect(service.listCredentials, isNotNull);
      });

      test('should have deleteCredential method available', () {
        expect(service.deleteCredential, isNotNull);
      });

      test('should reject empty credential ID for deletion', () async {
        try {
          await service.deleteCredential('');
          fail('Should have thrown WebAuthnException');
        } catch (e) {
          expect(e, isA<WebAuthnException>());
          expect((e as WebAuthnException).message, contains('cannot be empty'));
        }
      });

      test(
        'should reject whitespace-only credential ID for deletion',
        () async {
          try {
            await service.deleteCredential('   ');
            fail('Should have thrown WebAuthnException');
          } catch (e) {
            expect(e, isA<WebAuthnException>());
            expect(
              (e as WebAuthnException).message,
              contains('cannot be empty'),
            );
          }
        },
      );
    });

    group('Authentication Methods', () {
      test('should have beginAuthentication method available', () {
        expect(service.beginAuthentication, isNotNull);
      });

      test('should have completeAuthentication method available', () {
        expect(service.completeAuthentication, isNotNull);
      });
    });

    group('Device Support', () {
      test('should have isWebAuthnSupported method available', () {
        expect(service.isWebAuthnSupported, isNotNull);
      });
    });
  });
}
