import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/models/ai/ai_events.dart';
import 'package:emotion_tracker/utils/ai_animations.dart';

class AgentSelectorWidget extends ConsumerStatefulWidget {
  final AgentType? selectedAgent;
  final Function(AgentType) onAgentSelected;
  final bool compact;
  final bool showDescriptions;
  final EdgeInsets? padding;

  const AgentSelectorWidget({
    super.key,
    this.selectedAgent,
    required this.onAgentSelected,
    this.compact = false,
    this.showDescriptions = true,
    this.padding,
  });

  @override
  ConsumerState<AgentSelectorWidget> createState() => _AgentSelectorWidgetState();
}

class _AgentSelectorWidgetState extends ConsumerState<AgentSelectorWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  AgentType? _hoveredAgent;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    
    return Container(
      padding: widget.padding ?? EdgeInsets.all(widget.compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.compact) ...[
            Text(
              'Choose AI Assistant',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ).animateFadeIn(),
            const SizedBox(height: 8),
            Text(
              'Select an AI agent specialized for your needs',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ).animateFadeIn(),
            const SizedBox(height: 20),
          ],
          
          // Agent Grid
          _buildAgentGrid(theme),
        ],
      ),
    );
  }

  /// Build grid of agent cards
  Widget _buildAgentGrid(ThemeData theme) {
    final agents = _getAvailableAgents();
    
    if (widget.compact) {
      // Horizontal scrollable list for compact mode
      return SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: agents.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(right: index < agents.length - 1 ? 12 : 0),
              child: _buildAgentCard(theme, agents[index], compact: true)
                  .animateFadeIn(),
            );
          },
        ),
      );
    } else {
      // Grid layout for full mode
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: agents.length,
        itemBuilder: (context, index) {
          return _buildAgentCard(theme, agents[index])
              .animateFadeIn();
        },
      );
    }
  }

  /// Get number of columns based on screen width
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return 3;
    if (width > 400) return 2;
    return 1;
  }

  /// Build individual agent card
  Widget _buildAgentCard(ThemeData theme, AgentInfo agent, {bool compact = false}) {
    final isSelected = widget.selectedAgent == agent.type;
    final isHovered = _hoveredAgent == agent.type;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredAgent = agent.type),
      onExit: (_) => setState(() => _hoveredAgent = null),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isHovered ? _scaleAnimation.value : 1.0,
            child: GestureDetector(
              onTap: () => _handleAgentSelection(agent.type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: compact ? 120 : null,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? theme.primaryColor.withOpacity(0.1)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(compact ? 12 : 16),
                  border: Border.all(
                    color: isSelected 
                        ? theme.primaryColor
                        : isHovered
                            ? theme.primaryColor.withOpacity(0.5)
                            : theme.dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    if (isHovered || isSelected)
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(compact ? 12 : 16),
                    onTap: () => _handleAgentSelection(agent.type),
                    child: Padding(
                      padding: EdgeInsets.all(compact ? 12 : 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Agent Icon
                          Container(
                            width: compact ? 32 : 48,
                            height: compact ? 32 : 48,
                            decoration: BoxDecoration(
                              color: agent.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(compact ? 16 : 24),
                              border: Border.all(
                                color: agent.color.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              agent.icon,
                              color: agent.color,
                              size: compact ? 18 : 24,
                            ),
                          ),
                          
                          SizedBox(height: compact ? 6 : 12),
                          
                          // Agent Name
                          Text(
                            agent.name,
                            style: (compact 
                                ? theme.textTheme.bodySmall
                                : theme.textTheme.titleSmall)?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected 
                                  ? theme.primaryColor
                                  : theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          // Agent Description (only in full mode)
                          if (!compact && widget.showDescriptions) ...[
                            const SizedBox(height: 6),
                            Text(
                              agent.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          
                          // Capabilities badges (only in full mode)
                          if (!compact && agent.capabilities.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              alignment: WrapAlignment.center,
                              children: agent.capabilities.take(2).map((capability) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: agent.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: agent.color.withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    capability,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: agent.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          
                          // Selection indicator
                          if (isSelected) ...[
                            SizedBox(height: compact ? 4 : 8),
                            Container(
                              width: compact ? 16 : 20,
                              height: compact ? 16 : 20,
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                borderRadius: BorderRadius.circular(compact ? 8 : 10),
                              ),
                              child: Icon(
                                Icons.check,
                                color: theme.colorScheme.onPrimary,
                                size: compact ? 12 : 14,
                              ),
                            ).animateFadeIn(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Handle agent selection with animation and haptic feedback
  void _handleAgentSelection(AgentType agentType) {
    if (widget.selectedAgent != agentType) {
      // Trigger selection animation
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
      
      // Provide haptic feedback and sound
      AIHaptics.selection();
      
      // Call the selection callback
      widget.onAgentSelected(agentType);
    }
  }

  /// Get list of available agents with their information
  List<AgentInfo> _getAvailableAgents() {
    return [
      AgentInfo(
        type: AgentType.family,
        name: 'Family Assistant',
        description: 'Manage family relationships, invitations, and shared resources',
        icon: Icons.family_restroom,
        color: Colors.blue,
        capabilities: ['Family Management', 'Invitations', 'Shared Resources'],
      ),
      AgentInfo(
        type: AgentType.personal,
        name: 'Personal Assistant',
        description: 'Your personal helper for daily tasks and organization',
        icon: Icons.person_outline,
        color: Colors.green,
        capabilities: ['Task Management', 'Organization', 'Reminders'],
      ),
      AgentInfo(
        type: AgentType.workspace,
        name: 'Workspace Assistant',
        description: 'Boost productivity with work-related assistance',
        icon: Icons.work_outline,
        color: Colors.orange,
        capabilities: ['Productivity', 'Collaboration', 'Project Management'],
      ),
      AgentInfo(
        type: AgentType.commerce,
        name: 'Commerce Assistant',
        description: 'Help with shopping, purchases, and digital assets',
        icon: Icons.shopping_cart_outlined,
        color: Colors.purple,
        capabilities: ['Shopping', 'Purchases', 'Digital Assets'],
      ),
      AgentInfo(
        type: AgentType.security,
        name: 'Security Assistant',
        description: 'Monitor security settings and account safety',
        icon: Icons.security_outlined,
        color: Colors.red,
        capabilities: ['Security', 'Monitoring', 'Account Safety'],
      ),
      AgentInfo(
        type: AgentType.voice,
        name: 'Voice Assistant',
        description: 'Specialized for voice interactions and audio processing',
        icon: Icons.record_voice_over_outlined,
        color: Colors.teal,
        capabilities: ['Voice Processing', 'Audio', 'Speech Recognition'],
      ),
    ];
  }
}

/// Agent information data class
class AgentInfo {
  final AgentType type;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> capabilities;

  const AgentInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.capabilities,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentInfo && other.type == type;
  }

  @override
  int get hashCode => type.hashCode;
}

/// Agent Selector Dialog - for showing agent selection in a modal
class AgentSelectorDialog extends ConsumerWidget {
  final AgentType? selectedAgent;
  final Function(AgentType) onAgentSelected;

  const AgentSelectorDialog({
    super.key,
    this.selectedAgent,
    required this.onAgentSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    
    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select AI Assistant',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      AIHaptics.lightTap();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ],
              ),
            ).animateSlideUp(),
            
            // Agent Selector
            Flexible(
              child: SingleChildScrollView(
                child: AgentSelectorWidget(
                  selectedAgent: selectedAgent,
                  onAgentSelected: (agent) {
                    onAgentSelected(agent);
                    Navigator.of(context).pop();
                  },
                  compact: false,
                  showDescriptions: true,
                  padding: const EdgeInsets.all(20),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animateSlideUp();
  }

  /// Show agent selector dialog
  static Future<AgentType?> show(
    BuildContext context, {
    AgentType? selectedAgent,
  }) async {
    return showDialog<AgentType>(
      context: context,
      builder: (context) => AgentSelectorDialog(
        selectedAgent: selectedAgent,
        onAgentSelected: (agent) => Navigator.of(context).pop(agent),
      ),
    );
  }
}

/// Agent Selector Bottom Sheet - for showing agent selection in a bottom sheet
class AgentSelectorBottomSheet extends ConsumerWidget {
  final AgentType? selectedAgent;
  final Function(AgentType) onAgentSelected;

  const AgentSelectorBottomSheet({
    super.key,
    this.selectedAgent,
    required this.onAgentSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select AI Assistant',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Agent Selector
            Flexible(
              child: SingleChildScrollView(
                child: AgentSelectorWidget(
                  selectedAgent: selectedAgent,
                  onAgentSelected: (agent) {
                    onAgentSelected(agent);
                    Navigator.of(context).pop();
                  },
                  compact: false,
                  showDescriptions: true,
                  padding: const EdgeInsets.all(20),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animateSlideUp();
  }

  /// Show agent selector bottom sheet
  static Future<AgentType?> show(
    BuildContext context, {
    AgentType? selectedAgent,
  }) async {
    return showModalBottomSheet<AgentType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AgentSelectorBottomSheet(
        selectedAgent: selectedAgent,
        onAgentSelected: (agent) => Navigator.of(context).pop(agent),
      ),
    );
  }
}