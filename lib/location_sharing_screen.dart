import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:live_location_share/settings_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

import 'user.dart';

class LocationSharingScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const LocationSharingScreen({super.key, required this.onThemeChanged});


  @override
  State<LocationSharingScreen> createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends State<LocationSharingScreen> {
  GoogleMapController? _mapController;
  WebSocketChannel? _channel;
  Position? _currentPosition;
  String _userId = const Uuid().v4();
  String _userName = 'User';

  Map<String, User> _connectedUsers = {};
  Set<Marker> _markers = {};
  Timer? _locationTimer;
  bool _isConnected = false;
  bool _permissionGranted = false;
  String _websocketUrl = '';
  bool _isDarkMode = true;
  bool _autoLocationUpdates = false; // Default to false to save battery

  // Replace with your WebSocket server URL

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeApp();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _websocketUrl = prefs.getString('websocket_url') ?? '';
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      _autoLocationUpdates = prefs.getBool('autoLocationUpdates') ?? false;
      _userName = prefs.getString('user_name') ?? 'User${_userId.substring(0, 4)}';
    });
  }

  Future<void> _saveSettings({String? websocketUrl, bool? isDarkMode, String? userName, bool? autoLocationUpdates}) async {
    final prefs = await SharedPreferences.getInstance();
    if (websocketUrl != null) {
      await prefs.setString('websocket_url', websocketUrl);
    }
    if (isDarkMode != null) {
      await prefs.setBool('isDarkMode', isDarkMode);
    }
    if (userName != null) {
      await prefs.setString('user_name', userName);
    }
    if (autoLocationUpdates != null) {
      await prefs.setBool('autoLocationUpdates', autoLocationUpdates);
    }
  }

  Future<void> _initializeApp() async {
    await _requestPermissions();
    if (_permissionGranted) {
      await _getCurrentLocation();
      _connectWebSocket();
      if (_autoLocationUpdates) {
        _startLocationUpdates();
      }
    }
  }

  Future<void> _requestPermissions() async {
    final locationPermission = await Permission.location.request();

    if (locationPermission.isGranted) {
      _permissionGranted = true;
    } else {
      setState(() {
        _permissionGranted = false;
      });
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'This app needs location permission to share your location with others. Please grant permission in settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermissions();
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_websocketUrl));

      _channel!.stream.listen(
            (data) {
          _handleWebSocketMessage(data);
        },
        onError: (error) {
          print('WebSocket error: $error');
          setState(() {
            _isConnected = false;
          });
          _reconnectWebSocket();
        },
        onDone: () {
          print('WebSocket connection closed');
          setState(() {
            _isConnected = false;
          });
          _reconnectWebSocket();
        },
      );

      setState(() {
        _isConnected = true;
      });

      // Send initial location if available
      if (_currentPosition != null) {
        _sendLocationUpdate();
      }
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _reconnectWebSocket();
    }
  }

  void _reconnectWebSocket() {
    Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        _connectWebSocket();
      }
    });
  }

  void _handleWebSocketMessage(dynamic data) {
    try {
      final message = json.decode(data);

      switch (message['type']) {
        case 'user_location':
          final user = User.fromJson(message['data']);
          if (user.id != _userId) {
            setState(() {
              _connectedUsers[user.id] = user;
            });
            _updateMarkers();
          }
          break;

        case 'user_disconnected':
          final userId = message['data']['id'];
          setState(() {
            _connectedUsers.remove(userId);
          });
          _updateMarkers();
          break;

        case 'users_list':
          final users = message['data'] as List;
          setState(() {
            _connectedUsers.clear();
            for (var userData in users) {
              final user = User.fromJson(userData);
              if (user.id != _userId) {
                _connectedUsers[user.id] = user;
              }
            }
          });
          _updateMarkers();
          break;
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  void _sendLocationUpdate() {
    if (_channel != null && _currentPosition != null && _isConnected) {
      final user = User(
        id: _userId,
        name: _userName,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        lastUpdate: DateTime.now(),
      );

      final message = {
        'type': 'location_update',
        'data': user.toJson(),
      };

      _channel!.sink.add(json.encode(message));
    }
  }

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    if (_autoLocationUpdates) {
      _locationTimer =
          Timer.periodic(const Duration(seconds: 5), (timer) async {
            await _getCurrentLocation();
            _sendLocationUpdate();
          });
    }
  }

  void _sendLocationNow() async {
    await _getCurrentLocation();
    _sendLocationUpdate();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.send, color: Colors.white),
              SizedBox(width: 8),
              Text('Location sent successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _updateMarkers() {
    final newMarkers = <Marker>{};

    // Add current user marker
    if (_currentPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_user'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'You ($_userName)',
            snippet: 'Current location',
          ),
        ),
      );
    }

    // Add other users markers
    for (final user in _connectedUsers.values) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(user.id),
          position: LatLng(user.latitude, user.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: user.name,
            snippet: 'Last updated: ${_formatTime(user.lastUpdate)}',
          ),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Move camera to current location if available
    if (_currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0,
        ),
      );
    }
  }

  void _centerOnCurrentLocation() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0,
        ),
      );
    }
  }

  void _centerOnUser(User user) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(user.latitude, user.longitude),
          15.0,
        ),
      );
    }
  }

  void _showUsersList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Connected Users (${_connectedUsers.length + 1})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Current User
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text('$_userName (You)'),
                subtitle: const Text('Current location'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _autoLocationUpdates ? Icons.timer : Icons.timer_off,
                      size: 16,
                      color: _autoLocationUpdates ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _autoLocationUpdates ? 'Auto' : 'Manual',
                      style: TextStyle(
                        fontSize: 12,
                        color: _autoLocationUpdates ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _centerOnCurrentLocation();
                },
              ),

              // Other Users
              if (_connectedUsers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Other Users',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _connectedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _connectedUsers.values.toList()[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(user.name),
                        subtitle: Text('Last seen: ${_formatTime(user.lastUpdate)}'),
                        trailing: const Icon(Icons.location_on, color: Colors.red),
                        onTap: () {
                          Navigator.of(context).pop();
                          _centerOnUser(user);

                          // Show a brief message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Focused on ${user.name}\'s location'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No other users online',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share your server URL with friends to see them here',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _centerOnCurrentLocation();
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('My Location'),
                  ),
                  if (_connectedUsers.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showAllUsersOnMap();
                      },
                      icon: const Icon(Icons.zoom_out_map),
                      label: const Text('Show All'),
                    ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAllUsersOnMap() {
    if (_mapController == null) return;

    List<LatLng> allPositions = [];

    // Add current user position
    if (_currentPosition != null) {
      allPositions.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
    }

    // Add other users positions
    for (final user in _connectedUsers.values) {
      allPositions.add(LatLng(user.latitude, user.longitude));
    }

    if (allPositions.isEmpty) return;

    if (allPositions.length == 1) {
      // If only one position, center on it
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(allPositions.first, 15.0),
      );
    } else {
      // Calculate bounds to show all users
      double minLat = allPositions.first.latitude;
      double maxLat = allPositions.first.latitude;
      double minLng = allPositions.first.longitude;
      double maxLng = allPositions.first.longitude;

      for (final position in allPositions) {
        minLat = minLat < position.latitude ? minLat : position.latitude;
        maxLat = maxLat > position.latitude ? maxLat : position.latitude;
        minLng = minLng < position.longitude ? minLng : position.longitude;
        maxLng = maxLng > position.longitude ? maxLng : position.longitude;
      }

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100.0, // padding
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Showing all users on map'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          initialWebsocketUrl: _websocketUrl,
          initialUserName: _userName,
          isDarkMode: _isDarkMode,
          autoLocationUpdates: _autoLocationUpdates,
          onSettingsChanged: (websocketUrl, userName, isDarkMode, autoLocationUpdates) async {
            await _saveSettings(
              websocketUrl: websocketUrl,
              userName: userName,
              isDarkMode: isDarkMode,
              autoLocationUpdates: autoLocationUpdates,
            );

            setState(() {
              _websocketUrl = websocketUrl;
              _userName = userName;
              _isDarkMode = isDarkMode;
              _autoLocationUpdates = autoLocationUpdates;
            });

            widget.onThemeChanged(isDarkMode);

            // Reconnect with new settings
            if (_permissionGranted && _currentPosition != null) {
              _connectWebSocket();
              if (_autoLocationUpdates) {
                _startLocationUpdates();
              } else {
                _locationTimer?.cancel(); // Stop auto updates if disabled
              }
            }
          },
        ),
      ),
    );
  }


  @override
  void dispose() {
    _locationTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionGranted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Location Sharing'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettings,
            ),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Location permission required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please grant location permission to use this app',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentPosition == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Location Sharing'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettings,
            ),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Getting your location...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location Sharing'),
        actions: [
          // Send Location Now Button
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isConnected && _websocketUrl.isNotEmpty
                ? _sendLocationNow
                : null,
            tooltip: 'Send location now',
          ),
          IconButton(
            icon: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: () {
              String message;
              if (_websocketUrl.isEmpty) {
                message = 'No server configured. Go to settings to add a server.';
              } else {
                message = _isConnected
                    ? 'Connected to $_websocketUrl'
                    : 'Disconnected from $_websocketUrl';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: _isConnected && _websocketUrl.isNotEmpty
                      ? Colors.green
                      : Colors.red,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              zoom: 15.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),


              child: InkWell(
                onTap: _showUsersList,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_connectedUsers.length + 1} users online${_autoLocationUpdates ? ' • Auto-sharing' : ' • Manual sharing'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isConnected && _websocketUrl.isNotEmpty
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          if (_websocketUrl.isEmpty)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No server configured. Tap settings to add a WebSocket server.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: _openSettings,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),


      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}