import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/widgets/purple_sidebar.dart';
import 'core/widgets/hamburger_menu_button.dart';
import 'core/widgets/search_dropdown.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/home/presentation/pages/home_screen.dart';
import 'features/profile/presentation/pages/profile_screen.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'core/models/content_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize services
  await StorageService.init();
  await ApiService.init();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Force dark theme for glassmorphism
      home: authState.when(
        data: (user) => user != null 
            ? const MainNavigationScreen() 
            : const LoginScreen(),
        loading: () => const SplashScreen(),
        error: (error, stack) => const LoginScreen(),
      ),
      routes: {
        '/main': (context) => const MainNavigationScreen(),
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isSidebarOpen = false;
  
  // Search functionality
  final ApiService _apiService = ApiService();
  List<ContentItem> _searchResults = [];
  bool _isSearching = false;
  String _currentSearchQuery = '';
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const ProfileScreen(),
  ];

  final List<String> _screenTitles = [
    'Home',
    'Profile',
  ];

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _currentSearchQuery = '';
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _currentSearchQuery = query;
    });

    try {
      List<ContentItem> searchResults = [];
      
      // Search across all platforms
      final youtubeResult = await _apiService.searchYouTubeContent(query: query);
      if (youtubeResult.isSuccess && youtubeResult.data != null) {
        searchResults.addAll(youtubeResult.data!);
      }

      final tmdbResult = await _apiService.searchTMDBContent(query: query);
      if (tmdbResult.isSuccess && tmdbResult.data != null) {
        searchResults.addAll(tmdbResult.data!);
      }

      final spotifyResult = await _apiService.searchSpotifyContent(query: query);
      if (spotifyResult.isSuccess && spotifyResult.data != null) {
        searchResults.addAll(spotifyResult.data!);
      }

      setState(() {
        _searchResults = searchResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Main Content Area
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppTheme.backgroundGradient,
              ),
            ),
            child: Column(
              children: [
                // Top App Bar with Hamburger Menu and Search
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      HamburgerMenuButton(
                        onTap: _toggleSidebar,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _screenTitles[_currentIndex],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: SearchDropdown(
                            onSearch: _performSearch,
                            searchResults: _searchResults,
                            isLoading: _isSearching,
                            query: _currentSearchQuery,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          ),
          
          // Backdrop
          if (_isSidebarOpen)
            GestureDetector(
              onTap: _toggleSidebar,
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          
          // Purple Sidebar
          PurpleSidebar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            isOpen: _isSidebarOpen,
            onClose: _toggleSidebar,
          ),
        ],
      ),
    );
  }
}

