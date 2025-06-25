import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/utils/http_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerSettingsDialog extends ConsumerStatefulWidget {
  final void Function()? onSaved;
  const ServerSettingsDialog({Key? key, this.onSaved}) : super(key: key);

  @override
  ConsumerState<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends ConsumerState<ServerSettingsDialog> {
  TextEditingController? domainController;
  TextEditingController newServerController = TextEditingController();
  String? errorText;
  String preview = '';
  bool testSuccess = false;
  bool testing = false;
  bool showAddNewField = false;

  List<String> savedServers = [];
  String? selectedServer;

  @override
  void initState() {
    super.initState();
    _loadSavedServers();
  }

  Future<void> _loadSavedServers() async {
    final prefs = await SharedPreferences.getInstance();
    final servers = prefs.getStringList('saved_servers') ?? ['dev-app-sbd.rohanbatra.in'];
    setState(() {
      savedServers = servers.toSet().toList();
      if (domainController != null && savedServers.contains(domainController!.text.trim())) {
        selectedServer = domainController!.text.trim();
      } else {
        selectedServer = savedServers.isNotEmpty ? savedServers[0] : null;
      }
    });
  }

  Future<void> _saveServersList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_servers', savedServers);
  }

  void _addCurrentDomainToServers() async {
    final domain = domainController?.text.trim() ?? '';
    if (domain.isNotEmpty && !savedServers.contains(domain)) {
      setState(() {
        savedServers.add(domain);
        selectedServer = domain;
      });
      await _saveServersList();
    }
  }

  void _removeServer(String server) async {
    // Prevent deleting the default server
    if (server == 'dev-app-sbd.rohanbatra.in') return;
    setState(() {
      savedServers.remove(server);
      if (selectedServer == server) {
        selectedServer = savedServers.isNotEmpty ? savedServers[0] : null;
        if (selectedServer != null) {
          domainController?.text = selectedServer!;
        }
      }
    });
    await _saveServersList();
  }

  @override
  void dispose() {
    domainController?.dispose();
    newServerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final protocol = ref.watch(serverProtocolProvider);
    final domain = ref.watch(serverDomainProvider);
    final healthCheckUrl = ref.watch(healthCheckEndpointProvider);
    domainController ??= TextEditingController(text: domain);
    preview = '$protocol://${domainController!.text.trim().isEmpty ? 'dev-app-sbd.rohanbatra.in' : domainController!.text.trim()}';

    final currentDomain = domainController!.text.trim().isEmpty ? 'dev-app-sbd.rohanbatra.in' : domainController!.text.trim();
    final showUptimeButton = currentDomain.contains('rohanbatra.in');

    return AlertDialog(
      backgroundColor: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Padding(
        padding: const EdgeInsets.only(top: 12, left: 4, right: 4, bottom: 0),
        child: Text('Server Configuration', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Protocol', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Switch.adaptive(
                      value: protocol == 'https',
                      activeColor: theme.primaryColor,
                      inactiveThumbColor: theme.cardColor,
                      inactiveTrackColor: theme.dividerColor.withOpacity(0.2),
                      onChanged: (val) {
                        ref.read(serverProtocolProvider.notifier).setProtocol(val ? 'https' : 'http');
                      },
                    ),
                    Text(protocol == 'https' ? 'HTTPS' : 'HTTP', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text('Domain/IP', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      showAddNewField = true;
                      newServerController.clear();
                      errorText = null;
                      testSuccess = false;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size(0, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '+ Add new',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (showAddNewField)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: newServerController,
                    decoration: InputDecoration(
                      hintText: 'Enter new server domain/IP',
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                    style: theme.textTheme.bodyMedium,
                    onChanged: (val) {
                      setState(() {
                        errorText = null;
                        testSuccess = false;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: testing
                              ? null
                              : () async {
                                  setState(() { testing = true; errorText = null; });
                                  final inputDomain = newServerController.text.trim();
                                  final domainError = InputValidator.validateDomain(inputDomain);
                                  if (domainError != null) {
                                    setState(() {
                                      testSuccess = false;
                                      errorText = domainError;
                                      testing = false;
                                    });
                                    return;
                                  }
                                  final url = healthCheckUrl.replaceFirst(domain, inputDomain.isEmpty ? 'dev-app-sbd.rohanbatra.in' : inputDomain);
                                  try {
                                    final response = await HttpUtil.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
                                    if (response.statusCode == 200) {
                                      setState(() {
                                        testSuccess = true;
                                        errorText = null;
                                        testing = false;
                                      });
                                    } else {
                                      setState(() {
                                        testSuccess = false;
                                        errorText = 'Server responded, but health check failed (code: ${response.statusCode}). Please check your server.';
                                        testing = false;
                                      });
                                    }
                                  } catch (e) {
                                    setState(() {
                                      testSuccess = false;
                                      if (e is CloudflareTunnelException) {
                                        errorText = 'Cloudflare tunnel is down: ${e.message}';
                                      } else if (e is NetworkException) {
                                        errorText = 'Network error: ${e.message}';
                                      } else {
                                        errorText = 'Could not connect. Please check your network or server address.';
                                      }
                                      testing = false;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                          ),
                          child: testing
                              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
                              : const Text('Test Connection'),
                        ),
                      ),
                    ],
                  ),
                  if (testSuccess)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Connection successful', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green)),
                          ),
                          TextButton(
                            onPressed: () async {
                              final newDomain = newServerController.text.trim();
                              setState(() {
                                savedServers.add(newDomain);
                                showAddNewField = false;
                                domainController!.text = newDomain;
                                selectedServer = newDomain;
                              });
                              await _saveServersList();
                            },
                            child: Text('Save', style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                showAddNewField = false;
                                errorText = null;
                                testSuccess = false;
                              });
                            },
                            child: Text('Cancel', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                          ),
                        ],
                      ),
                    ),
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(errorText!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                    ),
                ],
              ),
            if (!showAddNewField) ...[
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: savedServers.contains(domainController!.text.trim()) ? domainController!.text.trim() : null,
                      selectedItemBuilder: (context) => savedServers.map((server) => Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          child: Text(
                            server,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )).toList(),
                      items: savedServers.map((server) => DropdownMenuItem(
                        value: server,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: domainController!.text.trim() == server
                                ? theme.primaryColor.withOpacity(0.10)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cloud,
                                color: domainController!.text.trim() == server
                                    ? theme.primaryColor
                                    : theme.iconTheme.color?.withOpacity(0.7),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  server,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: domainController!.text.trim() == server
                                        ? theme.primaryColor
                                        : theme.textTheme.bodyMedium?.color,
                                    fontWeight: domainController!.text.trim() == server ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (domainController!.text.trim() == server)
                                Icon(Icons.check, color: theme.primaryColor, size: 18),
                            ],
                          ),
                        ),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            domainController!.text = val;
                            selectedServer = val;
                            errorText = null;
                            testSuccess = false;
                          });
                        }
                      },
                      dropdownColor: theme.cardColor,
                      style: theme.textTheme.bodyMedium,
                      icon: (savedServers.contains(domainController!.text.trim()) && domainController!.text.trim() != 'dev-app-sbd.rohanbatra.in')
                        ? Padding(
                            padding: const EdgeInsets.only(right: 36.0), // shift arrow left when delete icon is visible
                            child: Icon(Icons.arrow_drop_down_rounded, color: theme.primaryColor, size: 28),
                          )
                        : Icon(Icons.arrow_drop_down_rounded, color: theme.primaryColor, size: 28),
                      decoration: InputDecoration(
                        hintText: 'dev-app-sbd.rohanbatra.in',
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                      ),
                      menuMaxHeight: 320,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  if (savedServers.contains(domainController!.text.trim()) && domainController!.text.trim() != 'dev-app-sbd.rohanbatra.in')
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.delete, color: theme.colorScheme.error),
                        tooltip: 'Remove server',
                        onPressed: () => _removeServer(domainController!.text.trim()),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Preview: $preview', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: showUptimeButton ? 2 : 1,
                    child: ElevatedButton(
                      onPressed: testing
                          ? null
                          : () async {
                              setState(() { testing = true; errorText = null; });
                              final inputDomain = domainController!.text.trim();
                              final domainError = InputValidator.validateDomain(inputDomain);
                              if (domainError != null) {
                                setState(() {
                                  testSuccess = false;
                                  errorText = domainError;
                                  testing = false;
                                });
                                return;
                              }
                              final url = healthCheckUrl.replaceFirst(domain, inputDomain.isEmpty ? 'dev-app-sbd.rohanbatra.in' : inputDomain);
                              try {
                                final response = await HttpUtil.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
                                if (response.statusCode == 200) {
                                  setState(() {
                                    testSuccess = true;
                                    errorText = null;
                                    testing = false;
                                  });
                                } else {
                                  setState(() {
                                    testSuccess = false;
                                    errorText = 'Server responded, but health check failed (code: ${response.statusCode}). Please check your server.';
                                    testing = false;
                                  });
                                }
                              } catch (e) {
                                setState(() {
                                  testSuccess = false;
                                  if (e is CloudflareTunnelException) {
                                    errorText = 'Cloudflare tunnel is down: ${e.message}';
                                  } else if (e is NetworkException) {
                                    errorText = 'Network error: ${e.message}';
                                  } else {
                                    errorText = 'Could not connect. Please check your network or server address.';
                                  }
                                  testing = false;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: testing
                          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
                          : const Text('Test Connection'),
                    ),
                  ),
                  if (showUptimeButton) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: testSuccess ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.info_outline, color: theme.colorScheme.onSecondary),
                                  SizedBox(width: 8),
                                  Expanded(child: Text('Uptime monitoring screen coming soon!')),
                                ],
                              ),
                              backgroundColor: theme.colorScheme.secondary,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: testSuccess ? theme.primaryColor : theme.disabledColor,
                          side: BorderSide(color: testSuccess ? theme.primaryColor : theme.disabledColor, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: Icon(
                          Icons.timeline_rounded,
                          size: 18,
                          color: testSuccess ? theme.primaryColor : theme.disabledColor,
                        ),
                        label: Text(
                          'Uptime',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: testSuccess ? theme.primaryColor : theme.disabledColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (testSuccess)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Connection successful', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green)),
                ),
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(errorText!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: theme.textTheme.bodyLarge?.color,
            textStyle: theme.textTheme.labelLarge,
          ),
          child: const Text('Cancel'),
        ),
        if (!showAddNewField) // Hide main Save button in add-new mode
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
            onPressed: () async {
              final domain = domainController!.text.trim();
              final domainError = InputValidator.validateDomain(domain);
              if (domainError != null) {
                setState(() { errorText = domainError; });
                return;
              }
              if (!testSuccess) {
                setState(() { errorText = 'Please test connection before saving.'; });
                return;
              }
              await ref.read(serverDomainProvider.notifier).setDomain(domain);
              _addCurrentDomainToServers();
              if (widget.onSaved != null) widget.onSaved!();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: theme.colorScheme.secondary),
                      SizedBox(width: 12),
                      Text(
                        'Server settings updated successfully!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: theme.colorScheme.secondary,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
      ],
    );
  }
}
