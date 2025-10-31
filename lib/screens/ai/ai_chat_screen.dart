import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:emotion_tracker/widgets/app_scaffold.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/ai/chat_message_widget.dart';
import 'package:emotion_tracker/widgets/ai/agent_selector_widget.dart';
import 'package:emotion_tracker/widgets/ai/voice_input_widget.dart';
import 'package:emotion_tracker/widgets/ai/ai_offline_indicator.dart' as ai_offline_indicator;
import 'package:emotion_tracker/widgets/ai/ai_skeleton_widgets.dart';
import 'package:emotion_tracker/screens/ai/ai_offline_queue_screen.dart';
import 'package:emotion_tracker/providers/ai/ai_providers.dart';
import 'package:emotion_tracker/providers/ai/ai_websocket_client.dart';
import 'package:emotion_tracker/providers/ai/ai_offline_service.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/models/ai/ai_events.dart';
import 'package:emotion_tracker/utils/ai_animations.dart';
import 'package:emotion_tracker/screens/settings/variant1.dart';
import 'package:emotion_tracker/screens/shop/variant1/variant1.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  bool _showAgentSelector = false;
  bool _isVoiceMode = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    
    // Set up pagination listener
    _scrollController.addListener(_onScroll);
  }

  /// Handle scroll events for pagination
  /// Requirement 8.3: Implement pagination to handle large conversations
  void _onScroll() {
    if (_scrollController.position.pixels <= 100 && !_isLoadingMore) {
      // User scrolled near the top, load more messages
      _loadMoreMessages();
    }
  }

  /// Load more messages for pagination
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final hasMore = await ref.read(chatMessagesProvider.notifier).loadMoreMessages();
      if (!hasMore) {
        // Show a brief message that no more messages are available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No more messages to load'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more messages: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _handleNavigation(String item) {
    Navigator.of(context).pop(); // Close drawer
    
    if (item == 'dashboard') {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home/v1',
        (route) => false,
      );
    } else if (item == 'settings') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreenV1()),
      );
    } else if (item == 'shop') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ShopScreenV1()),
      );
    }
    // If item == 'ai_chat', do nothing as we're already on this screen
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final currentSession = ref.watch(currentAISessionProvider);
    final messages = ref.watch(chatMessagesProvider);
    final connectionState = ref.watch(aiConnectionStateProvider);

    return AppScaffold(
      title: _buildTitle(currentSession),
      selectedItem: 'ai_chat',
      onItemSelected: _handleNavigation,
      showCurrency: false, // Hide currency in AI chat for cleaner UI
      body: Column(
        children: [
          // Offline Banner (shows when offline)
          ai_offline_indicator.AIOfflineBanner(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AIOfflineQueueScreen(),
                ),
              );
            },
          ),
          
          // Connection Status Bar
          _buildConnectionStatusBar(theme, connectionState),
          
          // Agent Selector (collapsible)
          if (_showAgentSelector)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: AgentSelectorWidget(
                selectedAgent: currentSession?.agentType,
                onAgentSelected: _handleAgentSelection,
                compact: true,
              ),
            ).animateSlideUp(),
          
          // Chat Messages Area
          Expanded(
            child: _buildChatArea(theme, currentSession, messages, connectionState),
          ),
          
          // Input Area
          _buildInputArea(theme, currentSession, connectionState),
        ],
      ),
      actions: [
        // Agent Selector Toggle
        IconButton(
          icon: Icon(
            _showAgentSelector ? Icons.expand_less : Icons.expand_more,
            color: theme.colorScheme.onPrimary,
          ),
          onPressed: () {
            AIHaptics.lightTap();
            setState(() {
              _showAgentSelector = !_showAgentSelector;
            });
          },
          tooltip: 'Select AI Agent',
        ),
        
        // Voice Mode Toggle
        IconButton(
          icon: Icon(
            _isVoiceMode ? Icons.keyboard : Icons.mic,
            color: theme.colorScheme.onPrimary,
          ),
          onPressed: () {
            AIHaptics.lightTap();
            setState(() {
              _isVoiceMode = !_isVoiceMode;
            });
          },
          tooltip: _isVoiceMode ? 'Switch to Text' : 'Switch to Voice',
        ),
      ],
    );
  }

  /// Build dynamic title based on current session
  String _buildTitle(AISession? session) {
    if (session == null) {
      return 'AI Chat';
    }
    
    final agentName = _getAgentDisplayName(session.agentType);
    return 'AI Chat - $agentName';
  }

  /// Get display name for agent type
  String _getAgentDisplayName(AgentType agentType) {
    switch (agentType) {
      case AgentType.family:
        return 'Family Assistant';
      case AgentType.personal:
        return 'Personal Assistant';
      case AgentType.workspace:
        return 'Workspace Assistant';
      case AgentType.commerce:
        return 'Commerce Assistant';
      case AgentType.security:
        return 'Security Assistant';
      case AgentType.voice:
        return 'Voice Assistant';
    }
  }

  /// Build connection status bar with offline awareness
  /// Requirement 7.4: Display offline mode with cached conversation history
  Widget _buildConnectionStatusBar(ThemeData theme, AIConnectionState connectionState) {
    final offlineService = ref.watch(aiOfflineServiceProvider);
    
    return StreamBuilder<bool>(
      stream: offlineService.offlineStatus,
      initialData: offlineService.isOffline,
      builder: (context, offlineSnapshot) {
        final isOffline = offlineSnapshot.data ?? false;
        
        // Don't show connection status bar if offline banner is showing
        if (isOffline) {
          return const SizedBox.shrink();
        }
        
        Color statusColor;
        String statusText;
        IconData statusIcon;

        switch (connectionState) {
          case AIConnectionState.connected:
            statusColor = Colors.green;
            statusText = 'Connected';
            statusIcon = Icons.check_circle;
            break;
          case AIConnectionState.connecting:
            statusColor = Colors.orange;
            statusText = 'Connecting...';
            statusIcon = Icons.sync;
            break;
          case AIConnectionState.reconnecting:
            statusColor = Colors.orange;
            statusText = 'Reconnecting...';
            statusIcon = Icons.sync;
            break;
          case AIConnectionState.disconnected:
            statusColor = Colors.grey;
            statusText = 'Disconnected';
            statusIcon = Icons.cloud_off;
            break;
          case AIConnectionState.error:
            statusColor = Colors.red;
            statusText = 'Connection Error';
            statusIcon = Icons.error;
            break;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: statusColor.withOpacity(0.3),
                width: 1,
              ),
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
              if (connectionState == AIConnectionState.connecting ||
                  connectionState == AIConnectionState.reconnecting) ...[
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
              const Spacer(),
              // Connection status indicator
              const ai_offline_indicator.AIConnectionStatusIndicator(
                showLabel: false,
                mainAxisSize: MainAxisSize.min,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build main chat area
  Widget _buildChatArea(
    ThemeData theme,
    AISession? session,
    List<ChatMessage> messages,
    AIConnectionState connectionState,
  ) {
    if (session == null) {
      return _buildWelcomeScreen(theme);
    }

    // Show skeleton loading while messages are loading
    final isLoading = ref.watch(chatMessagesProvider.notifier).isLoading;
    if (isLoading && messages.isEmpty) {
      return AISkeletonWidgets.chatHistory(context);
    }

    if (messages.isEmpty) {
      return _buildEmptyChat(theme, session);
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: messages.length + 
                  (ref.read(chatMessagesProvider.notifier).isStreaming ? 1 : 0) +
                  (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at top when loading more messages
          if (_isLoadingMore && index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading more messages...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Adjust index for loading indicator
          final messageIndex = _isLoadingMore ? index - 1 : index;
          
          // Show typing indicator if streaming
          if (messageIndex == messages.length && ref.read(chatMessagesProvider.notifier).isStreaming) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: AISkeletonWidgets.typingIndicator(context),
            );
          }
          
          final message = messages[messageIndex];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ChatMessageWidget(
              message: message,
              isStreaming: messageIndex == messages.length - 1 && 
                         ref.read(chatMessagesProvider.notifier).isStreaming,
            ),
          );
        },
      ),
    );
  }

  /// Build welcome screen when no session is active
  Widget _buildWelcomeScreen(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_rounded,
              size: 64,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to AI Chat',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Select an AI agent to start chatting. Each agent specializes in different areas to help you with various tasks.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                AIHaptics.mediumTap();
                setState(() {
                  _showAgentSelector = true;
                });
              },
              icon: const Icon(Icons.psychology),
              label: const Text('Choose AI Agent'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ).animateButtonPress(),
          ],
        ),
      ),
    );
  }

  /// Build empty chat screen for active session
  Widget _buildEmptyChat(ThemeData theme, AISession session) {
    final agentName = _getAgentDisplayName(session.agentType);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getAgentIcon(session.agentType),
              size: 48,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Chat with $agentName',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getAgentDescription(session.agentType),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                'Start typing a message below or use voice input to begin your conversation.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get icon for agent type
  IconData _getAgentIcon(AgentType agentType) {
    switch (agentType) {
      case AgentType.family:
        return Icons.family_restroom;
      case AgentType.personal:
        return Icons.person;
      case AgentType.workspace:
        return Icons.work;
      case AgentType.commerce:
        return Icons.shopping_cart;
      case AgentType.security:
        return Icons.security;
      case AgentType.voice:
        return Icons.record_voice_over;
    }
  }

  /// Get description for agent type
  String _getAgentDescription(AgentType agentType) {
    switch (agentType) {
      case AgentType.family:
        return 'Helps with family management, invitations, and shared resources.';
      case AgentType.personal:
        return 'Your personal assistant for daily tasks and organization.';
      case AgentType.workspace:
        return 'Assists with work-related tasks and productivity.';
      case AgentType.commerce:
        return 'Helps with shopping, purchases, and digital assets.';
      case AgentType.security:
        return 'Manages security settings and monitors account safety.';
      case AgentType.voice:
        return 'Specialized for voice interactions and audio processing.';
    }
  }

  /// Build input area (text or voice)
  Widget _buildInputArea(
    ThemeData theme,
    AISession? session,
    AIConnectionState connectionState,
  ) {
    final isConnected = connectionState == AIConnectionState.connected;
    final canSendMessage = session != null && isConnected;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isVoiceMode
              ? _buildVoiceInput(theme, canSendMessage)
              : _buildTextInput(theme, canSendMessage),
        ),
      ),
    );
  }

  /// Build text input area
  Widget _buildTextInput(ThemeData theme, bool canSendMessage) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              enabled: canSendMessage,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: canSendMessage 
                    ? 'Type your message...'
                    : 'Connect to start chatting',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              style: theme.textTheme.bodyMedium,
              onSubmitted: canSendMessage ? _handleSendMessage : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          onPressed: canSendMessage && _messageController.text.trim().isNotEmpty
              ? () {
                  AIHaptics.messageSent();
                  AISounds.messageSent();
                  _handleSendMessage(_messageController.text);
                }
              : null,
          backgroundColor: canSendMessage && _messageController.text.trim().isNotEmpty
              ? theme.primaryColor
              : theme.disabledColor,
          foregroundColor: theme.colorScheme.onPrimary,
          mini: true,
          child: const Icon(Icons.send),
        ).animateButtonPress(),
      ],
    );
  }

  /// Build voice input area
  Widget _buildVoiceInput(ThemeData theme, bool canSendMessage) {
    return VoiceInputWidget(
      enabled: canSendMessage,
      onVoiceMessage: _handleVoiceMessage,
      onTextFallback: () {
        setState(() {
          _isVoiceMode = false;
        });
      },
    );
  }

  /// Handle agent selection
  Future<void> _handleAgentSelection(AgentType agentType) async {
    final currentSession = ref.read(currentAISessionProvider);
    
    if (currentSession?.agentType == agentType) {
      // Same agent selected, just close selector
      setState(() {
        _showAgentSelector = false;
      });
      return;
    }

    try {
      // Show loading state
      setState(() {
        _showAgentSelector = false;
      });

      if (currentSession != null) {
        // Switch agent in existing session
        await ref.read(currentAISessionProvider.notifier).switchAgent(agentType);
      } else {
        // Create new session with selected agent
        final session = await ref.read(currentAISessionProvider.notifier).createSession(
          agentType: agentType,
          voiceEnabled: _isVoiceMode,
        );
        
        if (session != null) {
          // Connect WebSocket to new session
          await ref.read(aiConnectionStateProvider.notifier).connectToSession(
            session.sessionId,
            agentType: agentType.value,
          );
          
          // Load session history
          await ref.read(chatMessagesProvider.notifier).loadSessionHistory(
            session.sessionId,
          );
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select agent: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle sending text message
  Future<void> _handleSendMessage(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) return;

    final session = ref.read(currentAISessionProvider);
    if (session == null) return;

    // Clear input immediately for better UX
    _messageController.clear();
    _messageFocusNode.requestFocus();

    try {
      await ref.read(chatMessagesProvider.notifier).sendMessage(
        sessionId: session.sessionId,
        content: trimmedMessage,
        messageType: MessageType.text,
      );

      // Auto-scroll to bottom after sending
      _scrollToBottom();
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle voice message
  Future<void> _handleVoiceMessage(String audioData) async {
    final session = ref.read(currentAISessionProvider);
    if (session == null) return;

    try {
      await ref.read(chatMessagesProvider.notifier).sendMessage(
        sessionId: session.sessionId,
        content: '', // Voice messages have empty text content
        messageType: MessageType.voice,
        audioData: audioData,
      );

      // Auto-scroll to bottom after sending
      _scrollToBottom();
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send voice message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Scroll to bottom of chat
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }
}