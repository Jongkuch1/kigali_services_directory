import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/listing_model.dart';
import '../providers/auth_provider.dart' as ap;
import '../providers/listings_provider.dart';
import '../widgets/star_rating.dart';
import 'add_edit_listing_screen.dart';
import 'detail_screen.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  void _confirmDelete(
      BuildContext context, ListingModel listing, ListingsProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kNavyLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Listing',
            style: TextStyle(color: kWhite, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${listing.name}"? This cannot be undone.',
          style: const TextStyle(color: kGray, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kGray)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteListing(listing.id!);
            },
            child:
                const Text('Delete', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ListingsProvider, ap.AuthProvider>(
      builder: (context, listingsProvider, authProvider, _) {
        final myListings = listingsProvider.myListings;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${myListings.length} listing${myListings.length == 1 ? '' : 's'} created by you',
                style: const TextStyle(color: kGray, fontSize: 12),
              ),
            ),
            Expanded(
              child: myListings.isEmpty
                  ? const Center(
                      child: Text(
                        'You haven\'t created any listings yet.',
                        style: TextStyle(color: kGray, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: myListings.length,
                      itemBuilder: (context, i) {
                        final l = myListings[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kCardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      l.name,
                                      style: const TextStyle(
                                        color: kWhite,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: kGold.withValues(alpha: 0.13),
                                      borderRadius:
                                          BorderRadius.circular(8),
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
                                ],
                              ),
                              const SizedBox(height: 6),
                              StarRating(rating: l.rating, size: 12),
                              const SizedBox(height: 4),
                              Text(
                                l.address,
                                style: const TextStyle(
                                    color: kGray, fontSize: 12),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _actionButton(
                                    context,
                                    label: 'View',
                                    borderColor: kBorderAccent,
                                    textColor: kWhite,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              DetailScreen(listing: l)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _actionButton(
                                    context,
                                    label: 'Edit',
                                    borderColor: kGold,
                                    textColor: kGold,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              AddEditListingScreen(
                                                  listing: l)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _actionButton(
                                    context,
                                    label: 'Delete',
                                    borderColor: kRed,
                                    textColor: kRed,
                                    onTap: () => _confirmDelete(
                                        context, l, listingsProvider),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const AddEditListingScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGold,
                    foregroundColor: kNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    '+ Add New Listing',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
