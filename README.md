# AI-Based Content Recommendation System

A cross-platform Flutter mobile app that provides personalized content recommendations from YouTube, Spotify, and TMDB (movies/TV shows) using AI-powered mood detection and sentiment analysis.

## Features

### Core Features
- **User Authentication**: Email/password registration and login with Firebase Auth
- **Voice Mood Detection**: Real-time mood detection from voice using TensorFlow Lite (YAMNet-based model)
  - Detects 8 moods: Happy, Sad, Angry, Neutral, Fear, Surprise, Calm, Disgust
  - Supports both English and Urdu voice input
- **AI-Powered Recommendations**: OpenAI GPT integration for intelligent content suggestions
- **Mood-Based Content Filtering**: Personalized recommendations based on detected mood
- **Cross-Platform Content**: 
  - YouTube videos
  - Spotify music tracks and playlists
  - TMDB movies and TV shows
- **Chat Interface**: Interactive AI chat for content recommendations with link support
- **Content Management**:
  - Viewing history (tracks all opened content)
  - Favorites system with toggle functionality
  - Content search across all platforms
- **Smart Navigation**: Seamless user experience with automatic redirects

### Technical Stack
- **Frontend**: Flutter 3.9.2+
- **Backend Services**: 
  - Firebase Authentication
  - Firebase Firestore (for syncing history/favorites)
  - Firebase Storage
- **AI/ML**: 
  - TensorFlow Lite for voice mood detection
  - OpenAI GPT for chat and recommendations
- **APIs**: 
  - YouTube Data API v3
  - Spotify Web API
  - TMDB API
- **Local Storage**: Hive for offline data persistence

## Getting Started

### Prerequisites
- Flutter SDK 3.9.2 or higher
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Firebase project setup
- API keys for YouTube, Spotify, TMDB, and OpenAI

### Installation

1. **Clone the repository:**
```bash
git clone <repository-url>
cd AI-based-Content-Recommendation-System-1
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Set up Firebase:**
   - Create a Firebase project at https://console.firebase.google.com
   - Add your Android/iOS app to the Firebase project
   - Download and add configuration files:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Enable Storage (optional)

4. **Configure API Keys:**
   
   **OpenAI API Key:**
   - Get your API key from: https://platform.openai.com/api-keys
   - Create `lib/core/config/api_keys.dart` (copy from `api_keys.dart.example`)
   - Replace `YOUR_OPENAI_API_KEY_HERE` with your actual key
   - OR set environment variable: `flutter run --dart-define=OPENAI_API_KEY=your-key-here`

   **Other API Keys:**
   - Update API keys in `lib/core/constants/app_constants.dart`:
     - YouTube API Key
     - Spotify Client ID
     - TMDB API Key

5. **Voice Model Setup:**
   - Voice mood detection models are included in `assets/models/voice/`
   - Models are automatically loaded on first use
   - No additional setup required

6. **Run the app:**
```bash
# List available devices
flutter devices

# Run on connected device
flutter run -d <DEVICE_ID>

# Or run on default device
flutter run
```

### Connecting Your Phone

**For Android:**
1. Enable Developer Options (tap Build Number 7 times in Settings > About Phone)
2. Enable USB Debugging in Developer Options
3. Connect phone via USB
4. Accept "Allow USB debugging" prompt on phone
5. Run `adb devices` to verify connection
6. Run `flutter devices` to see your phone
7. Use `flutter run -d <DEVICE_ID>` to deploy

**For iOS:**
1. Connect iPhone via USB
2. Trust the computer when prompted
3. Run `flutter devices` to see your device
4. Use `flutter run -d <DEVICE_ID>` to deploy

## Project Structure

```
lib/
├── core/
│   ├── config/              # API keys configuration
│   ├── constants/           # App constants and API keys
│   ├── models/              # Data models (ContentItem, etc.)
│   ├── services/            # Core services
│   │   ├── api_service.dart          # YouTube, Spotify, TMDB APIs
│   │   ├── openai_service.dart       # OpenAI GPT integration
│   │   ├── history_service.dart      # Content history management
│   │   ├── favorites_service.dart    # Favorites management
│   │   ├── voice_mood_service_mobile.dart  # Voice mood detection
│   │   └── ...
│   ├── theme/               # App theming
│   └── widgets/             # Reusable widgets
├── features/
│   ├── auth/                # Authentication (login, register, password reset)
│   ├── welcome/             # Welcome screen, voice mood detection, chat
│   ├── home/                # Home screen with content cards
│   ├── recommendations/     # Mood-based recommendations
│   ├── chat/                # AI chat interface
│   ├── history/              # Viewing history
│   ├── favorites/           # Favorites management
│   ├── profile/             # User profile
│   ├── search/              # Content search
│   ├── youtube/             # YouTube recommendations
│   ├── music/               # Music recommendations
│   └── movies/              # Movies recommendations
└── main.dart                # App entry point
```

## Key Features Explained

### Voice Mood Detection
- Records audio from device microphone
- Processes audio through TensorFlow Lite YAMNet model
- Extracts mood probabilities (8 emotions)
- Uses feature-based fallback for low-confidence predictions
- Stores mood data for personalized recommendations

### AI Chat Interface
- Interactive chat with OpenAI GPT
- Understands user intent for content requests
- Provides diverse recommendations with links
- Tracks conversation context to avoid repetition
- Supports follow-up requests ("more links", "suggest more")

### Content History & Favorites
- Automatically tracks all opened content (videos, songs, movies)
- Syncs with Firebase when signed in
- Local storage for offline access
- Individual item deletion support
- Favorites toggle functionality

## API Integration

### YouTube Data API v3
- **Rate Limit**: 10,000 units/day
- **Endpoints**: Search, Videos, Channels
- **Data**: Video metadata, thumbnails, duration, categories

### Spotify Web API
- **Rate Limit**: 2,000 requests/hour
- **Authentication**: OAuth 2.0 (mocked for web compatibility)
- **Data**: Tracks, albums, artists, playlists

### TMDB API
- **Rate Limit**: 40 requests/10 seconds
- **Authentication**: API Key
- **Data**: Movies, TV shows, ratings, cast, genres

### OpenAI API
- **Model**: GPT-3.5-turbo / GPT-4
- **Usage**: Chat completions, content recommendations
- **Rate Limits**: Based on your plan

## Development Status

### Completed ✅
- [x] Flutter project setup and dependencies
- [x] Firebase Authentication integration
- [x] API integration (YouTube, Spotify, TMDB)
- [x] Voice mood detection with TensorFlow Lite
- [x] AI chat interface with OpenAI
- [x] Mood-based content filtering
- [x] Content history and favorites
- [x] Modern UI with Material 3 design
- [x] Cross-platform content mixing
- [x] User profile management
- [x] Search functionality
- [x] Content cards with media player
- [x] Navigation and routing

### In Progress 🚧
- [ ] Advanced ML recommendation models
- [ ] User behavior analytics
- [ ] Enhanced mood detection accuracy

### Planned 📋
- [ ] Push notifications
- [ ] Offline mode improvements
- [ ] Social features
- [ ] Playlist sharing
- [ ] Advanced filtering options

## Troubleshooting

### Voice Mood Detection Not Working
- Check microphone permissions in device settings
- Ensure audio recording duration is sufficient (minimum 2 seconds)
- Verify TensorFlow Lite models are in `assets/models/voice/`

### API Errors
- Verify API keys are correctly set in `app_constants.dart`
- Check API rate limits haven't been exceeded
- Ensure internet connection is stable

### Firebase Issues
- Verify `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is present
- Check Firebase project settings match your app package name
- Ensure required Firebase services are enabled in console

### Build Errors
- Run `flutter clean` and `flutter pub get`
- Ensure Flutter SDK version matches requirements
- Check Android/iOS build configurations

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Team

- **Maham Saeed** - Developer
- **Syed Hamza Mehdi** - Developer

## Support

For support, email support@contentai.com or create an issue in the repository.

## Acknowledgments

- TensorFlow Lite team for YAMNet model
- OpenAI for GPT API
- Firebase team for backend services
- Flutter team for the amazing framework
