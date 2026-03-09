import 'dart:async';
import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../services/firestore_service.dart';

enum ListingsStatus { initial, loading, loaded, error }

class ListingsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<ListingModel> _allListings = [];
  List<ListingModel> _myListings = [];
  ListingsStatus _status = ListingsStatus.initial;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  StreamSubscription<List<ListingModel>>? _allListingsSubscription;
  StreamSubscription<List<ListingModel>>? _myListingsSubscription;

  static const List<String> categories = [
    'All',
    'Cafés',
    'Hospitals',
    'Police',
    'Libraries',
    'Parks',
    'Restaurants',
    'Tourist',
  ];

  ListingsProvider(this._firestoreService);

  ListingsStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<ListingModel> get allListings => _allListings;
  List<ListingModel> get myListings => _myListings;

  List<ListingModel> get filteredListings {
    return _allListings.where((l) {
      final matchesCategory =
          _selectedCategory == 'All' || l.category == _selectedCategory;
      final matchesSearch =
          l.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              l.address.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Start listening to real-time full directory
  void subscribeToAllListings() {
    _status = ListingsStatus.loading;
    notifyListeners();
    _allListingsSubscription?.cancel();
    _allListingsSubscription =
        _firestoreService.listingsStream.listen((listings) {
      _allListings = listings;
      _status = ListingsStatus.loaded;
      notifyListeners();
    }, onError: (e) {
      _status = ListingsStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    });
  }

  // Start listening to the current user's listings
  void subscribeToMyListings(String uid) {
    _myListingsSubscription?.cancel();
    _myListingsSubscription =
        _firestoreService.userListingsStream(uid).listen((listings) {
      _myListings = listings;
      notifyListeners();
    });
  }

  void cancelSubscriptions() {
    _allListingsSubscription?.cancel();
    _myListingsSubscription?.cancel();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> addListing(ListingModel listing) async {
    try {
      await _firestoreService.createListing(listing);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateListing(String id, Map<String, dynamic> fields) async {
    try {
      await _firestoreService.updateListing(id, fields);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteListing(String id) async {
    try {
      await _firestoreService.deleteListing(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> addReview(
      String listingId, Map<String, dynamic> review) async {
    try {
      await _firestoreService.addReview(listingId, review);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
