import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location_sharing_screen.dart';

void main() {
  runApp(const LiveLocationApp());
}

class LiveLocationApp extends StatefulWidget {
  const LiveLocationApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LiveLocationAppState();
  }
}

class _LiveLocationAppState extends State<LiveLocationApp> {
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark theme

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? true; // Default to dark
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _updateTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Location Sharing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: _themeMode,
      home: LocationSharingScreen(onThemeChanged: _updateTheme),
      debugShowCheckedModeBanner: false,
    );
  }
}