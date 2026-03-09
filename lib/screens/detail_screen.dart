import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_colors.dart';
import '../models/listing_model.dart';
import '../providers/auth_provider.dart' as ap;
import '../providers/bookmarks_provider.dart';
import '../widgets/star_rating.dart';

class DetailScreen extends StatefulWidget {
  final ListingModel listing;

  const DetailScreen({super.key, required this.listing});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Widget _imageFallback() {
    return Container(
      color: kNavyLight,
      child: const Center(
        child: Icon(Icons.image_outlined, color: kBorderAccent, size: 64),
      ),
    );
  }

  Future<void> _launchNavigation() async {
    final lat = widget.listing.lat;
    final lng = widget.listing.lng;
    final label = Uri.encodeComponent(widget.listing.name);
    final googleMapsUrl =
        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$label');
    final appleMapsUrl =
        Uri.parse('http://maps.apple.com/?daddr=$lat,$lng&q=$label');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not open maps application.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final position = LatLng(listing.lat, listing.lng);

    return Scaffold(
      backgroundColor: kNavy,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: kNavyLight,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kNavy.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.arrow_back, color: kWhite, size: 20),
              ),
            ),
            actions: [
              Consumer2<BookmarksProvider, ap.AuthProvider>(
                builder: (context, bp, auth, child) {
                  final id = listing.id ?? '';
                  final isBookmarked = bp.isBookmarked(id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        final uid = auth.firebaseUser?.uid;
                        if (uid != null && id.isNotEmpty) {
                          bp.toggle(uid, id);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kNavy.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: isBookmarked ? kGold : kWhite,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: listing.imageUrl != null
                  ? Image.network(
                      listing.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imageFallback(),
                    )
                  : _imageFallback(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.name,
                              style: const TextStyle(
                                color: kWhite,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: kGold.withValues(alpha: 0.13),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    listing.category,
                                    style: const TextStyle(
                                      color: kGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StarRating(rating: listing.rating),
                          const SizedBox(height: 4),
                          Text(
                            listing.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: kGold,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    listing.description,
                    style: const TextStyle(
                      color: kGray,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: listing.address),
                        _InfoRow(
                            icon: Icons.phone_outlined,
                            label: listing.contact),
                        _InfoRow(
                          icon: Icons.my_location_outlined,
                          label:
                              '${listing.lat.toStringAsFixed(4)}, ${listing.lng.toStringAsFixed(4)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Google Map
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 200,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: position,
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId('marker_${listing.id}'),
                            position: position,
                            infoWindow: InfoWindow(title: listing.name),
                          ),
                        },
                        onMapCreated: (ctrl) => _mapController = ctrl,
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Get Directions button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _launchNavigation,
                      icon: const Text('🧭',
                          style: TextStyle(fontSize: 16)),
                      label: const Text(
                        'Get Directions',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGold,
                        foregroundColor: kNavy,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Reviews
                  const Text(
                    'Reviews',
                    style: TextStyle(
                      color: kWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (listing.reviews.isEmpty)
                    const Text(
                      'No reviews yet.',
                      style: TextStyle(color: kGray, fontSize: 13),
                    )
                  else
                    ...listing.reviews.map((r) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kCardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.author,
                                style: const TextStyle(
                                    color: kWhite,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '"${r.text}"',
                                style: const TextStyle(
                                  color: kGray,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: kGold, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: kGray, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
