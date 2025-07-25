import 'package:flutter_test/flutter_test.dart';
import 'package:emotion_tracker/core/global_error_handler.dart';
import 'package:emotion_tracker/core/error_constants.dart';
import 'package:emotion_tracker/core/error_state.dart';
import 'package:emotion_tracker/models/webauthn_models.dart';

void main() {
  group('WebAuthn Error Integration', () {
    test('should process WebAuthnException with flutter code correctly', () {
      final webauthnError = WebAuthnException(
        'User cancelled authentication',
        statusCode: 400,
        flutterCode: 'USER_CANCELLED',
      );

      final errorState = GlobalErrorHandler.processError(webauthnError);

      expect(errorState.type, ErrorType.webauthn);
      expect(errorState.title, ErrorConstants.webauthnTitle);
      expect(errorState.message, ErrorConstants.userCancelled);
      expect(errorState.metadata?['originalError'], webauthnError);
      expect(errorState.metadata?['statusCode'], 400);
      expect(errorState.metadata?['flutterCode'], 'USER_CANCELLED');
    });

    test('should process WebAuthnException with status code mapping', () {
      final webauthnError = WebAuthnException(
        'Credential not found',
        statusCode: 404,
      );

      final errorState = GlobalErrorHandler.processError(webauthnError);

      expect(errorState.type, ErrorType.webauthn);
      expect(errorState.title, ErrorConstants.webauthnTitle);
      expect(errorState.message, ErrorConstants.credentialNotFound);
      expect(errorState.metadata?['originalError'], webauthnError);
      expect(errorState.metadata?['statusCode'], 404);
    });

    test('should process WebAuthnException with keyword matching', () {
      final webauthnError = WebAuthnException(
        'Authentication was cancelled by user',
      );

      final errorState = GlobalErrorHandler.processError(webauthnError);

      expect(errorState.type, ErrorType.webauthn);
      expect(errorState.title, ErrorConstants.webauthnTitle);
      expect(errorState.message, ErrorConstants.userCancelled);
      expect(errorState.metadata?['originalError'], webauthnError);
    });

    test('should handle WebAuthn errors as non-retryable', () {
      final webauthnError = WebAuthnException('Test error');
      final errorState = GlobalErrorHandler.processError(webauthnError);

      expect(GlobalErrorHandler.isRetryable(errorState), false);
    });

    test('should provide appropriate retry delay for WebAuthn errors', () {
      final webauthnError = WebAuthnException('Test error');
      final errorState = GlobalErrorHandler.processError(webauthnError);

      final delay = GlobalErrorHandler.getRetryDelay(errorState, 1);
      expect(delay, ErrorConstants.retryDelay);
    });

    test('should fallback to original message when no mapping found', () {
      final webauthnError = WebAuthnException('Custom error message');
      final errorState = GlobalErrorHandler.processError(webauthnError);

      expect(errorState.type, ErrorType.webauthn);
      expect(errorState.title, ErrorConstants.webauthnTitle);
      expect(errorState.message, 'Custom error message');
    });

    test(
      'should fallback to generic authentication failed for empty message',
      () {
        final webauthnError = WebAuthnException('');
        final errorState = GlobalErrorHandler.processError(webauthnError);

        expect(errorState.type, ErrorType.webauthn);
        expect(errorState.title, ErrorConstants.webauthnTitle);
        expect(errorState.message, ErrorConstants.authenticationFailed);
      },
    );
  });
}
