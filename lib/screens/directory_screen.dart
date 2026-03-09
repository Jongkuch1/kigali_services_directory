import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/listing_model.dart';
import '../providers/listings_provider.dart';
import '../widgets/category_badge.dart';
import '../widgets/listing_card.dart';
import 'detail_screen.dart';

// Category metadata: icon + accent colour
const _catMeta = {
  'Cafés':       {'icon': Icons.local_cafe_outlined,      'color': Color(0xFFE67E22)},
  'Hospitals':   {'icon': Icons.local_hospital_outlined,  'color': Color(0xFFE74C3C)},
  'Police':      {'icon': Icons.local_police_outlined,    'color': Color(0xFF2980B9)},
  'Libraries':   {'icon': Icons.menu_book_outlined,       'color': Color(0xFF8E44AD)},
  'Parks':       {'icon': Icons.park_outlined,            'color': Color(0xFF27AE60)},
  'Restaurants': {'icon': Icons.restaurant_outlined,      'color': Color(0xFFD35400)},
  'Tourist':     {'icon': Icons.photo_camera_outlined,    'color': Color(0xFF16A085)},
};

class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ListingsProvider>(
      builder: (context, provider, _) {
        final isFiltered = provider.selectedCategory != 'All' ||
            provider.searchQuery.isNotEmpty;

        return Column(
          children: [
            // ── Category chips ───────────────────────────────────────────
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ListingsProvider.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = ListingsProvider.categories[i];
                  return CategoryBadge(
                    label: cat,
                    active: provider.selectedCategory == cat,
                    onTap: () => provider.setCategory(cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // ── Search field ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: provider.setSearch,
                style: const TextStyle(color: kWhite, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search for a service...',
                  hintStyle: const TextStyle(color: kGray, fontSize: 14),
                  prefixIcon:
                      const Icon(Icons.search, color: kGray, size: 20),
                  suffixIcon: provider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: kGray, size: 18),
                          onPressed: () => provider.setSearch(''),
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
            const SizedBox(height: 8),

            // ── Body ─────────────────────────────────────────────────────
            Expanded(child: _buildBody(context, provider, isFiltered)),
          ],
        );
      },
    );
  }

  Widget _buildBody(
      BuildContext context, ListingsProvider provider, bool isFiltered) {
    if (provider.status == ListingsStatus.loading &&
        provider.allListings.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kGold));
    }

    if (provider.status == ListingsStatus.error) {
      return Center(
        child: Text(
          provider.errorMessage ?? 'An error occurred',
          style: const TextStyle(color: kRed),
          textAlign: TextAlign.center,
        ),
      );
    }

    // ── Filtered / search mode: plain flat list ─────────────────────────
    if (isFiltered) {
      final listings = provider.filteredListings;
      if (listings.isEmpty) {
        return const Center(
          child: Text('No listings found',
              style: TextStyle(color: kGray, fontSize: 14)),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '${listings.length} RESULT${listings.length == 1 ? '' : 'S'}',
              style: const TextStyle(
                color: kGray,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: listings.length,
              itemBuilder: (context, i) {
                final l = listings[i];
                return ListingCard(
                  listing: l,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetailScreen(listing: l)),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    // ── Default "All" mode: sectioned by category ────────────────────────
    final all = provider.allListings;
    if (all.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_city_outlined,
                color: kGray.withValues(alpha: 0.35), size: 64),
            const SizedBox(height: 16),
            const Text('No listings yet',
                style: TextStyle(
                    color: kWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Go to Services to add the first listing.',
                style: TextStyle(color: kGray, fontSize: 13)),
          ],
        ),
      );
    }

    // Build sections only for categories that have listings (up to 15 each)
    final cats =
        ListingsProvider.categories.where((c) => c != 'All').toList();

    final sections = cats.where((cat) {
      return all.any((l) => l.category == cat);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: sections.length,
      itemBuilder: (ctx, i) {
        final cat = sections[i];
        final items = all.where((l) => l.category == cat).take(15).toList();
        return _CategorySection(
          cat: cat,
          items: items,
          onSeeAll: () => provider.setCategory(cat),
        );
      },
    );
  }
}

// ── Category section ─────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final String cat;
  final List<ListingModel> items;
  final VoidCallback onSeeAll;

  const _CategorySection({
    required this.cat,
    required this.items,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _catMeta[cat];
    final icon = meta?['icon'] as IconData? ?? Icons.place_outlined;
    final color = meta?['color'] as Color? ?? kGold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cat,
                  style: const TextStyle(
                    color: kWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onSeeAll,
                child: Row(
                  children: [
                    Text(
                      '${items.length} listing${items.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: kGold, fontSize: 12),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, color: kGold, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Horizontal scroll of compact cards
        SizedBox(
          height: 172,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (ctx, i) =>
                _CompactCard(listing: items[i], accentColor: color),
          ),
        ),
      ],
    );
  }
}

// ── Compact horizontal card ──────────────────────────────────────────────────

class _CompactCard extends StatelessWidget {
  final ListingModel listing;
  final Color accentColor;

  const _CompactCard({required this.listing, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final icon =
        _catMeta[listing.category]?['icon'] as IconData? ?? Icons.place_outlined;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(listing: listing)),
      ),
      child: Container(
        width: 158,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 19),
            ),
            const SizedBox(height: 9),

            // Name
            Text(
              listing.name,
              style: const TextStyle(
                color: kWhite,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Address
            Text(
              listing.address,
              style: const TextStyle(color: kGray, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Rating row
            Row(
              children: [
                const Icon(Icons.star, color: kGold, size: 12),
                const SizedBox(width: 3),
                Text(
                  listing.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: kGold,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: kGray, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
