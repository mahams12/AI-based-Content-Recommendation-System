# AI-Based Content Recommendation System

A cross-platform Flutter mobile app that provides personalized content recommendations from YouTube, Spotify, and TMDB (movies/TV shows) using AI and sentiment analysis.

## Features

### Core Features
- **User Management**: Registration/Login with email verification, profile creation with preferences
- **AI Recommendation Engine**: Collaborative filtering + Content-based filtering + Deep learning hybrid
- **Sentiment Analysis**: Mood detection based on user interaction patterns
- **Cross-Platform Integration**: YouTube, Spotify, and TMDB APIs
- **Real-time Content Fetching**: Live content from all platforms
- **Smart Features**: Auto-generated playlists, cross-platform content mixing

### Technical Stack
- **Frontend**: Flutter 3.0+
- **Backend**: Python Flask/Django REST API (planned)
- **Database**: MongoDB Atlas (planned)
- **Authentication**: Firebase Auth
- **ML/AI**: TensorFlow, scikit-learn, BERT (planned)
- **APIs**: YouTube Data API v3, Spotify Web API, TMDB API

## Getting Started

### Prerequisites
- Flutter SDK 3.9.2 or higher
- Dart SDK
- Android Studio / VS Code
- Firebase project setup

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd ai_based_content_recommendation_system
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up Firebase:
   - Create a Firebase project
   - Add your app to the Firebase project
   - Download and add the configuration files
   - Update `lib/firebase_options.dart` with your Firebase configuration

4. Configure API Keys:
   - Update API keys in `lib/core/constants/app_constants.dart`
   - YouTube API Key: `AIzaSyDdwTVftDl6nRqRuofWlfx1p8-enTPNFnc`
   - Spotify Client ID: `071b9c2312f64b2495e7135f3dfbf317`
   - TMDB API Key: `146bd026e1a4e8b5998458984ac771ce`

5. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── constants/          # App constants and configuration
│   ├── models/            # Data models
│   ├── services/          # API and storage services
│   └── theme/             # App theming
├── features/
│   ├── auth/              # Authentication feature
│   ├── home/              # Home screen and content display
│   ├── search/            # Search functionality
│   ├── recommendations/   # AI recommendations
│   └── profile/           # User profile management
└── main.dart              # App entry point
```

## API Integration

### YouTube Data API v3
- Rate Limit: 10,000 units/day
- Endpoints: Search, Videos, Channels
- Data: Video metadata, thumbnails, duration, categories

### Spotify Web API
- Rate Limit: 2,000 requests/hour
- Authentication: OAuth 2.0
- Data: Tracks, albums, artists, playlists, audio features

### TMDB API
- Rate Limit: 40 requests/10 seconds
- Authentication: API Key
- Data: Movies, TV shows, ratings, cast, genres

## Performance Requirements

| Metric | Target | Critical Path |
|--------|--------|---------------|
| App Launch | < 3 seconds | Initial data loading |
| Recommendations Load | < 2 seconds | ML processing + API calls |
| Search Results | < 1.5 seconds | Multi-API parallel requests |
| Content Metadata | < 1 second | Cached data retrieval |
| Memory Usage | < 150MB | Image caching optimization |

## Development Status

### Completed ✅
- [x] Flutter project setup and dependencies
- [x] API integration (YouTube, Spotify, TMDB)
- [x] Modern UI design with Material 3
- [x] Authentication system (Firebase)
- [x] Real-time content fetching
- [x] Content caching and storage
- [x] Mood-based filtering
- [x] Cross-platform content mixing

### In Progress 🚧
- [ ] AI recommendation engine
- [ ] Sentiment analysis implementation
- [ ] MongoDB database setup
- [ ] Backend API development

### Planned 📋
- [ ] Advanced ML models
- [ ] User behavior analytics
- [ ] Push notifications
- [ ] Offline mode
- [ ] Social features

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Team

- **Maham Saeed** - Developer
- **Syed Hamza Mehdi** - Developer

## Timeline

- **Spring 2025** - Project initiation and core development
- **Fall 2026** - Advanced features and deployment

## Support

For support, email support@contentai.com or create an issue in the repository.