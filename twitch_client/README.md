# Twitch Client

A modern, cross-platform Twitch client built with Flutter that works on both Web and iOS. Features Apple Liquid Glass design and native Picture-in-Picture (PiP) support for video playback.

## Features

### Core Functionality
- 🔐 **Twitch OAuth 2.0 Authentication** - Secure login with Twitch
- 📺 **Live Stream Viewing** - Watch live streams with real-time chat
- 📹 **Video On Demand (VOD)** - Browse and watch past broadcasts, uploads, and highlights
- ❤️ **Subscriptions Management** - View your followed channels and subscriptions
- 💬 **Real-time Chat** - Integrated IRC chat with WebSocket support

### Design & UX
- 🎨 **Apple Liquid Glass Design** - Beautiful glassmorphism UI effects
- 🌙 **Dark Theme** - Twitch-inspired dark color scheme
- 📱 **Responsive Layout** - Optimized for both mobile and web
- 🔄 **Smooth Animations** - Fluid transitions and interactions

### Video Features
- 🎬 **Native PiP Support** - Picture-in-Picture mode for iOS
- ⏯️ **Advanced Player Controls** - Full video player functionality
- 📊 **Quality Selection** - Adaptive streaming quality
- 🖼️ **Auto-Rotation** - Landscape/portrait mode switching

## Project Structure

```
twitch_client/
├── lib/
│   ├── config/           # App configuration
│   │   └── twitch_config.dart
│   ├── models/           # Data models
│   │   └── twitch_models.dart
│   ├── services/         # Business logic & API
│   │   ├── auth_service.dart
│   │   ├── twitch_api_service.dart
│   │   └── chat_service.dart
│   ├── screens/          # UI screens
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── streams_screen.dart
│   │   ├── stream_player_screen.dart
│   │   ├── subscriptions_screen.dart
│   │   └── videos_screen.dart
│   ├── widgets/          # Reusable components
│   │   └── glass_button.dart
│   └── main.dart         # App entry point
├── ios/                  # iOS-specific code
├── web/                  # Web-specific code
└── pubspec.yaml          # Dependencies
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Xcode (for iOS builds)
- Twitch Developer Account

### 1. Clone the Repository
```bash
cd /workspace/twitch_client
```

### 2. Configure Twitch API Credentials

Open `lib/config/twitch_config.dart` and replace the placeholder values:

```dart
static const String clientId = 'YOUR_TWITCH_CLIENT_ID';
static const String clientSecret = 'YOUR_TWITCH_CLIENT_SECRET';
static const String redirectUri = 'twitchclient://auth/callback';
```

To get these credentials:
1. Go to [Twitch Developer Console](https://dev.twitch.tv/console)
2. Register a new application
3. Set the OAuth Redirect URL to `twitchclient://auth/callback`
4. Copy your Client ID and Client Secret

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run on Web
```bash
flutter run -d chrome
```

### 5. Run on iOS
```bash
flutter run -d <device_id>
```

## Building for Production

### Web Build
```bash
flutter build web --release
```

### iOS Build (IPA)
```bash
flutter build ios --release
```

Then open in Xcode to archive and export IPA:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Product → Archive
3. Export as IPA for distribution

## Configuration

### iOS Specific Settings

For Picture-in-Picture support, add to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>remote-notification</string>
</array>
```

### Web Specific Settings

For web deployment, configure CORS and update `web/index.html` with proper meta tags.

## Architecture

The app follows a clean architecture pattern:

- **Models**: Data structures (User, Stream, Video, ChatMessage)
- **Services**: Business logic (Auth, API, Chat)
- **Screens**: UI pages
- **Widgets**: Reusable components
- **Config**: App settings and constants

State management is handled using Provider for reactive UI updates.

## API Integration

### Twitch Helix API
- Streams endpoint for live content
- Videos endpoint for VODs
- Users endpoint for profile data
- Subscriptions endpoint for followed channels

### Twitch IRC
- WebSocket connection for real-time chat
- OAuth token authentication
- Channel join/part commands

## Customization

### Theme Colors
Modify in `lib/main.dart`:
```dart
primaryColor: Color(0xFF9146FF), // Twitch purple
secondaryColor: Color(0xFF00F5EA), // Cyan accent
```

### Glass Effect
Adjust blur and opacity in `lib/widgets/glass_button.dart`

## Troubleshooting

### Common Issues

1. **OAuth Login Fails**
   - Verify redirect URI matches exactly
   - Check Client ID and Secret
   - Ensure required scopes are requested

2. **Streams Not Loading**
   - Verify API credentials
   - Check network connectivity
   - Review Twitch API rate limits

3. **Chat Not Connecting**
   - Ensure user is authenticated
   - Check WebSocket connection
   - Verify channel name format

## Development Status

This is a foundational implementation. For production use, consider:

- [ ] Implementing actual HTTP requests in services
- [ ] Adding error handling and retry logic
- [ ] Implementing caching strategies
- [ ] Adding push notifications
- [ ] Enhancing security measures
- [ ] Complete PiP native implementation
- [ ] Add search functionality
- [ ] Implement channel pages
- [ ] Add emote support in chat
- [ ] Implement clips viewing

## License

This project is for educational purposes. Please comply with Twitch's Terms of Service and API guidelines.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

---

Built with ❤️ using Flutter
