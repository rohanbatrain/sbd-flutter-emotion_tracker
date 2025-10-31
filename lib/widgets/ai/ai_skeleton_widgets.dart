import 'package:flutter/material.dart';
import 'package:emotion_tracker/utils/ai_animations.dart';

/// Skeleton loading widgets for AI chat interface
/// Requirement 8.2: Efficient state updates and smooth loading states
class AISkeletonWidgets {
  /// Chat history skeleton loader
  static Widget chatHistory(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _MessageSkeleton(
            isUser: index % 2 == 0,
            theme: theme,
          ),
        );
      },
    );
  }

  /// Typing indicator for AI responses
  static Widget typingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.smart_toy,
              size: 16,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
            child: AIAnimations.typingIndicator(
              color: theme.primaryColor,
              size: 6,
            ),
          ),
        ],
      ),
    );
  }

  /// Agent selector skeleton
  static Widget agentSelector(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(
            width: 120,
            height: 20,
            theme: theme,
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  child: _SkeletonBox(
                    height: 80,
                    theme: theme,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Voice input skeleton
  static Widget voiceInput(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _SkeletonBox(
            width: 48,
            height: 48,
            theme: theme,
            isCircle: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _SkeletonBox(
              height: 48,
              theme: theme,
            ),
          ),
          const SizedBox(width: 16),
          _SkeletonBox(
            width: 48,
            height: 48,
            theme: theme,
            isCircle: true,
          ),
        ],
      ),
    );
  }

  /// Connection status skeleton
  static Widget connectionStatus(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _SkeletonBox(
            width: 16,
            height: 16,
            theme: theme,
            isCircle: true,
          ),
          const SizedBox(width: 8),
          _SkeletonBox(
            width: 80,
            height: 16,
            theme: theme,
          ),
          const Spacer(),
          _SkeletonBox(
            width: 60,
            height: 16,
            theme: theme,
          ),
        ],
      ),
    );
  }

  /// Tool execution skeleton
  static Widget toolExecution(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBox(
                width: 20,
                height: 20,
                theme: theme,
                isCircle: true,
              ),
              const SizedBox(width: 8),
              _SkeletonBox(
                width: 100,
                height: 16,
                theme: theme,
              ),
              const Spacer(),
              _SkeletonBox(
                width: 60,
                height: 16,
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SkeletonBox(
            width: double.infinity,
            height: 12,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _SkeletonBox(
            width: 200,
            height: 12,
            theme: theme,
          ),
        ],
      ),
    );
  }

  /// Session list skeleton
  static Widget sessionList(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SkeletonBox(
                    width: 24,
                    height: 24,
                    theme: theme,
                    isCircle: true,
                  ),
                  const SizedBox(width: 12),
                  _SkeletonBox(
                    width: 120,
                    height: 16,
                    theme: theme,
                  ),
                  const Spacer(),
                  _SkeletonBox(
                    width: 60,
                    height: 14,
                    theme: theme,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SkeletonBox(
                width: double.infinity,
                height: 14,
                theme: theme,
              ),
              const SizedBox(height: 6),
              _SkeletonBox(
                width: 180,
                height: 14,
                theme: theme,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Individual message skeleton
class _MessageSkeleton extends StatelessWidget {
  final bool isUser;
  final ThemeData theme;

  const _MessageSkeleton({
    required this.isUser,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          _SkeletonBox(
            width: 32,
            height: 32,
            theme: theme,
            isCircle: true,
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? theme.primaryColor.withOpacity(0.1)
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(
                        width: double.infinity,
                        height: 14,
                        theme: theme,
                      ),
                      const SizedBox(height: 8),
                      _SkeletonBox(
                        width: 150,
                        height: 14,
                        theme: theme,
                      ),
                      if (!isUser) ...[
                        const SizedBox(height: 8),
                        _SkeletonBox(
                          width: 200,
                          height: 14,
                          theme: theme,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _SkeletonBox(
                  width: 60,
                  height: 12,
                  theme: theme,
                ),
              ],
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 12),
          _SkeletonBox(
            width: 32,
            height: 32,
            theme: theme,
            isCircle: true,
          ),
        ],
      ],
    ).addShimmer(
      baseColor: theme.colorScheme.surface,
      highlightColor: theme.colorScheme.onSurface.withOpacity(0.1),
    );
  }
}

/// Basic skeleton box widget
class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final ThemeData theme;
  final bool isCircle;

  const _SkeletonBox({
    this.width,
    required this.height,
    required this.theme,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: isCircle 
            ? BorderRadius.circular(height / 2)
            : BorderRadius.circular(8),
      ),
    );
  }
}

