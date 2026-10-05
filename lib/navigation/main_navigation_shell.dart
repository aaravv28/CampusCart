import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/ai_assistant/screens/ai_shopping_copilot_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/listings/screens/add_item_screen.dart';
import '../features/listings/screens/home_feed_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/search/screens/search_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    // 0: Marketplace Home
    const HomeFeedScreen(),

    // 1: Search & Multi-criteria Filter
    const SearchScreen(),

    // 2: 🤖 CartAI Conversational Shopping Copilot
    const AiShoppingCopilotScreen(),

    // 3: Sell Item
    const AddItemScreen(),

    // 4: In-App Campus Messaging
    const ChatListScreen(),

    // 5: Student Profile & Settings
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.borderLight, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primaryLight,
          onDestinationSelected: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppTheme.primaryIris),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: AppTheme.primaryIris),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.auto_awesome_outlined,
                color: AppTheme.accentPurple,
              ),
              selectedIcon: Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.primaryIris,
              ),
              label: 'CartAI',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle, color: AppTheme.primaryIris),
              label: 'Sell',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(
                Icons.chat_bubble,
                color: AppTheme.primaryIris,
              ),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppTheme.primaryIris),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
