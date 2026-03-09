import 'package:flutter_test/flutter_test.dart';
import 'package:kigali_services_directory/models/listing_model.dart';

void main() {
  final baseTime = DateTime(2025, 1, 15, 10, 0);

  ListingModel makeModel({
    String id = 'test-id',
    String name = 'Kigali Hospital',
    String category = 'Hospitals',
    String address = 'KG 100 St, Kigali',
    String contact = '+250788000000',
    String description = 'Main city hospital',
    double lat = -1.9441,
    double lng = 30.0619,
    String createdBy = 'user-1',
    double rating = 4.5,
    String? imageUrl,
  }) {
    return ListingModel(
      id: id,
      name: name,
      category: category,
      address: address,
      contact: contact,
      description: description,
      lat: lat,
      lng: lng,
      createdBy: createdBy,
      timestamp: baseTime,
      rating: rating,
      imageUrl: imageUrl,
    );
  }

  group('ListingModel constructor', () {
    test('stores all required fields', () {
      final model = makeModel();
      expect(model.id, 'test-id');
      expect(model.name, 'Kigali Hospital');
      expect(model.category, 'Hospitals');
      expect(model.address, 'KG 100 St, Kigali');
      expect(model.contact, '+250788000000');
      expect(model.description, 'Main city hospital');
      expect(model.lat, -1.9441);
      expect(model.lng, 30.0619);
      expect(model.createdBy, 'user-1');
      expect(model.rating, 4.5);
      expect(model.reviews, isEmpty);
      expect(model.imageUrl, isNull);
    });

    test('stores optional imageUrl', () {
      final model = makeModel(imageUrl: 'https://example.com/img.jpg');
      expect(model.imageUrl, 'https://example.com/img.jpg');
    });

    test('defaults rating to 0.0 when not provided', () {
      final model = ListingModel(
        name: 'Test',
        category: 'Cafés',
        address: 'Addr',
        contact: '123',
        description: 'Desc',
        lat: 0,
        lng: 0,
        createdBy: 'uid',
        timestamp: baseTime,
      );
      expect(model.rating, 0.0);
    });
  });

  group('ListingModel.copyWith', () {
    test('returns a new instance with changed fields', () {
      final original = makeModel();
      final copy = original.copyWith(name: 'New Name', rating: 3.0);

      expect(copy.name, 'New Name');
      expect(copy.rating, 3.0);
      // unchanged fields preserved
      expect(copy.id, original.id);
      expect(copy.category, original.category);
      expect(copy.lat, original.lat);
    });

    test('preserves imageUrl through copyWith', () {
      final original = makeModel(imageUrl: 'https://example.com/img.jpg');
      final copy = original.copyWith(name: 'Changed');
      expect(copy.imageUrl, 'https://example.com/img.jpg');
    });

    test('can update imageUrl via copyWith', () {
      final original = makeModel();
      final copy = original.copyWith(imageUrl: 'https://new.url/img.jpg');
      expect(copy.imageUrl, 'https://new.url/img.jpg');
    });

    test('does not mutate the original', () {
      final original = makeModel(name: 'Original');
      original.copyWith(name: 'Changed');
      expect(original.name, 'Original');
    });
  });

  group('ListingModel.toFirestore', () {
    test('serializes all fields correctly', () {
      final model = makeModel(imageUrl: 'https://example.com/img.jpg');
      final map = model.toFirestore();

      expect(map['name'], 'Kigali Hospital');
      expect(map['category'], 'Hospitals');
      expect(map['address'], 'KG 100 St, Kigali');
      expect(map['contact'], '+250788000000');
      expect(map['description'], 'Main city hospital');
      expect(map['lat'], -1.9441);
      expect(map['lng'], 30.0619);
      expect(map['createdBy'], 'user-1');
      expect(map['rating'], 4.5);
      expect(map['reviews'], isEmpty);
      expect(map['imageUrl'], 'https://example.com/img.jpg');
    });

    test('omits imageUrl key when imageUrl is null', () {
      final model = makeModel();
      final map = model.toFirestore();
      expect(map.containsKey('imageUrl'), isFalse);
    });
  });

  group('ReviewModel', () {
    test('serializes and deserializes correctly', () {
      final review = ReviewModel(author: 'Alice', text: 'Great place!');
      final map = review.toMap();
      final restored = ReviewModel.fromMap(map);

      expect(restored.author, 'Alice');
      expect(restored.text, 'Great place!');
    });

    test('fromMap uses empty strings for missing keys', () {
      final review = ReviewModel.fromMap({});
      expect(review.author, '');
      expect(review.text, '');
    });
  });
}
