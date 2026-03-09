import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/listing_model.dart';
import '../providers/auth_provider.dart' as ap;
import '../providers/listings_provider.dart';
import '../services/storage_service.dart';
import 'location_picker_screen.dart';

class AddEditListingScreen extends StatefulWidget {
  final ListingModel? listing; // null = create, non-null = edit

  const AddEditListingScreen({super.key, this.listing});

  @override
  State<AddEditListingScreen> createState() => _AddEditListingScreenState();
}

class _AddEditListingScreenState extends State<AddEditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _descCtrl;
  String _selectedCategory = ListingsProvider.categories[1];
  bool _saving = false;

  // Location
  late double _lat;
  late double _lng;

  // Image
  XFile? _pickedImage;
  final _imagePicker = ImagePicker();
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _nameCtrl = TextEditingController(text: l?.name ?? '');
    _addressCtrl = TextEditingController(text: l?.address ?? '');
    _contactCtrl = TextEditingController(text: l?.contact ?? '');
    _descCtrl = TextEditingController(text: l?.description ?? '');
    _lat = l?.lat ?? -1.9441;
    _lng = l?.lng ?? 30.0619;
    if (l != null) _selectedCategory = l.category;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _pickedImage = picked);
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _lat,
          initialLng: _lng,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<ListingsProvider>();
    final auth = context.read<ap.AuthProvider>();
    final uid = auth.firebaseUser?.uid ?? '';

    // Upload new image to Cloudinary if the user picked one; otherwise keep existing.
    String? imageUrl = widget.listing?.imageUrl;
    if (_pickedImage != null) {
      try {
        imageUrl = await _storage.uploadListingImage(uid, File(_pickedImage!.path));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Photo upload failed: $e'),
            backgroundColor: kRed,
          ));
        }
        setState(() => _saving = false);
        return;
      }
    }

    final fields = {
      'name': _nameCtrl.text.trim(),
      'category': _selectedCategory,
      'address': _addressCtrl.text.trim(),
      'contact': _contactCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'lat': _lat,
      'lng': _lng,
      'imageUrl': imageUrl,
    };

    if (widget.listing == null) {
      // Create
      final newListing = ListingModel(
        name: fields['name'] as String,
        category: fields['category'] as String,
        address: fields['address'] as String,
        contact: fields['contact'] as String,
        description: fields['description'] as String,
        lat: fields['lat'] as double,
        lng: fields['lng'] as double,
        createdBy: uid,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
      );
      await provider.addListing(newListing);
    } else {
      // Update
      await provider.updateListing(widget.listing!.id!, fields);
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  InputDecoration _deco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kGray, fontSize: 13),
      filled: true,
      fillColor: kNavyMid,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorderAccent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorderAccent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kGold),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.listing != null;
    final existingImageUrl = widget.listing?.imageUrl;

    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavyLight,
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Listing' : 'Add New Listing',
          style: const TextStyle(color: kWhite, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kWhite),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: kBorder),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Photo picker ──────────────────────────────────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: kNavyMid,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorderAccent),
                ),
                clipBehavior: Clip.hardEdge,
                child: _pickedImage != null
                    ? Image.file(
                        File(_pickedImage!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : existingImageUrl != null
                        ? Image.network(
                            existingImageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, _, _) =>
                                _imagePlaceholder(showChange: true),
                          )
                        : _imagePlaceholder(showChange: false),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                _pickedImage != null
                    ? 'Tap to change photo'
                    : existingImageUrl != null
                        ? 'Tap to replace photo'
                        : 'Tap to add a photo',
                style: const TextStyle(color: kGray, fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),

            // ── Text fields ───────────────────────────────────────────────
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: _deco('Place / Service Name *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              dropdownColor: kNavyMid,
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: _deco('Category *'),
              items: ListingsProvider.categories
                  .where((c) => c != 'All')
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c,
                            style: const TextStyle(color: kWhite)),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedCategory = v ?? _selectedCategory),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: _deco('Address *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Address is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactCtrl,
              style: const TextStyle(color: kWhite, fontSize: 14),
              keyboardType: TextInputType.phone,
              decoration: _deco('Contact Number *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Contact is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              style: const TextStyle(color: kWhite, fontSize: 14),
              maxLines: 3,
              decoration: _deco('Description *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 12),

            // ── Location picker ───────────────────────────────────────────
            GestureDetector(
              onTap: _pickLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: kNavyMid,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorderAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_outlined, color: kGold, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location',
                            style: TextStyle(color: kGray, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lat: ${_lat.toStringAsFixed(6)}   '
                            'Lng: ${_lng.toStringAsFixed(6)}',
                            style: const TextStyle(
                                color: kWhite, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Change',
                      style: TextStyle(
                        color: kGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold,
                  foregroundColor: kNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: kNavy, strokeWidth: 2),
                      )
                    : Text(
                        isEdit ? 'Save Changes' : '+ Add Listing',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder({required bool showChange}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            showChange ? Icons.image_outlined : Icons.add_photo_alternate_outlined,
            color: kBorderAccent,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            showChange ? 'Tap to change photo' : 'Add a photo',
            style: const TextStyle(color: kGray, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
