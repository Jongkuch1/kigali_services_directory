import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../providers/auth_provider.dart' as ap;
import '../providers/bookmarks_provider.dart';
import '../providers/listings_provider.dart';
import '../services/notification_service.dart';
import 'directory_screen.dart';
import 'map_view_screen.dart';
import 'my_listings_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<String> _titles = [
    '🏙 Directory',
    '📍 My Listings',
    '🗺 Map View',
    '⚙️ Settings',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<ap.AuthProvider>();
      final listings = context.read<ListingsProvider>();
      listings.subscribeToAllListings();
      if (auth.firebaseUser != null) {
        final uid = auth.firebaseUser!.uid;
        listings.subscribeToMyListings(uid);
        context.read<BookmarksProvider>().subscribe(uid);
        // Initialize FCM: request permission, save token, subscribe to topics
        NotificationService().initialize(uid);
      }
      // Show foreground push notifications as SnackBars
      NotificationService.listenForeground(context);
    });
  }

  @override
  void dispose() {
    context.read<ListingsProvider>().cancelSubscriptions();
    context.read<BookmarksProvider>().cancelSubscription();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DirectoryScreen(),
      const MyListingsScreen(),
      const MapViewScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
              backgroundColor: kNavyLight,
              elevation: 0,
              title: Text(
                _titles[_currentIndex],
                style: const TextStyle(
                  color: kWhite,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: kBorder, height: 1),
              ),
            ),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kNavyLight,
          border: Border(top: BorderSide(color: kBorder)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: kGold,
          unselectedItemColor: kGray,
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Directory'),
            BottomNavigationBarItem(
                icon: Icon(Icons.location_on_outlined),
                activeIcon: Icon(Icons.location_on),
                label: 'My Listings'),
            BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Map View'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
