import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/twitch_api_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TwitchClientApp());
}

class TwitchClientApp extends StatelessWidget {
  const TwitchClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => TwitchApiService(Provider.of<AuthService>(_, listen: false))),
      ],
      child: MaterialApp(
        title: 'Twitch Client',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF9146FF),
          scaffoldBackgroundColor: const Color(0xFF0E0E10),
          fontFamily: 'SF Pro',
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF9146FF),
            secondary: Color(0xFF00F5EA),
            surface: Color(0xFF18181B),
            background: Color(0xFF0E0E10),
          ),
        ),
        home: const AppStartup(),
      ),
    );
  }
}

class AppStartup extends StatelessWidget {
  const AppStartup({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<bool>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF9146FF),
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
