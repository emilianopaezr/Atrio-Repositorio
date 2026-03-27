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
                    // Price badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AtrioColors.neonLime,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '\$${listing.basePrice?.toStringAsFixed(0) ?? '0'}',
                                style: AtrioTypography.priceMedium.copyWith(
                                  color: Colors.black,
                                  fontSize: 15,
                                ),
                              ),
                              TextSpan(
                                text: '/${_priceUnitLabel(listing)}',
                                style: AtrioTypography.bodySmall.copyWith(
                                  color: Colors.black87,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                    // Bottom gradient for readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.15)],
                          ),
                        ),
                      ),
                    ),
                    // Image count indicator
                    if (listing.images.length > 1)
                      Positioned(
                        top: 12,
                        right: 56,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '1 / ${listing.images.length}',
                            style: AtrioTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge + rating row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AtrioColors.neonLime.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          listing.type == 'space'
                              ? 'Espacio'
                              : listing.type == 'experience'
                                  ? 'Experiencia'
                                  : 'Servicio',
                          style: AtrioTypography.caption.copyWith(
                            color: AtrioColors.neonLimeDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (listing.rating > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB800)),
                            const SizedBox(width: 3),
                            Text(
                              listing.rating.toStringAsFixed(1),
                              style: AtrioTypography.labelMedium.copyWith(
                                color: isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '(${listing.reviewCount})',
                              style: AtrioTypography.bodySmall.copyWith(
                                color: isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    listing.title,
                    style: AtrioTypography.headingSmall.copyWith(
                      color: isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (listing.city != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${listing.city}${listing.country != null ? ', ${listing.country}' : ''}',
                            style: AtrioTypography.bodySmall.copyWith(
                              color: isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

  String _priceUnitLabel(Listing listing) {
    switch (listing.priceUnit) {
      case 'night': return 'noche';
      case 'hour': return 'hora';
      case 'session': return 'sesión';
      case 'person': return 'persona';
      case 'day': return 'día';
      default: return listing.priceUnit;
    }
  }
}
