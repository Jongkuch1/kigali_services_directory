import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kigali_services_directory/models/listing_model.dart';
import 'package:kigali_services_directory/widgets/listing_card.dart';

ListingModel _makeListing({
  String name = 'City Hospital',
  String category = 'Hospitals',
  String address = 'KG 1 Ave, Kigali',
  double rating = 4.2,
  String? imageUrl,
}) =>
    ListingModel(
      id: 'test-id',
      name: name,
      category: category,
      address: address,
      contact: '+250788000000',
      description: 'Test description',
      lat: -1.9441,
      lng: 30.0619,
      createdBy: 'user-1',
      timestamp: DateTime(2025, 1, 1),
      rating: rating,
      imageUrl: imageUrl,
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ListingCard', () {
    testWidgets('renders listing name', (tester) async {
      await tester.pumpWidget(_wrap(
        ListingCard(listing: _makeListing(name: 'City Hospital'), onTap: () {}),
      ));
      expect(find.text('City Hospital'), findsOneWidget);
    });

    testWidgets('renders category badge', (tester) async {
      await tester.pumpWidget(_wrap(
        ListingCard(listing: _makeListing(category: 'Hospitals'), onTap: () {}),
      ));
      expect(find.text('Hospitals'), findsOneWidget);
    });

    testWidgets('renders address', (tester) async {
      await tester.pumpWidget(_wrap(
        ListingCard(
            listing: _makeListing(address: 'KG 5 Ave, Kigali'), onTap: () {}),
      ));
      expect(find.text('KG 5 Ave, Kigali'), findsOneWidget);
    });

    testWidgets('renders formatted rating', (tester) async {
      await tester.pumpWidget(_wrap(
        ListingCard(listing: _makeListing(rating: 4.2), onTap: () {}),
      ));
      expect(find.text('4.2'), findsOneWidget);
    });

    testWidgets('shows chevron_right icon', (tester) async {
      await tester.pumpWidget(_wrap(
        ListingCard(listing: _makeListing(), onTap: () {}),
      ));
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        ListingCard(listing: _makeListing(), onTap: () => tapped = true),
      ));
      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, isTrue);
    });

    testWidgets('no thumbnail when imageUrl is null', (tester) async {
      await tester.pumpWidget(_wrap(
        ListingCard(listing: _makeListing(imageUrl: null), onTap: () {}),
      ));
      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('shows thumbnail ClipRRect when imageUrl is set', (tester) async {
      await tester.pumpWidget(_wrap(
        ListingCard(
          listing: _makeListing(imageUrl: 'https://example.com/img.jpg'),
          onTap: () {},
        ),
      ));
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('rating 0.0 displays as "0.0"', (tester) async {
      await tester.pumpWidget(_wrap(
        ListingCard(listing: _makeListing(rating: 0.0), onTap: () {}),
      ));
      expect(find.text('0.0'), findsOneWidget);
    });

    testWidgets('long name is rendered without overflow error', (tester) async {
      await tester.pumpWidget(_wrap(
        ListingCard(
          listing: _makeListing(
              name: 'This Is A Very Long Service Name That Might Overflow'),
          onTap: () {},
        ),
      ));
      // If overflow throws, the test fails; otherwise pass
      expect(find.byType(ListingCard), findsOneWidget);
    });
  });
}
