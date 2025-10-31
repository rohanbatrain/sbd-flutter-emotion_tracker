import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/ai/voice_service.dart';
import 'package:emotion_tracker/utils/ai_animations.dart';
import 'dart:math' as math;

/// Voice Input Widget - provides voice recording interface for AI chat
class VoiceInputWidget extends ConsumerStatefulWidget {
  final bool enabled;
  final Function(String audioData) onVoiceMessage;
  final VoidCallback? onTextFallback;
  final String? hintText;

  const VoiceInputWidget({
    super.key,
    required this.enabled,
    required this.onVoiceMessage,
    this.onTextFallback,
    this.hintText,
  });

  @override
  ConsumerState<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends ConsumerState<VoiceInputWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for recording button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Wave animation for audio level visualization
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final recordingState = ref.watch(voiceRecordingStateProvider);
    
    // Update animations based on recording state
    _updateAnimations(recordingState);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording status and controls
          _buildRecordingStatus(theme, recordingState),
          
          const SizedBox(height: 16),
          
          // Main voice input area
          _buildVoiceInputArea(theme, recordingState),
          
          // Error message if any
          if (recordingState.hasError)
            _buildErrorMessage(theme, recordingState),
        ],
      ),
    );
  }

  /// Update animations based on recording state
  void _updateAnimations(VoiceRecordingState recordingState) {
    if (recordingState.isRecording) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
      
      // Update wave animation based on amplitude
      final amplitude = recordingState.amplitude ?? 0.0;
      _waveController.animateTo(amplitude);
    } else {
      _pulseController.stop();
      _pulseController.reset();
      _waveController.animateTo(0.0);
    }
  }

  /// Build recording status indicator
  Widget _buildRecordingStatus(ThemeData theme, VoiceRecordingState recordingState) {
    if (!recordingState.isRecording && !recordingState.isProcessing) {
      return const SizedBox.shrink();
    }

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (recordingState.isRecording) {
      final duration = recordingState.duration ?? Duration.zero;
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      statusText = 'Recording ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      statusColor = Colors.red;
      statusIcon = Icons.fiber_manual_record;
    } else if (recordingState.isProcessing) {
      statusText = 'Processing audio...';
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (recordingState.isProcessing) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build main voice input area
  Widget _buildVoiceInputArea(ThemeData theme, VoiceRecordingState recordingState) {
    return Row(
      children: [
        // Text fallback button
        if (widget.onTextFallback != null)
          IconButton(
            onPressed: widget.enabled ? widget.onTextFallback : null,
            icon: const Icon(Icons.keyboard),
            tooltip: 'Switch to text input',
            style: IconButton.styleFrom(
              backgroundColor: theme.scaffoldBackgroundColor,
              foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        
        const SizedBox(width: 12),
        
        // Voice input area
        Expanded(
          child: _buildVoiceRecordingArea(theme, recordingState),
        ),
        
        const SizedBox(width: 12),
        
        // Action buttons (cancel/send)
        _buildActionButtons(theme, recordingState),
      ],
    );
  }

  /// Build voice recording area with visual feedback
  Widget _buildVoiceRecordingArea(ThemeData theme, VoiceRecordingState recordingState) {
    return GestureDetector(
      onTapDown: widget.enabled ? _handleRecordingStart : null,
      onTapUp: widget.enabled ? _handleRecordingEnd : null,
      onTapCancel: widget.enabled ? _handleRecordingCancel : null,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: recordingState.isRecording 
              ? Colors.red.withOpacity(0.1)
              : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: recordingState.isRecording 
                ? Colors.red.withOpacity(0.3)
                : theme.dividerColor,
            width: recordingState.isRecording ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Audio level visualization
            if (recordingState.isRecording)
              _buildAudioLevelVisualization(theme, recordingState),
            
            // Main content
            Center(
              child: _buildRecordingContent(theme, recordingState),
            ),
          ],
        ),
      ),
    );
  }

  /// Build audio level visualization
  Widget _buildAudioLevelVisualization(ThemeData theme, VoiceRecordingState recordingState) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: AudioWavePainter(
            amplitude: _waveAnimation.value,
            color: Colors.red.withOpacity(0.3),
          ),
          size: const Size(double.infinity, 60),
        );
      },
    );
  }

  /// Build recording content (icon and text)
  Widget _buildRecordingContent(ThemeData theme, VoiceRecordingState recordingState) {
    IconData icon;
    String text;
    Color color;

    if (recordingState.status == VoiceRecordingStatus.permission_denied) {
      icon = Icons.mic_off;
      text = 'Microphone permission required';
      color = Colors.red;
    } else if (recordingState.isRecording) {
      icon = Icons.mic;
      text = 'Release to send';
      color = Colors.red;
    } else if (recordingState.isProcessing) {
      icon = Icons.hourglass_empty;
      text = 'Processing...';
      color = Colors.orange;
    } else if (!widget.enabled) {
      icon = Icons.mic_off;
      text = 'Connect to use voice';
      color = theme.disabledColor;
    } else {
      icon = Icons.mic;
      text = widget.hintText ?? 'Hold to record voice message';
      color = theme.colorScheme.onSurface.withOpacity(0.7);
    }

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: recordingState.isRecording 
                  ? FontWeight.w600 
                  : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    // Apply error shake animation
    if (recordingState.hasError) {
      // Error shake animation would be implemented here
      // content = content.animateErrorShake();
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: recordingState.isRecording ? _pulseAnimation.value : 1.0,
          child: content,
        );
      },
    );
  }

  /// Build action buttons (cancel/send)
  Widget _buildActionButtons(ThemeData theme, VoiceRecordingState recordingState) {
    if (recordingState.isCompleted) {
      // Show send button when recording is complete
      return FloatingActionButton(
        onPressed: _handleSendVoiceMessage,
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        mini: true,
        child: const Icon(Icons.send),
      );
    } else if (recordingState.isRecording) {
      // Show cancel button while recording
      return FloatingActionButton(
        onPressed: _handleRecordingCancel,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        mini: true,
        child: const Icon(Icons.close),
      );
    } else {
      // Show microphone button when idle
      return FloatingActionButton(
        onPressed: widget.enabled ? _handleMicrophoneTap : null,
        backgroundColor: widget.enabled 
            ? theme.primaryColor 
            : theme.disabledColor,
        foregroundColor: theme.colorScheme.onPrimary,
        mini: true,
        child: const Icon(Icons.mic),
      );
    }
  }

  /// Build error message
  Widget _buildErrorMessage(ThemeData theme, VoiceRecordingState recordingState) {
    if (!recordingState.hasError || recordingState.errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              recordingState.errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _handleRetryRecording,
            child: const Icon(
              Icons.refresh,
              color: Colors.red,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Handle recording start (tap down)
  void _handleRecordingStart(TapDownDetails details) {
    if (!widget.enabled) return;
    
    // AIHaptics.recordingStart();
    // AISounds.recordingStart();
    
    final recordingNotifier = ref.read(voiceRecordingStateProvider.notifier);
    recordingNotifier.startRecording();
  }

  /// Handle recording end (tap up)
  void _handleRecordingEnd(TapUpDetails details) {
    if (!widget.enabled) return;
    
    final recordingState = ref.read(voiceRecordingStateProvider);
    if (recordingState.isRecording) {
      // AIHaptics.recordingStop();
      // AISounds.recordingStop();
      
      final recordingNotifier = ref.read(voiceRecordingStateProvider.notifier);
      recordingNotifier.stopRecording();
    }
  }

  /// Handle recording cancel (tap cancel or explicit cancel)
  void _handleRecordingCancel() {
    final recordingNotifier = ref.read(voiceRecordingStateProvider.notifier);
    recordingNotifier.cancelRecording();
  }

  /// Handle microphone button tap (alternative to hold-to-record)
  void _handleMicrophoneTap() {
    final recordingState = ref.read(voiceRecordingStateProvider);
    final recordingNotifier = ref.read(voiceRecordingStateProvider.notifier);
    
    if (recordingState.canRecord) {
      recordingNotifier.startRecording();
    } else if (recordingState.isRecording) {
      recordingNotifier.stopRecording();
    }
  }

  /// Handle sending voice message
  void _handleSendVoiceMessage() {
    final recordingState = ref.read(voiceRecordingStateProvider);
    
    if (recordingState.isCompleted && recordingState.base64Data != null) {
      AIHaptics.messageSent();
      AISounds.messageSent();
      
      widget.onVoiceMessage(recordingState.base64Data!);
      
      // Reset recording state
      final recordingNotifier = ref.read(voiceRecordingStateProvider.notifier);
      recordingNotifier.reset();
    }
  }

  /// Handle retry recording after error
  void _handleRetryRecording() {
    final recordingNotifier = ref.read(voiceRecordingStateProvider.notifier);
    recordingNotifier.reset();
  }
}

/// Custom painter for audio wave visualization
class AudioWavePainter extends CustomPainter {
  final double amplitude;
  final Color color;

  AudioWavePainter({
    required this.amplitude,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitude <= 0.0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;
    final waveHeight = size.height * 0.3 * amplitude;
    
    // Draw multiple wave bars across the width
    const barCount = 20;
    final barWidth = size.width / barCount;
    
    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      
      // Create varying heights for wave effect
      final phase = (i / barCount) * 2 * math.pi;
      final heightMultiplier = (math.sin(phase) * 0.5 + 0.5) * amplitude + 0.1;
      final barHeight = waveHeight * heightMultiplier;
      
      final rect = Rect.fromCenter(
        center: Offset(x, centerY),
        width: barWidth * 0.6,
        height: barHeight,
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(AudioWavePainter oldDelegate) {
    return oldDelegate.amplitude != amplitude || oldDelegate.color != color;
  }
}