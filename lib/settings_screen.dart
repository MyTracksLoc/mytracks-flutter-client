import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final String initialWebsocketUrl;
  final String initialUserName;
  final bool isDarkMode;
  final bool autoLocationUpdates;
  final Function(String, String, bool, bool) onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.initialWebsocketUrl,
    required this.initialUserName,
    required this.isDarkMode,
    required this.autoLocationUpdates,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _websocketController;
  late TextEditingController _userNameController;
  late bool _isDarkMode;
  late bool _autoLocationUpdates;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _websocketController = TextEditingController(text: widget.initialWebsocketUrl);
    _userNameController = TextEditingController(text: widget.initialUserName);
    _isDarkMode = widget.isDarkMode;
    _autoLocationUpdates = widget.autoLocationUpdates;
  }

  @override
  void dispose() {
    _websocketController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      widget.onSettingsChanged(
        _websocketController.text.trim(),
        _userNameController.text.trim(),
        _isDarkMode,
        _autoLocationUpdates,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    }
  }

  String? _validateWebSocketUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a WebSocket URL';
    }

    final trimmed = value.trim();
    if (!trimmed.startsWith('ws://') && !trimmed.startsWith('wss://')) {
      return 'URL must start with ws:// or wss://';
    }

    try {
      Uri.parse(trimmed);
    } catch (e) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  String? _validateUserName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a user name';
    }

    if (value.trim().length < 2) {
      return 'User name must be at least 2 characters';
    }

    if (value.trim().length > 20) {
      return 'User name must be less than 20 characters';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Server Configuration Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.dns, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Server Configuration',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _websocketController,
                      validator: _validateWebSocketUrl,
                      decoration: const InputDecoration(
                        labelText: 'WebSocket Server URL',
                        hintText: 'ws://example.com:8080/ws',
                        prefixIcon: Icon(Icons.link),
                        border: OutlineInputBorder(),
                        helperText: 'Enter the WebSocket server URL (ws:// or wss://)',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // User Configuration Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'User Configuration',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _userNameController,
                      validator: _validateUserName,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        hintText: 'Enter your name',
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                        helperText: 'Name shown to other users (2-20 characters)',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Appearance Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Appearance',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: Text(_isDarkMode ? 'Dark theme enabled' : 'Light theme enabled'),
                      value: _isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          _isDarkMode = value;
                        });
                      },
                      secondary: Icon(
                        _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Location Sharing Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Location Sharing',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Auto Location Updates'),
                      subtitle: Text(
                        _autoLocationUpdates
                            ? 'Sharing location every 5 seconds (battery intensive)'
                            : 'Manual sharing only (battery friendly)',
                      ),
                      value: _autoLocationUpdates,
                      onChanged: (value) {
                        setState(() {
                          _autoLocationUpdates = value;
                        });
                      },
                      secondary: Icon(
                        _autoLocationUpdates ? Icons.timer : Icons.timer_off,
                        color: _autoLocationUpdates ? Colors.orange : Colors.grey,
                      ),
                    ),
                    if (!_autoLocationUpdates)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Use the send button (📤) in the app to share your location manually',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Example URLs
            Card(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Example Server URLs',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildExampleUrl('Local development:', 'ws://localhost:8080/ws'),
                    _buildExampleUrl('Secure server:', 'wss://myserver.com/ws'),
                    _buildExampleUrl('With port:', 'ws://192.168.1.100:3000/ws'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleUrl(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              url,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              _websocketController.text = url;
            },
            tooltip: 'Copy to field',
          ),
        ],
      ),
    );
  }
}