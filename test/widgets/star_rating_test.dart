import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kigali_services_directory/widgets/star_rating.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('StarRating', () {
    testWidgets('rating 5.0 → 5 full stars', (tester) async {
      await tester.pumpWidget(_wrap(const StarRating(rating: 5.0)));
      expect(find.byIcon(Icons.star), findsNWidgets(5));
      expect(find.byIcon(Icons.star_half), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('rating 0.0 → 5 empty stars', (tester) async {
      await tester.pumpWidget(_wrap(const StarRating(rating: 0.0)));
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.star_half), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNWidgets(5));
    });

    testWidgets('rating 2.5 → 2 full, 1 half, 2 empty', (tester) async {
      await tester.pumpWidget(_wrap(const StarRating(rating: 2.5)));
      expect(find.byIcon(Icons.star), findsNWidgets(2));
      expect(find.byIcon(Icons.star_half), findsNWidgets(1));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('rating 3.0 → 3 full, 0 half, 2 empty', (tester) async {
      await tester.pumpWidget(_wrap(const StarRating(rating: 3.0)));
      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_half), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('rating 4.7 → 4 full, 1 half, 0 empty', (tester) async {
      await tester.pumpWidget(_wrap(const StarRating(rating: 4.7)));
      expect(find.byIcon(Icons.star), findsNWidgets(4));
      expect(find.byIcon(Icons.star_half), findsNWidgets(1));
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('rating 1.4 → 1 full, 0 half, 4 empty', (tester) async {
      await tester.pumpWidget(_wrap(const StarRating(rating: 1.4)));
      expect(find.byIcon(Icons.star), findsNWidgets(1));
      expect(find.byIcon(Icons.star_half), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNWidgets(4));
    });

    testWidgets('applies custom size to all icons', (tester) async {
      await tester.pumpWidget(_wrap(const StarRating(rating: 3.0, size: 24)));
      final icons = tester.widgetList<Icon>(find.byType(Icon));
      expect(icons.every((ic) => ic.size == 24), isTrue);
    });

    testWidgets('default size is 14', (tester) async {
      await tester.pumpWidget(_wrap(const StarRating(rating: 3.0)));
      final icons = tester.widgetList<Icon>(find.byType(Icon));
      expect(icons.every((ic) => ic.size == 14), isTrue);
    });

    testWidgets('always renders exactly 5 icons', (tester) async {
      for (final r in [0.0, 1.0, 2.5, 3.7, 5.0]) {
        await tester.pumpWidget(_wrap(StarRating(rating: r)));
        final total = tester.widgetList<Icon>(find.byType(Icon)).length;
        expect(total, 5, reason: 'Expected 5 icons for rating $r');
      }
    });
  });
}
