import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../core/utils/extensions.dart';

/// Single line of a price breakdown — label on the left, formatted CLP on
/// the right. Use [bold] for the final "Total" line.
class PriceBreakdownItem {
  final String label;
  final double amount;
  final bool bold;
  const PriceBreakdownItem(this.label, this.amount, {this.bold = false});
}

/// Airbnb-style price card. Shows only the [total] up-front, plus a "Ver
/// desglose" affordance that opens a bottom sheet with the [items]
/// breakdown. Keeps guest-facing pricing visually clean while preserving
/// transparency for users who want the math.
class PriceBreakdownCard extends StatelessWidget {
  /// Description shown in small grey text above the total (e.g. how units
  /// were computed). Optional.
  final String? caption;

  /// What to label the final big number. Defaults to "Total".
  final String totalLabel;

  /// Sum the guest will be charged.
  final double total;

  /// Itemized rows surfaced inside the bottom sheet.
  final List<PriceBreakdownItem> items;

  /// Optional widget rendered below the breakdown rows in the sheet
  /// (e.g. a promo banner). Rendered with default padding.
  final Widget? footer;

  const PriceBreakdownCard({
    super.key,
    required this.total,
    required this.items,
    this.caption,
    this.totalLabel = 'Total',
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (caption != null) ...[
            Text(
              caption!,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AtrioColors.guestTextSecondary,
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalLabel,
                style: AtrioTypography.headingSmall.copyWith(
                  color: AtrioColors.guestTextPrimary,
                ),
              ),
              Text(
                total.toCLP,
                style: AtrioTypography.priceLarge.copyWith(
                  color: AtrioColors.guestTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _showBreakdownSheet(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Ver desglose',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AtrioColors.guestTextPrimary,
                      decoration: TextDecoration.underline,
                      decorationThickness: 1.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AtrioColors.guestTextPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBreakdownSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BreakdownSheet(
        title: 'Desglose de precio',
        items: items,
        total: total,
        totalLabel: totalLabel,
        footer: footer,
      ),
    );
  }
}

class _BreakdownSheet extends StatelessWidget {
  final String title;
  final List<PriceBreakdownItem> items;
  final double total;
  final String totalLabel;
  final Widget? footer;

  const _BreakdownSheet({
    required this.title,
    required this.items,
    required this.total,
    required this.totalLabel,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AtrioColors.guestBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AtrioColors.guestCardBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text(
            title,
            style: AtrioTypography.headingSmall.copyWith(
              color: AtrioColors.guestTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: item.bold ? FontWeight.w700 : FontWeight.w500,
                        color: AtrioColors.guestTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.amount.toCLP,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: item.bold ? FontWeight.w800 : FontWeight.w600,
                      color: AtrioColors.guestTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 4),
            footer!,
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AtrioColors.guestCardBorder),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalLabel,
                style: AtrioTypography.headingSmall.copyWith(
                  color: AtrioColors.guestTextPrimary,
                ),
              ),
              Text(
                total.toCLP,
                style: AtrioTypography.priceLarge.copyWith(
                  color: AtrioColors.guestTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
