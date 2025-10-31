import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/models/ai/ai_events.dart';
import 'package:emotion_tracker/utils/ai_animations.dart';
import 'package:intl/intl.dart';

class ChatMessageWidget extends ConsumerStatefulWidget {
  final ChatMessage message;
  final bool isStreaming;
  final VoidCallback? onRetry;
  final VoidCallback? onCopy;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.onRetry,
    this.onCopy,
  });

  @override
  ConsumerState<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends ConsumerState<ChatMessageWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _streamingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _streamingAnimation;

  @override
  void initState() {
    super.initState();
    
    // Fade-in animation for new messages
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    // Streaming animation for typing indicator
    _streamingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _streamingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _streamingController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    
    if (widget.isStreaming) {
      _streamingController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ChatMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isStreaming != oldWidget.isStreaming) {
      if (widget.isStreaming) {
        _streamingController.repeat(reverse: true);
      } else {
        _streamingController.stop();
        _streamingController.reset();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _streamingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message.isAssistantMessage) ...[
            _buildAvatar(theme),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: widget.message.isUserMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildMessageBubble(theme),
                const SizedBox(height: 4),
                _buildMessageInfo(theme),
              ],
            ),
          ),
          if (widget.message.isUserMessage) ...[
            const SizedBox(width: 12),
            _buildAvatar(theme),
          ],
        ],
      ),
    ).animateFadeIn();
  }

  /// Build avatar for message sender
  Widget _buildAvatar(ThemeData theme) {
    final isUser = widget.message.isUserMessage;
    final isError = widget.message.metadata['is_error'] == true;
    
    Color avatarColor;
    IconData avatarIcon;
    
    if (isError) {
      avatarColor = Colors.red;
      avatarIcon = Icons.error;
    } else if (isUser) {
      avatarColor = theme.primaryColor;
      avatarIcon = Icons.person;
    } else {
      avatarColor = theme.colorScheme.secondary;
      avatarIcon = _getAgentIcon();
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: avatarColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: avatarColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        avatarIcon,
        color: avatarColor,
        size: 18,
      ),
    );
  }

  /// Get icon for AI agent type
  IconData _getAgentIcon() {
    final agentType = widget.message.agentType;
    if (agentType == null) return Icons.smart_toy;
    
    switch (agentType) {
      case 'family':
        return Icons.family_restroom;
      case 'personal':
        return Icons.person_outline;
      case 'workspace':
        return Icons.work_outline;
      case 'commerce':
        return Icons.shopping_cart_outlined;
      case 'security':
        return Icons.security_outlined;
      case 'voice':
        return Icons.record_voice_over_outlined;
      default:
        return Icons.smart_toy;
    }
  }

  /// Build main message bubble
  Widget _buildMessageBubble(ThemeData theme) {
    final isUser = widget.message.isUserMessage;
    final isError = widget.message.metadata['is_error'] == true;
    final isThinking = widget.message.metadata['is_thinking'] == true;
    final isTyping = widget.message.metadata['is_typing'] == true;
    
    Color bubbleColor;
    Color textColor;
    
    if (isError) {
      bubbleColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
    } else if (isUser) {
      bubbleColor = theme.primaryColor;
      textColor = theme.colorScheme.onPrimary;
    } else {
      bubbleColor = theme.cardColor;
      textColor = theme.colorScheme.onSurface;
    }

    Widget bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
          bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
        ),
        border: isUser ? null : Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            AIHaptics.lightTap();
            widget.onCopy?.call();
          },
          onLongPress: () {
            AIHaptics.mediumTap();
            _showMessageOptions(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message content
                _buildMessageContent(theme, textColor, isThinking, isTyping),
                
                // Tool execution indicator
                if (widget.message.isToolMessage)
                  _buildToolIndicator(theme, textColor),
                
                // Voice message controls
                if (widget.message.isVoiceMessage)
                  _buildVoiceControls(theme, textColor),
                
                // Streaming indicator
                if (widget.isStreaming)
                  _buildStreamingIndicator(theme, textColor),
              ],
            ),
          ),
        ),
      ),
    );

    // Apply fade animation for error messages
    if (isError) {
      bubble = bubble.animateFadeIn();
    }

    return bubble;
  }

  /// Build message content based on type
  Widget _buildMessageContent(
    ThemeData theme,
    Color textColor,
    bool isThinking,
    bool isTyping,
  ) {
    if (isThinking || isTyping) {
      return _buildAnimatedIndicator(theme, textColor, isThinking ? 'thinking' : 'typing');
    }

    return SelectableText(
      widget.message.content,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: textColor,
        height: 1.4,
      ),
    );
  }

  /// Build animated thinking/typing indicator
  Widget _buildAnimatedIndicator(ThemeData theme, Color textColor, String type) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          type == 'thinking' ? 'AI is thinking' : 'AI is typing',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor.withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Build tool execution indicator
  Widget _buildToolIndicator(ThemeData theme, Color textColor) {
    final toolName = widget.message.metadata['tool_name'] as String?;
    final isSuccess = widget.message.metadata['success'] as bool? ?? false;
    final status = widget.message.metadata['status'] as String?;
    
    IconData toolIcon;
    Color toolColor;
    
    if (status == 'executing') {
      toolIcon = Icons.settings;
      toolColor = Colors.orange;
    } else if (isSuccess) {
      toolIcon = Icons.check_circle;
      toolColor = Colors.green;
    } else {
      toolIcon = Icons.error;
      toolColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: toolColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: toolColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            toolIcon,
            color: toolColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            toolName ?? 'Tool',
            style: theme.textTheme.bodySmall?.copyWith(
              color: toolColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (status == 'executing') ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: toolColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build voice message controls
  Widget _buildVoiceControls(ThemeData theme, Color textColor) {
    final hasAudio = widget.message.audioData != null;
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasAudio ? Icons.volume_up : Icons.mic,
            color: textColor.withOpacity(0.7),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            hasAudio ? 'Voice message' : 'Voice input',
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          if (hasAudio) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _playAudio(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: textColor,
                  size: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build streaming indicator
  Widget _buildStreamingIndicator(ThemeData theme, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: AnimatedBuilder(
        animation: _streamingAnimation,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.3 + (_streamingAnimation.value * 0.7)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Streaming...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build message info (timestamp, processing time, etc.)
  Widget _buildMessageInfo(ThemeData theme) {
    final timestamp = widget.message.timestamp;
    final processingTime = widget.message.processingTimeMs;
    final isError = widget.message.metadata['is_error'] == true;
    
    final timeFormat = DateFormat('HH:mm');
    final timeString = timeFormat.format(timestamp);
    
    String infoText = timeString;
    if (processingTime != null && processingTime > 0) {
      infoText += ' • ${processingTime}ms';
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          infoText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isError 
                ? Colors.red.withOpacity(0.7)
                : theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
        if (isError) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: widget.onRetry,
            child: Icon(
              Icons.refresh,
              color: Colors.red.withOpacity(0.7),
              size: 14,
            ),
          ),
        ],
      ],
    );
  }

  /// Show message options menu
  void _showMessageOptions(BuildContext context) {
    final theme = ref.read(currentThemeProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Message'),
              onTap: () {
                Navigator.pop(context);
                _copyMessage();
              },
            ),
            if (widget.message.isVoiceMessage && widget.message.audioData != null)
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Play Audio'),
                onTap: () {
                  Navigator.pop(context);
                  _playAudio();
                },
              ),
            if (widget.message.metadata['is_error'] == true)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Retry'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onRetry?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Message Info'),
              onTap: () {
                Navigator.pop(context);
                _showMessageInfo(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Copy message to clipboard
  void _copyMessage() {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    AIHaptics.lightTap();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message copied to clipboard')
            .animateFadeIn(),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Play audio message
  void _playAudio() {
    // TODO: Implement audio playback
    // This would use the audioplayers package to play the audio data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Playing audio message...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Show detailed message information
  void _showMessageInfo(BuildContext context) {
    final theme = ref.read(currentThemeProvider);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm:ss');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Message Information',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Message ID', widget.message.messageId, theme),
            _buildInfoRow('Role', widget.message.role.value, theme),
            _buildInfoRow('Type', widget.message.messageType.value, theme),
            _buildInfoRow('Timestamp', dateFormat.format(widget.message.timestamp), theme),
            if (widget.message.agentType != null)
              _buildInfoRow('Agent', widget.message.agentType!, theme),
            if (widget.message.processingTimeMs != null)
              _buildInfoRow('Processing Time', '${widget.message.processingTimeMs}ms', theme),
            if (widget.message.audioData != null)
              _buildInfoRow('Has Audio', 'Yes', theme),
            if (widget.message.metadata.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Metadata:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...widget.message.metadata.entries.map(
                (entry) => _buildInfoRow(entry.key, entry.value.toString(), theme),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build info row for message details
  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}