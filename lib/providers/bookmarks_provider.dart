import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class BookmarksProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<String> _bookmarkedIds = [];
  StreamSubscription<List<String>>? _sub;

  BookmarksProvider(this._firestoreService);

  List<String> get bookmarkedIds => List.unmodifiable(_bookmarkedIds);

  bool isBookmarked(String listingId) => _bookmarkedIds.contains(listingId);

  void subscribe(String uid) {
    _sub?.cancel();
    _sub = _firestoreService.bookmarksStream(uid).listen((ids) {
      _bookmarkedIds = ids;
      notifyListeners();
    });
  }

  Future<void> toggle(String uid, String listingId) async {
    final add = !_bookmarkedIds.contains(listingId);
    await _firestoreService.toggleBookmark(uid, listingId, add);
  }

  void cancelSubscription() {
    _sub?.cancel();
    _bookmarkedIds = [];
  }
}
