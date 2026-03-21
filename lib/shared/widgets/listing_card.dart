import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../core/models/listing_model.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AtrioColors.hostSurface : AtrioColors.guestBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AtrioColors.hostCardBorder : AtrioColors.guestCardBorder,
            width: isDark ? 0.5 : 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    listing.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: listing.images.first,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                              color: isDark
                                  ? AtrioColors.hostSurfaceVariant
                                  : AtrioColors.guestSurfaceVariant,
                            ),
                            errorWidget: (_, _, _) => Container(
                              color: isDark
                                  ? AtrioColors.hostSurfaceVariant
                                  : AtrioColors.guestSurfaceVariant,
                              child: const Icon(Icons.image, size: 48),
                            ),
                          )
                        : Container(
                            color: isDark
                                ? AtrioColors.hostSurfaceVariant
                                : AtrioColors.guestSurfaceVariant,
                            child: Icon(
                              Icons.image,
                              size: 48,
                              color: isDark
                                  ? AtrioColors.hostTextTertiary
                                  : AtrioColors.guestTextTertiary,
                            ),
                          ),
                    // Favorite button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: onFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? AtrioColors.error : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    // Type badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AtrioColors.electricViolet,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          listing.type.toUpperCase(),
                          style: AtrioTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: AtrioTypography.headingSmall.copyWith(
                      color: isDark
                          ? AtrioColors.hostTextPrimary
                          : AtrioColors.guestTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (listing.city != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isDark
                              ? AtrioColors.hostTextSecondary
                              : AtrioColors.guestTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${listing.city}${listing.country != null ? ', ${listing.country}' : ''}',
                            style: AtrioTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AtrioColors.hostTextSecondary
                                  : AtrioColors.guestTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '\$${listing.basePrice?.toStringAsFixed(0) ?? '0'}',
                              style: AtrioTypography.priceMedium.copyWith(
                                color: isDark
                                    ? AtrioColors.hostTextPrimary
                                    : AtrioColors.guestTextPrimary,
                              ),
                            ),
                            TextSpan(
                              text: ' /${listing.priceUnit}',
                              style: AtrioTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AtrioColors.hostTextSecondary
                                    : AtrioColors.guestTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Rating
                      if (listing.rating > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Color(0xFFFFB800),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              listing.rating.toStringAsFixed(1),
                              style: AtrioTypography.labelMedium.copyWith(
                                color: isDark
                                    ? AtrioColors.hostTextPrimary
                                    : AtrioColors.guestTextPrimary,
                              ),
                            ),
                            Text(
                              ' (${listing.reviewCount})',
                              style: AtrioTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AtrioColors.hostTextSecondary
                                    : AtrioColors.guestTextSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
