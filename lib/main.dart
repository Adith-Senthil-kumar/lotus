import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotus/navigation_bloc.dart';
import 'package:lotus/navigation_event.dart';
import 'package:lotus/navigation_state.dart';
import 'firebase_options.dart';
import 'tenant_page.dart';
import 'rooms_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(LotusApp());
}

class LotusApp extends StatefulWidget {
  @override
  _LotusAppState createState() => _LotusAppState();
}

class _LotusAppState extends State<LotusApp> {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  // Function to toggle the theme
  void _toggleTheme(bool value) {
    setState(() {
      _themeMode = value ? ThemeMode.dark : ThemeMode.light; // Toggle theme
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lotus',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.pink, // Pink as the primary color
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white, // White AppBar for light theme
          foregroundColor: Colors.pink, // Pink text/icons
          elevation: 2, // Light shadow
        ),
        scaffoldBackgroundColor: Colors.white, // White background
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.black87),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.pink, // Pink as the primary color
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black, // Black AppBar for dark theme
          foregroundColor: Colors.pink, // Pink text/icons
          elevation: 2, // Light shadow
        ),
        scaffoldBackgroundColor: Colors.black, // Black background
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.white70),
        ),
      ),
      themeMode: _themeMode, // Use the themeMode that is set
      home: NavigationPage(
          toggleTheme: _toggleTheme), // Pass toggleTheme to NavigationPage
    );
  }
}

class NavigationPage extends StatefulWidget {
  final Function(bool) toggleTheme;

  NavigationPage({required this.toggleTheme});

  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int _selectedIndex = 0;

  // List of pages to switch between
  List<Widget> _pages = [
    TenantPage(),
    RoomsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lotus'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Opens the drawer
            },
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            // Switch Theme option in the menu
            SwitchListTile(
              title: Text('Dark Mode'),
              value: Theme.of(context).brightness ==
                  Brightness.dark, // Check if the current theme is dark
              onChanged:
                  widget.toggleTheme, // Toggle theme when the switch is changed
              activeColor: Theme.of(context)
                  .primaryColor, // Pink color for the switch when active
            ),
            ListTile(
              title: Text('Download'),
              onTap: () {
                downloadTenantsCollection();
                Navigator.pop(context); // Close the drawer
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex], // Show the selected page content
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Handle tap on bottom navigation
        selectedItemColor:
            Theme.of(context).primaryColor, // Highlight selected item in pink
        unselectedItemColor: const Color.fromARGB(
            108, 233, 30, 98), // Set color for unselected items (light gray)
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tenants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.door_back_door),
            label: 'Rooms',
          ),
        ],
      ),
    );
  }
}

Future<void> downloadTenantsCollection() async {
  try {
    const String collectionName = 'tenants';

    // Fetch documents from Firestore collection
    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance.collection(collectionName).get();

    if (querySnapshot.docs.isEmpty) {
      print('No data found in the tenants collection.');
      return;
    }

    // Convert documents to CSV format
    List<List<dynamic>> csvData = [];
    List<String> headers = [];

    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      data['id'] = doc.id; // Add document ID

      if (headers.isEmpty) {
        headers = data.keys.toList();
        csvData.add(headers); // Add headers to CSV
      }

      List<dynamic> row = [];
      for (var header in headers) {
        var value = data[header];
        if (value is Timestamp) {
          value = value.toDate().toIso8601String();
        }
        row.add(value);
      }
      csvData.add(row);
    }

    // Convert the data to CSV format
    String csvString = const ListToCsvConverter().convert(csvData);

    // Get the downloads directory
    Directory? downloadsDir;
    if (Platform.isWindows) {
      downloadsDir =
          Directory('${Platform.environment['USERPROFILE']}\\Downloads');
    } else {
      downloadsDir = await getExternalStorageDirectory(); // Android path
    }

    if (downloadsDir == null) {
      print('Error: Could not get downloads directory.');
      return;
    }

    final file = File('${downloadsDir.path}/$collectionName.csv');
    await file.writeAsString(csvString);

    print('Tenants collection downloaded successfully as CSV to ${file.path}');
  } catch (e) {
    print('Error downloading tenants collection: $e');
  }
}
