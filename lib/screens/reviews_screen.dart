import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/listing_model.dart';
import '../providers/auth_provider.dart' as ap;
import '../providers/listings_provider.dart';
import 'detail_screen.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddReviewSheet(
      BuildContext context, ListingModel listing, ap.AuthProvider auth) {
    final textCtrl = TextEditingController();
    int selectedStars = 5;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kNavyLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Write a Review',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          listing.name,
                          style: const TextStyle(color: kGold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: kGray, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Star picker ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedStars = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < selectedStars ? Icons.star : Icons.star_border,
                        color: kGold,
                        size: 34,
                      ),
                    ),
                  );
                }),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][selectedStars],
                    style: const TextStyle(color: kGold, fontSize: 12),
                  ),
                ),
              ),

              TextField(
                controller: textCtrl,
                autofocus: true,
                maxLines: 4,
                style: const TextStyle(color: kWhite, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Share your experience at ${listing.name}...',
                  hintStyle: const TextStyle(color: kGray, fontSize: 13),
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
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final text = textCtrl.text.trim();
                    if (text.isEmpty) return;
                    final authorName = auth.userProfile?.name ?? 'Anonymous';
                    Navigator.pop(ctx);
                    await context.read<ListingsProvider>().addReview(
                          listing.id!,
                          {
                            'author': authorName,
                            'text': text,
                            'rating': selectedStars.toDouble(),
                          },
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Review posted!'),
                          backgroundColor: kGreen,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGold,
                    foregroundColor: kNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Post Review',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ap.AuthProvider>();

    return Consumer<ListingsProvider>(
      builder: (context, provider, _) {
        final allListings = provider.allListings;

        // Filter by search
        final filtered = _search.isEmpty
            ? allListings
            : allListings
                .where((l) =>
                    l.name
                        .toLowerCase()
                        .contains(_search.toLowerCase()) ||
                    l.category
                        .toLowerCase()
                        .contains(_search.toLowerCase()))
                .toList();

        return Column(
          children: [
            // Search bar
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v.trim()),
                style: const TextStyle(color: kWhite, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search listings to review...',
                  hintStyle:
                      const TextStyle(color: kGray, fontSize: 14),
                  prefixIcon:
                      const Icon(Icons.search, color: kGray, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: kGray, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: kCardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kGold),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Count
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filtered.length} listing${filtered.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: kGray,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            // List
            Expanded(
              child: provider.status == ListingsStatus.loading &&
                      allListings.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: kGold))
                  : filtered.isEmpty
                      ? const Center(
                          child: Text('No listings found.',
                              style: TextStyle(color: kGray)),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final l = filtered[i];
                            return _ReviewListingCard(
                              listing: l,
                              onViewListing: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        DetailScreen(listing: l)),
                              ),
                              onAddReview: () => _openAddReviewSheet(
                                  context, l, auth),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

// ── Listing card for Reviews screen ─────────────────────────────────────────

class _ReviewListingCard extends StatefulWidget {
  final ListingModel listing;
  final VoidCallback onViewListing;
  final VoidCallback onAddReview;

  const _ReviewListingCard({
    required this.listing,
    required this.onViewListing,
    required this.onAddReview,
  });

  @override
  State<_ReviewListingCard> createState() => _ReviewListingCardState();
}

class _ReviewListingCardState extends State<_ReviewListingCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final reviewCount = l.reviews.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.name,
                        style: const TextStyle(
                          color: kWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kGold.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l.category,
                              style: const TextStyle(
                                color: kGold,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.star,
                              color: kGold, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            l.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: kGold, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$reviewCount review${reviewCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: kGray, fontSize: 12),
                    ),
                    if (reviewCount > 0)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _expanded = !_expanded),
                        child: Text(
                          _expanded ? 'Hide' : 'Show',
                          style: const TextStyle(
                            color: kGold,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Existing reviews (expandable)
          if (_expanded && l.reviews.isNotEmpty) ...[
            const Divider(color: kBorder, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                children: l.reviews
                    .map((r) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kNavyMid,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person,
                                      color: kGold, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      r.author,
                                      style: const TextStyle(
                                        color: kWhite,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (r.rating > 0) ...[
                                    const Icon(Icons.star,
                                        color: kGold, size: 11),
                                    const SizedBox(width: 2),
                                    Text(
                                      r.rating.toStringAsFixed(0),
                                      style: const TextStyle(
                                          color: kGold, fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r.text,
                                style: const TextStyle(
                                  color: kGray,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],

          // Action buttons
          const Divider(color: kBorder, height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onViewListing,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: kBorderAccent),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          color: kGray,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onAddReview,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8),
                      decoration: BoxDecoration(
                        color: kGold.withValues(alpha: 0.12),
                        border: Border.all(
                            color: kGold.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '✏️  Write Review',
                        style: TextStyle(
                          color: kGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
