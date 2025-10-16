import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:content_nation/core/widgets/safe_network_image.dart';
import 'package:content_nation/core/models/content_model.dart';

void main() {
  group('SafeNetworkImage Tests', () {
    testWidgets('should display placeholder for empty URL', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeNetworkImage(
              imageUrl: '',
              platform: ContentType.spotify,
            ),
          ),
        ),
      );

      // Should show platform-specific placeholder
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('should display error widget for invalid URL', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeNetworkImage(
              imageUrl: 'invalid-url',
              platform: ContentType.youtube,
            ),
          ),
        ),
      );

      // Should show error icon
      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });

    testWidgets('should display placeholder image for valid placeholder URL', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeNetworkImage(
              imageUrl: 'https://via.placeholder.com/300x300/1db954/ffffff?text=Test',
              platform: ContentType.tmdb,
            ),
          ),
        ),
      );

      // Should show the placeholder image
      expect(find.byType(Image), findsOneWidget);
    });
  });
}