import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String author;
  final String text;
  final double rating;

  ReviewModel({required this.author, required this.text, this.rating = 0.0});

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      author: map['author'] as String? ?? '',
      text: map['text'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'author': author,
        'text': text,
        'rating': rating,
      };
}

class ListingModel {
  final String? id;
  final String name;
  final String category;
  final String address;
  final String contact;
  final String description;
  final double lat;
  final double lng;
  final String createdBy;
  final DateTime timestamp;
  final double rating;
  final List<ReviewModel> reviews;
  final String? imageUrl;

  ListingModel({
    this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.contact,
    required this.description,
    required this.lat,
    required this.lng,
    required this.createdBy,
    required this.timestamp,
    this.rating = 0.0,
    this.reviews = const [],
    this.imageUrl,
  });

  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListingModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      address: data['address'] as String? ?? '',
      contact: data['contact'] as String? ?? '',
      description: data['description'] as String? ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      createdBy: data['createdBy'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (data['reviews'] as List<dynamic>? ?? [])
          .map((r) => ReviewModel.fromMap(r as Map<String, dynamic>))
          .toList(),
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'address': address,
        'contact': contact,
        'description': description,
        'lat': lat,
        'lng': lng,
        'createdBy': createdBy,
        'timestamp': Timestamp.fromDate(timestamp),
        'rating': rating,
        'reviews': reviews.map((r) => r.toMap()).toList(),
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

  ListingModel copyWith({
    String? id,
    String? name,
    String? category,
    String? address,
    String? contact,
    String? description,
    double? lat,
    double? lng,
    String? createdBy,
    DateTime? timestamp,
    double? rating,
    List<ReviewModel>? reviews,
    String? imageUrl,
  }) {
    return ListingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      createdBy: createdBy ?? this.createdBy,
      timestamp: timestamp ?? this.timestamp,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
