import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kigali_services_directory/models/listing_model.dart';
import 'package:kigali_services_directory/providers/listings_provider.dart';
import 'package:kigali_services_directory/services/firestore_service.dart';

// Minimal fake that exposes a controllable listings stream
class FakeFirestoreService extends Fake implements FirestoreService {
  final StreamController<List<ListingModel>> controller =
      StreamController<List<ListingModel>>.broadcast();

  @override
  Stream<List<ListingModel>> get listingsStream => controller.stream;

  @override
  Stream<List<ListingModel>> userListingsStream(String uid) =>
      const Stream.empty();
}

ListingModel makeListing({
  required String name,
  required String category,
  String address = 'KG 1 Ave, Kigali',
}) {
  return ListingModel(
    id: name.toLowerCase().replaceAll(' ', '-'),
    name: name,
    category: category,
    address: address,
    contact: '+250788000000',
    description: 'Test description',
    lat: -1.9441,
    lng: 30.0619,
    createdBy: 'user-1',
    timestamp: DateTime(2025, 1, 1),
  );
}

void main() {
  late FakeFirestoreService fakeService;
  late ListingsProvider provider;

  setUp(() {
    fakeService = FakeFirestoreService();
    provider = ListingsProvider(fakeService);
    // Seed some listings via the stream
    provider.subscribeToAllListings();
    fakeService.controller.add([
      makeListing(name: 'City Hospital', category: 'Hospitals'),
      makeListing(name: 'Central Library', category: 'Libraries'),
      makeListing(name: 'Kigali Café', category: 'Cafés',
          address: 'KN 5 Rd, Kigali'),
      makeListing(name: 'Green Park', category: 'Parks',
          address: 'KG 7 St, Kigali'),
      makeListing(name: 'Blue Café', category: 'Cafés',
          address: 'KG 2 Ave, Kigali'),
    ]);
  });

  tearDown(() {
    provider.cancelSubscriptions();
    fakeService.controller.close();
  });

  group('filteredListings – category filter', () {
    test('"All" returns every listing', () async {
      await Future.microtask(() {});
      provider.setCategory('All');
      expect(provider.filteredListings.length, 5);
    });

    test('filters to only Cafés', () async {
      await Future.microtask(() {});
      provider.setCategory('Cafés');
      final results = provider.filteredListings;
      expect(results.length, 2);
      expect(results.every((l) => l.category == 'Cafés'), isTrue);
    });

    test('filters to only Hospitals', () async {
      await Future.microtask(() {});
      provider.setCategory('Hospitals');
      final results = provider.filteredListings;
      expect(results.length, 1);
      expect(results.first.name, 'City Hospital');
    });

    test('returns empty list for category with no listings', () async {
      await Future.microtask(() {});
      provider.setCategory('Tourist');
      expect(provider.filteredListings, isEmpty);
    });
  });

  group('filteredListings – search filter', () {
    test('searches by name (case-insensitive)', () async {
      await Future.microtask(() {});
      provider.setCategory('All');
      provider.setSearch('café');
      final results = provider.filteredListings;
      expect(results.length, 2);
      expect(results.every((l) => l.name.toLowerCase().contains('café')),
          isTrue);
    });

    test('searches by address', () async {
      await Future.microtask(() {});
      provider.setCategory('All');
      provider.setSearch('KN 5 Rd');
      final results = provider.filteredListings;
      expect(results.length, 1);
      expect(results.first.name, 'Kigali Café');
    });

    test('empty search returns all listings in selected category', () async {
      await Future.microtask(() {});
      provider.setCategory('Cafés');
      provider.setSearch('');
      expect(provider.filteredListings.length, 2);
    });

    test('search with no matches returns empty list', () async {
      await Future.microtask(() {});
      provider.setSearch('zzznomatch');
      expect(provider.filteredListings, isEmpty);
    });
  });

  group('filteredListings – combined search + category', () {
    test('narrows by both category and search term', () async {
      await Future.microtask(() {});
      provider.setCategory('Cafés');
      provider.setSearch('blue');
      final results = provider.filteredListings;
      expect(results.length, 1);
      expect(results.first.name, 'Blue Café');
    });

    test('search that matches name but not category returns empty', () async {
      await Future.microtask(() {});
      provider.setCategory('Hospitals');
      provider.setSearch('Café');
      expect(provider.filteredListings, isEmpty);
    });
  });

  group('setSearch / setCategory state', () {
    test('setSearch updates searchQuery', () {
      provider.setSearch('hello');
      expect(provider.searchQuery, 'hello');
    });

    test('setCategory updates selectedCategory', () {
      provider.setCategory('Parks');
      expect(provider.selectedCategory, 'Parks');
    });
  });

  group('categories list', () {
    test('contains All and all expected service types', () {
      const expected = [
        'All', 'Cafés', 'Hospitals', 'Police',
        'Libraries', 'Parks', 'Restaurants', 'Tourist',
      ];
      expect(ListingsProvider.categories, expected);
    });
  });
}
