# API Keys Configuration

This app requires API keys for certain services. To configure them:

## OpenAI API Key

1. Get your API key from: https://platform.openai.com/api-keys
2. Create a file: `lib/core/config/api_keys.dart`
3. Copy the content from `lib/core/config/api_keys.dart.example`
4. Replace `YOUR_OPENAI_API_KEY_HERE` with your actual key

**OR**

Set the environment variable when running:
```bash
flutter run --dart-define=OPENAI_API_KEY=your-key-here
```

**Note:** The `api_keys.dart` file is gitignored and will not be committed to the repository.

