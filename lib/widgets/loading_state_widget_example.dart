import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';

/// Example implementation showing how to use LoadingStateWidget
/// in various scenarios and with different configurations
class LoadingStateWidgetExample extends ConsumerStatefulWidget {
  const LoadingStateWidgetExample({super.key});

  @override
  ConsumerState<LoadingStateWidgetExample> createState() =>
      _LoadingStateWidgetExampleState();
}

class _LoadingStateWidgetExampleState
    extends ConsumerState<LoadingStateWidgetExample> {
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isButtonLoading = false;
  String _currentExample = 'basic';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LoadingStateWidget Examples'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Example Selection
            _buildExampleSelector(theme),
            const SizedBox(height: 24),

            // Current Example Display
            _buildCurrentExample(theme),
            const SizedBox(height: 32),

            // Control Buttons
            _buildControlButtons(theme),
            const SizedBox(height: 32),

            // Static Examples
            _buildStaticExamples(theme),
          ],
        ),
      ),
    );
  }

  /// Builds the example selector dropdown
  Widget _buildExampleSelector(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Example:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _currentExample,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'basic', child: Text('Basic Loading')),
                DropdownMenuItem(
                  value: 'compact',
                  child: Text('Compact Loading'),
                ),
                DropdownMenuItem(
                  value: 'custom',
                  child: Text('Custom Color & Size'),
                ),
                DropdownMenuItem(
                  value: 'overlay',
                  child: Text('Loading Overlay'),
                ),
                DropdownMenuItem(
                  value: 'refresh',
                  child: Text('RefreshIndicator'),
                ),
                DropdownMenuItem(
                  value: 'transition',
                  child: Text('Smooth Transitions'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentExample = value;
                    _isLoading = false;
                    _isRefreshing = false;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the current example display
  Widget _buildCurrentExample(ThemeData theme) {
    return Card(
      child: Container(
        width: double.infinity,
        height: 300,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              _getExampleTitle(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildExampleContent()),
          ],
        ),
      ),
    );
  }

  /// Gets the title for the current example
  String _getExampleTitle() {
    switch (_currentExample) {
      case 'basic':
        return 'Basic Loading State';
      case 'compact':
        return 'Compact Loading State';
      case 'custom':
        return 'Custom Color & Size';
      case 'overlay':
        return 'Loading Overlay';
      case 'refresh':
        return 'RefreshIndicator Integration';
      case 'transition':
        return 'Smooth Transitions';
      default:
        return 'Loading Example';
    }
  }

  /// Builds the content for the current example
  Widget _buildExampleContent() {
    switch (_currentExample) {
      case 'basic':
        return _isLoading
            ? const LoadingStateWidget(message: 'Loading your data...')
            : const Center(child: Text('Content loaded successfully!'));

      case 'compact':
        return _isLoading
            ? const LoadingStateWidget(message: 'Loading...', compact: true)
            : const Center(child: Text('Compact loading completed!'));

      case 'custom':
        return _isLoading
            ? const LoadingStateWidget(
              message: 'Processing with custom styling...',
              color: Colors.purple,
              size: 48.0,
            )
            : const Center(child: Text('Custom styled loading finished!'));

      case 'overlay':
        return LoadingStateHelper.createLoadingOverlay(
          isLoading: _isLoading,
          loadingMessage: 'Processing overlay...',
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          indicatorColor: Colors.white,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dashboard, size: 64, color: Colors.blue),
                SizedBox(height: 16),
                Text('Dashboard Content'),
                Text('This content is overlaid during loading'),
              ],
            ),
          ),
        );

      case 'refresh':
        return LoadingStateHelper.createRefreshIndicator(
          onRefresh: _simulateRefresh,
          child: ListView(
            children: [
              const ListTile(
                leading: Icon(Icons.person),
                title: Text('User 1'),
                subtitle: Text('user1@example.com'),
              ),
              const ListTile(
                leading: Icon(Icons.person),
                title: Text('User 2'),
                subtitle: Text('user2@example.com'),
              ),
              const ListTile(
                leading: Icon(Icons.person),
                title: Text('User 3'),
                subtitle: Text('user3@example.com'),
              ),
              if (_isRefreshing)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: LoadingStateWidget(
                    message: 'Refreshing users...',
                    compact: true,
                  ),
                ),
            ],
          ),
        );

      case 'transition':
        return const Text('Content').withLoadingTransition(
          isLoading: _isLoading,
          loadingMessage: 'Smooth transition loading...',
          transitionDuration: const Duration(milliseconds: 500),
        );

      default:
        return const Center(child: Text('Select an example above'));
    }
  }

  /// Builds control buttons for testing the examples
  Widget _buildControlButtons(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controls:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _toggleLoading,
                  child: Text(_isLoading ? 'Stop Loading' : 'Start Loading'),
                ),
                LoadingStateHelper.createLoadingButton(
                  text: 'Submit',
                  onPressed: _simulateButtonAction,
                  isLoading: _isButtonLoading,
                  loadingText: 'Submitting...',
                  icon: Icons.send,
                ),
                OutlinedButton(
                  onPressed: _resetAll,
                  child: const Text('Reset All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds static examples showing different configurations
  Widget _buildStaticExamples(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Static Examples:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Factory constructors examples
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Full Screen'),
                      const SizedBox(height: 8),
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: LoadingStateWidget.fullScreen(
                          message: 'Loading app...',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Inline'),
                      const SizedBox(height: 8),
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: LoadingStateWidget.inline(
                          message: 'Inline loading...',
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Custom indicator example
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const LoadingStateWidget(
                message: 'Custom indicator loading...',
                customIndicator: Icon(
                  Icons.hourglass_empty,
                  size: 32,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggles the loading state
  void _toggleLoading() {
    setState(() {
      _isLoading = !_isLoading;
    });
  }

  /// Simulates a button action with loading state
  Future<void> _simulateButtonAction() async {
    setState(() {
      _isButtonLoading = true;
    });

    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isButtonLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Simulates refresh action
  Future<void> _simulateRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate refresh delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  /// Resets all loading states
  void _resetAll() {
    setState(() {
      _isLoading = false;
      _isRefreshing = false;
      _isButtonLoading = false;
    });
  }
}
