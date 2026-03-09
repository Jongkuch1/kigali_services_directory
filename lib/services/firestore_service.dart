import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

final _usersCol = FirebaseFirestore.instance.collection('users');

class FirestoreService {
  final CollectionReference _listingsCol =
      FirebaseFirestore.instance.collection('listings');

  // Real-time stream of all listings
  Stream<List<ListingModel>> get listingsStream {
    return _listingsCol
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList());
  }

  // Real-time stream of listings belonging to a specific user
  Stream<List<ListingModel>> userListingsStream(String uid) {
    return _listingsCol
        .where('createdBy', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList());
  }

  // Fetch all listings once
  Future<List<ListingModel>> fetchAllListings() async {
    final snapshot =
        await _listingsCol.orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList();
  }

  // Create a new listing
  Future<String> createListing(ListingModel listing) async {
    final docRef = await _listingsCol.add(listing.toFirestore());
    return docRef.id;
  }

  // Update an existing listing (only fields the user controls)
  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    await _listingsCol.doc(id).update(data);
  }

  // Delete a listing
  Future<void> deleteListing(String id) async {
    await _listingsCol.doc(id).delete();
  }

  // Fetch a single listing by id
  Future<ListingModel?> fetchListing(String id) async {
    final doc = await _listingsCol.doc(id).get();
    if (doc.exists) return ListingModel.fromFirestore(doc);
    return null;
  }

  // ── Bookmarks ────────────────────────────────────────────────────────────

  // Real-time stream of bookmarked listing IDs for a user
  Stream<List<String>> bookmarksStream(String uid) {
    return _usersCol.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return <String>[];
      final data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['bookmarks'] as List? ?? []);
    });
  }

  // Add or remove a listing from the user's bookmarks
  Future<void> toggleBookmark(
      String uid, String listingId, bool add) async {
    await _usersCol.doc(uid).set(
      {
        'bookmarks': add
            ? FieldValue.arrayUnion([listingId])
            : FieldValue.arrayRemove([listingId]),
      },
      SetOptions(merge: true),
    );
  }

  // ── Reviews ──────────────────────────────────────────────────────────────

  // Append a review and atomically recalculate the average rating
  Future<void> addReview(String listingId, Map<String, dynamic> review) async {
    final docRef = _listingsCol.doc(listingId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      final data = snapshot.data() as Map<String, dynamic>;
      final reviews = [
        ...(data['reviews'] as List<dynamic>? ?? [])
            .map((r) => r as Map<String, dynamic>),
        review,
      ];
      final avgRating = reviews
              .map((r) => (r['rating'] as num?)?.toDouble() ?? 0.0)
              .fold(0.0, (a, b) => a + b) /
          reviews.length;
      tx.update(docRef, {
        'reviews': reviews,
        'rating': double.parse(avgRating.toStringAsFixed(1)),
      });
    });
  }
}
