import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/twitch_api_service.dart';
import '../services/chat_service.dart';
import 'streams_screen.dart';
import 'subscriptions_screen.dart';
import 'videos_screen.dart';

/// Main home screen with bottom navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const StreamsScreen(),
    const SubscriptionsScreen(),
    const VideosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF18181B).withOpacity(0.8),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.live_tv,
                    label: 'Streams',
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.favorite,
                    label: 'Subscriptions',
                    index: 1,
                  ),
                  _buildNavItem(
                    icon: Icons.video_library,
                    label: 'Videos',
                    index: 2,
                  ),
                  _buildNavItem(
                    icon: Icons.person,
                    label: user?.displayName ?? 'Profile',
                    index: 3,
                    isProfile: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isProfile = false,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (isProfile) {
          _showProfileMenu();
        } else {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF9146FF)
                  : Colors.white54,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label.length > 12 ? '${label.substring(0, 10)}...' : label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF9146FF)
                    : Colors.white54,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF18181B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF9146FF),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authService.currentUser?.displayName ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '@${authService.currentUser?.login ?? "user"}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      authService.logout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
