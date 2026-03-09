import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../providers/auth_provider.dart' as ap;
import '../providers/bookmarks_provider.dart';
import '../providers/listings_provider.dart';
import '../widgets/listing_card.dart';
import 'detail_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ListingsProvider, BookmarksProvider>(
      builder: (context, listings, bookmarks, _) {
        final uid =
            context.read<ap.AuthProvider>().firebaseUser?.uid ?? '';

        final saved = listings.allListings
            .where((l) => bookmarks.isBookmarked(l.id ?? ''))
            .toList();

        if (listings.status == ListingsStatus.loading &&
            listings.allListings.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: kGold));
        }

        if (saved.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bookmark_border,
                    color: kGray.withValues(alpha: 0.4), size: 64),
                const SizedBox(height: 16),
                const Text(
                  'No bookmarks yet',
                  style: TextStyle(
                    color: kWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the bookmark icon on any listing\nto save it here.',
                  style: TextStyle(color: kGray, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${saved.length} saved listing${saved.length == 1 ? '' : 's'}',
                style: const TextStyle(color: kGray, fontSize: 12),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: saved.length,
                itemBuilder: (context, i) {
                  final l = saved[i];
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ListingCard(
                        listing: l,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DetailScreen(listing: l)),
                        ),
                      ),
                      // Remove bookmark button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () =>
                              bookmarks.toggle(uid, l.id ?? ''),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: kNavy.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bookmark,
                                color: kGold, size: 16),
                          ),
                        ),
                      ),
                    ],
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
