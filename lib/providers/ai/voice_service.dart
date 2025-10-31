import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

// Voice Service Provider - follows existing provider patterns
final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService(ref);
});

// Voice Recording State Provider
final voiceRecordingStateProvider = StateNotifierProvider<VoiceRecordingStateNotifier, VoiceRecordingState>((ref) {
  final voiceService = ref.watch(voiceServiceProvider);
  return VoiceRecordingStateNotifier(voiceService);
});

// Voice Playback State Provider
final voicePlaybackStateProvider = StateNotifierProvider<VoicePlaybackStateNotifier, VoicePlaybackState>((ref) {
  final voiceService = ref.watch(voiceServiceProvider);
  return VoicePlaybackStateNotifier(voiceService);
});

/// Voice recording states
enum VoiceRecordingStatus {
  idle,
  requesting_permission,
  permission_denied,
  recording,
  processing,
  completed,
  error,
}

/// Voice playback states
enum VoicePlaybackStatus {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

/// Voice recording state model
class VoiceRecordingState {
  final VoiceRecordingStatus status;
  final Duration? duration;
  final double? amplitude;
  final String? filePath;
  final String? base64Data;
  final String? errorMessage;

  const VoiceRecordingState({
    this.status = VoiceRecordingStatus.idle,
    this.duration,
    this.amplitude,
    this.filePath,
    this.base64Data,
    this.errorMessage,
  });

  VoiceRecordingState copyWith({
    VoiceRecordingStatus? status,
    Duration? duration,
    double? amplitude,
    String? filePath,
    String? base64Data,
    String? errorMessage,
  }) {
    return VoiceRecordingState(
      status: status ?? this.status,
      duration: duration ?? this.duration,
      amplitude: amplitude ?? this.amplitude,
      filePath: filePath ?? this.filePath,
      base64Data: base64Data ?? this.base64Data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isRecording => status == VoiceRecordingStatus.recording;
  bool get isProcessing => status == VoiceRecordingStatus.processing;
  bool get hasError => status == VoiceRecordingStatus.error;
  bool get isCompleted => status == VoiceRecordingStatus.completed;
  bool get canRecord => status == VoiceRecordingStatus.idle;
}

/// Voice playback state model
class VoicePlaybackState {
  final VoicePlaybackStatus status;
  final Duration? duration;
  final Duration? position;
  final String? currentMessageId;
  final String? errorMessage;

  const VoicePlaybackState({
    this.status = VoicePlaybackStatus.idle,
    this.duration,
    this.position,
    this.currentMessageId,
    this.errorMessage,
  });

  VoicePlaybackState copyWith({
    VoicePlaybackStatus? status,
    Duration? duration,
    Duration? position,
    String? currentMessageId,
    String? errorMessage,
  }) {
    return VoicePlaybackState(
      status: status ?? this.status,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      currentMessageId: currentMessageId ?? this.currentMessageId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isPlaying => status == VoicePlaybackStatus.playing;
  bool get isPaused => status == VoicePlaybackStatus.paused;
  bool get isLoading => status == VoicePlaybackStatus.loading;
  bool get hasError => status == VoicePlaybackStatus.error;
  bool get isIdle => status == VoicePlaybackStatus.idle;
}

/// Voice Service - handles audio recording and playback for AI chat
class VoiceService {
  final Ref _ref;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  // Recording state
  Timer? _recordingTimer;
  Timer? _amplitudeTimer;
  String? _currentRecordingPath;
  
  // Playback state
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  VoiceService(this._ref) {
    _initializeAudioPlayer();
  }

  /// Initialize audio player with event listeners
  void _initializeAudioPlayer() {
    // Listen to player state changes
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      // This will be handled by the state notifier
    });
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      
      switch (status) {
        case PermissionStatus.granted:
          return true;
        case PermissionStatus.denied:
        case PermissionStatus.restricted:
        case PermissionStatus.limited:
        case PermissionStatus.permanentlyDenied:
          return false;
        default:
          return false;
      }
    } catch (e) {
      print('[VoiceService] Error requesting microphone permission: $e');
      return false;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      print('[VoiceService] Error checking microphone permission: $e');
      return false;
    }
  }

  /// Start voice recording
  Future<String?> startRecording() async {
    try {
      // Check if already recording
      if (await _recorder.isRecording()) {
        print('[VoiceService] Already recording');
        return null;
      }

      // Get temporary directory for recording
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'voice_recording_$timestamp.m4a';
      final filePath = '${tempDir.path}/$fileName';
      
      _currentRecordingPath = filePath;

      // Configure recording settings
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc, // AAC-LC for good compression and compatibility
        bitRate: 128000, // 128 kbps for good quality
        sampleRate: 44100, // Standard sample rate
        numChannels: 1, // Mono recording
      );

      // Start recording
      await _recorder.start(config, path: filePath);
      
      print('[VoiceService] Started recording to: $filePath');
      return filePath;
    } catch (e) {
      print('[VoiceService] Error starting recording: $e');
      _currentRecordingPath = null;
      return null;
    }
  }

  /// Stop voice recording and return file path
  Future<String?> stopRecording() async {
    try {
      if (!await _recorder.isRecording()) {
        print('[VoiceService] Not currently recording');
        return null;
      }

      final path = await _recorder.stop();
      print('[VoiceService] Recording stopped, file saved to: $path');
      
      return path;
    } catch (e) {
      print('[VoiceService] Error stopping recording: $e');
      return null;
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      
      // Clean up the recording file if it exists
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          print('[VoiceService] Deleted cancelled recording: $_currentRecordingPath');
        }
        _currentRecordingPath = null;
      }
    } catch (e) {
      print('[VoiceService] Error cancelling recording: $e');
    }
  }

  /// Get current recording amplitude (for visual feedback)
  Future<double> getAmplitude() async {
    try {
      if (await _recorder.isRecording()) {
        final amplitude = await _recorder.getAmplitude();
        // Normalize amplitude to 0.0 - 1.0 range
        // The amplitude.current is typically in dB, convert to linear scale
        final normalizedAmplitude = (amplitude.current + 60) / 60; // Assuming -60dB to 0dB range
        return normalizedAmplitude.clamp(0.0, 1.0);
      }
      return 0.0;
    } catch (e) {
      print('[VoiceService] Error getting amplitude: $e');
      return 0.0;
    }
  }

  /// Convert audio file to base64 for API transmission with optimization
  /// Requirement 8.3: Optimize voice processing and audio file management
  Future<String?> convertToBase64(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('[VoiceService] Audio file does not exist: $filePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      
      // Optimize audio file size if too large (>1MB)
      if (bytes.length > 1024 * 1024) {
        print('[VoiceService] Audio file is large (${bytes.length} bytes), consider compression');
        // Note: In a real implementation, you might want to compress the audio here
        // For now, we'll proceed with the original file but log the size
      }
      
      final base64String = base64Encode(bytes);
      
      print('[VoiceService] Converted audio to base64, size: ${bytes.length} bytes');
      return base64String;
    } catch (e) {
      print('[VoiceService] Error converting audio to base64: $e');
      return null;
    }
  }

  /// Play audio from base64 data (TTS responses) with caching
  /// Requirement 8.3: Optimize voice processing and audio file management
  Future<bool> playAudioFromBase64(String base64Data, String messageId) async {
    try {
      // Check if audio file already exists in cache
      final tempDir = await getTemporaryDirectory();
      final cachedFileName = 'tts_audio_${messageId}.m4a';
      final cachedFilePath = '${tempDir.path}/$cachedFileName';
      final cachedFile = File(cachedFilePath);
      
      String filePath;
      
      if (await cachedFile.exists()) {
        // Use cached file for faster playback
        filePath = cachedFilePath;
        print('[VoiceService] Using cached TTS audio for message: $messageId');
      } else {
        // Decode base64 to bytes
        final bytes = base64Decode(base64Data);
        
        // Create cached file for future use
        await cachedFile.writeAsBytes(bytes);
        filePath = cachedFilePath;
        
        print('[VoiceService] Cached TTS audio for message: $messageId (${bytes.length} bytes)');
      }
      
      // Play the audio file
      await _player.play(DeviceFileSource(filePath));
      
      print('[VoiceService] Started playing TTS audio for message: $messageId');
      return true;
    } catch (e) {
      print('[VoiceService] Error playing audio from base64: $e');
      return false;
    }
  }

  /// Play audio from file path
  Future<bool> playAudioFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('[VoiceService] Audio file does not exist: $filePath');
        return false;
      }

      await _player.play(DeviceFileSource(filePath));
      print('[VoiceService] Started playing audio from file: $filePath');
      return true;
    } catch (e) {
      print('[VoiceService] Error playing audio from file: $e');
      return false;
    }
  }

  /// Pause audio playback
  Future<void> pausePlayback() async {
    try {
      await _player.pause();
      print('[VoiceService] Audio playback paused');
    } catch (e) {
      print('[VoiceService] Error pausing playback: $e');
    }
  }

  /// Resume audio playback
  Future<void> resumePlayback() async {
    try {
      await _player.resume();
      print('[VoiceService] Audio playback resumed');
    } catch (e) {
      print('[VoiceService] Error resuming playback: $e');
    }
  }

  /// Stop audio playback
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      print('[VoiceService] Audio playback stopped');
    } catch (e) {
      print('[VoiceService] Error stopping playback: $e');
    }
  }

  /// Seek to position in audio
  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
      print('[VoiceService] Seeked to position: ${position.inSeconds}s');
    } catch (e) {
      print('[VoiceService] Error seeking to position: $e');
    }
  }

  /// Get current playback position
  Future<Duration?> getCurrentPosition() async {
    try {
      return await _player.getCurrentPosition();
    } catch (e) {
      print('[VoiceService] Error getting current position: $e');
      return null;
    }
  }

  /// Get audio duration
  Future<Duration?> getDuration() async {
    try {
      return await _player.getDuration();
    } catch (e) {
      print('[VoiceService] Error getting duration: $e');
      return null;
    }
  }

  /// Check if currently recording
  Future<bool> isRecording() async {
    try {
      return await _recorder.isRecording();
    } catch (e) {
      print('[VoiceService] Error checking recording status: $e');
      return false;
    }
  }

  /// Check if currently playing
  bool get isPlaying => _player.state == PlayerState.playing;

  /// Check if currently paused
  bool get isPaused => _player.state == PlayerState.paused;

  /// Get player state stream
  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;

  /// Get position stream
  Stream<Duration> get positionStream => _player.onPositionChanged;

  /// Get duration stream
  Stream<Duration?> get durationStream => _player.onDurationChanged;

  /// Clean up temporary audio files with intelligent caching
  /// Requirement 8.3: Optimize voice processing and audio file management
  Future<void> cleanupTempFiles({bool keepRecentTTS = true}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      final now = DateTime.now();
      
      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          
          // Always clean up voice recordings (they're one-time use)
          if (fileName.contains('voice_recording_')) {
            try {
              await file.delete();
              print('[VoiceService] Deleted voice recording: $fileName');
            } catch (e) {
              print('[VoiceService] Error deleting voice recording $fileName: $e');
            }
          }
          // Clean up old TTS files but keep recent ones for caching
          else if (fileName.contains('tts_audio_')) {
            try {
              final stat = await file.stat();
              final age = now.difference(stat.modified);
              
              // Keep TTS files for 1 hour for caching, unless explicitly cleaning all
              if (!keepRecentTTS || age.inHours >= 1) {
                await file.delete();
                print('[VoiceService] Deleted old TTS file: $fileName (age: ${age.inMinutes}min)');
              }
            } catch (e) {
              print('[VoiceService] Error processing TTS file $fileName: $e');
            }
          }
        }
      }
    } catch (e) {
      print('[VoiceService] Error cleaning up temp files: $e');
    }
  }

  /// Get cache statistics for monitoring
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      int voiceRecordings = 0;
      int ttsFiles = 0;
      int totalSize = 0;
      
      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          final stat = await file.stat();
          
          if (fileName.contains('voice_recording_')) {
            voiceRecordings++;
            totalSize += stat.size;
          } else if (fileName.contains('tts_audio_')) {
            ttsFiles++;
            totalSize += stat.size;
          }
        }
      }
      
      return {
        'voice_recordings': voiceRecordings,
        'tts_files': ttsFiles,
        'total_size_bytes': totalSize,
        'total_size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      print('[VoiceService] Error getting cache stats: $e');
      return {};
    }
  }

  /// Dispose resources
  void dispose() {
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _recorder.dispose();
    _player.dispose();
  }
}

/// Voice Recording State Notifier
class VoiceRecordingStateNotifier extends StateNotifier<VoiceRecordingState> {
  final VoiceService _voiceService;
  Timer? _recordingTimer;
  Timer? _amplitudeTimer;

  VoiceRecordingStateNotifier(this._voiceService) : super(const VoiceRecordingState());

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    super.dispose();
  }

  /// Start recording with permission check
  Future<void> startRecording() async {
    if (state.status != VoiceRecordingStatus.idle) {
      print('[VoiceRecording] Cannot start recording, current status: ${state.status}');
      return;
    }

    // Request permission
    state = state.copyWith(status: VoiceRecordingStatus.requesting_permission);
    
    final hasPermission = await _voiceService.hasMicrophonePermission();
    if (!hasPermission) {
      final granted = await _voiceService.requestMicrophonePermission();
      if (!granted) {
        state = state.copyWith(
          status: VoiceRecordingStatus.permission_denied,
          errorMessage: 'Microphone permission is required for voice messages',
        );
        return;
      }
    }

    // Start recording
    try {
      final filePath = await _voiceService.startRecording();
      if (filePath == null) {
        state = state.copyWith(
          status: VoiceRecordingStatus.error,
          errorMessage: 'Failed to start recording',
        );
        return;
      }

      state = state.copyWith(
        status: VoiceRecordingStatus.recording,
        filePath: filePath,
        duration: Duration.zero,
        amplitude: 0.0,
        errorMessage: null,
      );

      // Start timers for duration and amplitude updates
      _startRecordingTimers();
      
    } catch (e) {
      state = state.copyWith(
        status: VoiceRecordingStatus.error,
        errorMessage: 'Error starting recording: $e',
      );
    }
  }

  /// Stop recording and process audio
  Future<void> stopRecording() async {
    if (state.status != VoiceRecordingStatus.recording) {
      print('[VoiceRecording] Cannot stop recording, current status: ${state.status}');
      return;
    }

    // Stop timers
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();

    state = state.copyWith(status: VoiceRecordingStatus.processing);

    try {
      final filePath = await _voiceService.stopRecording();
      if (filePath == null) {
        state = state.copyWith(
          status: VoiceRecordingStatus.error,
          errorMessage: 'Failed to stop recording',
        );
        return;
      }

      // Convert to base64 for API transmission
      final base64Data = await _voiceService.convertToBase64(filePath);
      if (base64Data == null) {
        state = state.copyWith(
          status: VoiceRecordingStatus.error,
          errorMessage: 'Failed to process audio file',
        );
        return;
      }

      state = state.copyWith(
        status: VoiceRecordingStatus.completed,
        filePath: filePath,
        base64Data: base64Data,
        errorMessage: null,
      );

    } catch (e) {
      state = state.copyWith(
        status: VoiceRecordingStatus.error,
        errorMessage: 'Error processing recording: $e',
      );
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    if (state.status != VoiceRecordingStatus.recording) {
      return;
    }

    // Stop timers
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();

    try {
      await _voiceService.cancelRecording();
      state = const VoiceRecordingState(); // Reset to initial state
    } catch (e) {
      state = state.copyWith(
        status: VoiceRecordingStatus.error,
        errorMessage: 'Error cancelling recording: $e',
      );
    }
  }

  /// Reset state to idle
  void reset() {
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    state = const VoiceRecordingState();
  }

  /// Start recording duration and amplitude timers
  void _startRecordingTimers() {
    // Update duration every 100ms
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (state.status == VoiceRecordingStatus.recording) {
        final currentDuration = state.duration ?? Duration.zero;
        state = state.copyWith(
          duration: currentDuration + const Duration(milliseconds: 100),
        );
      } else {
        timer.cancel();
      }
    });

    // Update amplitude every 50ms for smooth visual feedback
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      if (state.status == VoiceRecordingStatus.recording) {
        try {
          final amplitude = await _voiceService.getAmplitude();
          state = state.copyWith(amplitude: amplitude);
        } catch (e) {
          print('[VoiceRecording] Error getting amplitude: $e');
        }
      } else {
        timer.cancel();
      }
    });
  }
}

/// Voice Playback State Notifier
class VoicePlaybackStateNotifier extends StateNotifier<VoicePlaybackState> {
  final VoiceService _voiceService;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  VoicePlaybackStateNotifier(this._voiceService) : super(const VoicePlaybackState()) {
    _initializeListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    super.dispose();
  }

  /// Initialize audio player event listeners
  void _initializeListeners() {
    // Listen to player state changes
    _playerStateSubscription = _voiceService.playerStateStream.listen((playerState) {
      switch (playerState) {
        case PlayerState.playing:
          if (state.status != VoicePlaybackStatus.playing) {
            state = state.copyWith(status: VoicePlaybackStatus.playing);
          }
          break;
        case PlayerState.paused:
          state = state.copyWith(status: VoicePlaybackStatus.paused);
          break;
        case PlayerState.stopped:
        case PlayerState.completed:
          state = state.copyWith(
            status: VoicePlaybackStatus.completed,
            position: Duration.zero,
          );
          break;
        case PlayerState.disposed:
          state = state.copyWith(status: VoicePlaybackStatus.idle);
          break;
      }
    });

    // Listen to position changes
    _positionSubscription = _voiceService.positionStream.listen((position) {
      if (state.status == VoicePlaybackStatus.playing || 
          state.status == VoicePlaybackStatus.paused) {
        state = state.copyWith(position: position);
      }
    });

    // Listen to duration changes
    _durationSubscription = _voiceService.durationStream.listen((duration) {
      if (duration != null && state.duration != duration) {
        state = state.copyWith(duration: duration);
      }
    });
  }

  /// Play audio from base64 data (TTS responses)
  Future<void> playFromBase64(String base64Data, String messageId) async {
    if (state.status == VoicePlaybackStatus.playing && 
        state.currentMessageId == messageId) {
      // Already playing this message, pause instead
      await pause();
      return;
    }

    // Stop current playback if any
    if (state.status == VoicePlaybackStatus.playing) {
      await stop();
    }

    state = state.copyWith(
      status: VoicePlaybackStatus.loading,
      currentMessageId: messageId,
      errorMessage: null,
    );

    try {
      final success = await _voiceService.playAudioFromBase64(base64Data, messageId);
      if (!success) {
        state = state.copyWith(
          status: VoicePlaybackStatus.error,
          errorMessage: 'Failed to play audio',
        );
      }
      // Status will be updated by player state listener
    } catch (e) {
      state = state.copyWith(
        status: VoicePlaybackStatus.error,
        errorMessage: 'Error playing audio: $e',
      );
    }
  }

  /// Play audio from file path
  Future<void> playFromFile(String filePath, {String? messageId}) async {
    // Stop current playback if any
    if (state.status == VoicePlaybackStatus.playing) {
      await stop();
    }

    state = state.copyWith(
      status: VoicePlaybackStatus.loading,
      currentMessageId: messageId,
      errorMessage: null,
    );

    try {
      final success = await _voiceService.playAudioFromFile(filePath);
      if (!success) {
        state = state.copyWith(
          status: VoicePlaybackStatus.error,
          errorMessage: 'Failed to play audio file',
        );
      }
      // Status will be updated by player state listener
    } catch (e) {
      state = state.copyWith(
        status: VoicePlaybackStatus.error,
        errorMessage: 'Error playing audio file: $e',
      );
    }
  }

  /// Pause playback
  Future<void> pause() async {
    if (state.status != VoicePlaybackStatus.playing) {
      return;
    }

    try {
      await _voiceService.pausePlayback();
      // Status will be updated by player state listener
    } catch (e) {
      state = state.copyWith(
        status: VoicePlaybackStatus.error,
        errorMessage: 'Error pausing playback: $e',
      );
    }
  }

  /// Resume playback
  Future<void> resume() async {
    if (state.status != VoicePlaybackStatus.paused) {
      return;
    }

    try {
      await _voiceService.resumePlayback();
      // Status will be updated by player state listener
    } catch (e) {
      state = state.copyWith(
        status: VoicePlaybackStatus.error,
        errorMessage: 'Error resuming playback: $e',
      );
    }
  }

  /// Stop playback
  Future<void> stop() async {
    if (state.status == VoicePlaybackStatus.idle) {
      return;
    }

    try {
      await _voiceService.stopPlayback();
      state = state.copyWith(
        status: VoicePlaybackStatus.idle,
        position: Duration.zero,
        currentMessageId: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: VoicePlaybackStatus.error,
        errorMessage: 'Error stopping playback: $e',
      );
    }
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    if (state.status != VoicePlaybackStatus.playing && 
        state.status != VoicePlaybackStatus.paused) {
      return;
    }

    try {
      await _voiceService.seekTo(position);
      state = state.copyWith(position: position);
    } catch (e) {
      state = state.copyWith(
        status: VoicePlaybackStatus.error,
        errorMessage: 'Error seeking to position: $e',
      );
    }
  }

  /// Reset state to idle
  void reset() {
    state = const VoicePlaybackState();
  }

  /// Toggle play/pause for current message
  Future<void> togglePlayPause() async {
    switch (state.status) {
      case VoicePlaybackStatus.playing:
        await pause();
        break;
      case VoicePlaybackStatus.paused:
        await resume();
        break;
      default:
        // Cannot toggle if not playing or paused
        break;
    }
  }

  /// Get playback progress (0.0 to 1.0)
  double get progress {
    if (state.duration == null || state.position == null) {
      return 0.0;
    }
    
    final totalMs = state.duration!.inMilliseconds;
    final currentMs = state.position!.inMilliseconds;
    
    if (totalMs <= 0) return 0.0;
    
    return (currentMs / totalMs).clamp(0.0, 1.0);
  }

  /// Check if currently playing a specific message
  bool isPlayingMessage(String messageId) {
    return state.status == VoicePlaybackStatus.playing && 
           state.currentMessageId == messageId;
  }

  /// Check if currently paused on a specific message
  bool isPausedOnMessage(String messageId) {
    return state.status == VoicePlaybackStatus.paused && 
           state.currentMessageId == messageId;
  }
}