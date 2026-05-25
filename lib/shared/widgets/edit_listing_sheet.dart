import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_colors.dart';
import '../../core/services/database_service.dart';
import '../../l10n/app_localizations.dart';

/// Bottom sheet for editing the most commonly tweaked fields on a
/// listing: title, description, base price, and (optionally) cleaning
/// fee. Used both by the host-listings screen and by the Quick
/// Services host-owned detail view.
///
/// Deep edits (photos, location, rules, modality, etc.) are out of
/// scope here — those still require deleting + recreating the listing
/// for now. Surface fields are intentionally constrained to keep the
/// flow short and avoid accidentally turning a "service" into an
/// "experience" via a category change.
///
/// Returns `true` to the caller if the row was saved, `null` if the
/// user dismissed without saving.
Future<bool?> showEditListingSheet(
  BuildContext context, {
  required Map<String, dynamic> listing,
  bool showCleaningFee = true,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: _EditListingSheet(
        listing: listing,
        showCleaningFee: showCleaningFee,
      ),
    ),
  );
}

class _EditListingSheet extends StatefulWidget {
  final Map<String, dynamic> listing;
  final bool showCleaningFee;

  const _EditListingSheet({
    required this.listing,
    required this.showCleaningFee,
  });

  @override
  State<_EditListingSheet> createState() => _EditListingSheetState();
}

class _EditListingSheetState extends State<_EditListingSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _cleaningController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: (widget.listing['title'] ?? '').toString());
    _descController = TextEditingController(
        text: (widget.listing['description'] ?? '').toString());
    _priceController = TextEditingController(
        text:
            ((widget.listing['base_price'] as num?)?.toInt() ?? 0).toString());
    _cleaningController = TextEditingController(
        text: ((widget.listing['cleaning_fee'] as num?)?.toInt() ?? 0)
            .toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _cleaningController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    final price = int.tryParse(_priceController.text.trim());

    if (title.isEmpty) {
      setState(() => _error = l.hostListingsEditValidationTitle);
      return;
    }
    if (price == null || price < 0) {
      setState(() => _error = l.hostListingsEditValidationPrice);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final updates = <String, dynamic>{
      'title': title,
      'description': _descController.text.trim(),
      'base_price': price,
    };
    if (widget.showCleaningFee) {
      final cleaning = int.tryParse(_cleaningController.text.trim()) ?? 0;
      updates['cleaning_fee'] = cleaning;
    }

    try {
      await DatabaseService.updateListing(widget.listing['id'] as String, updates);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l.hostListingsEditError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AtrioColors.hostBackground
        : AtrioColors.guestBackground;
    final surface = isDark
        ? AtrioColors.hostSurface
        : AtrioColors.guestSurface;
    final border = isDark
        ? AtrioColors.hostCardBorder
        : AtrioColors.guestCardBorder;
    final textP = isDark
        ? AtrioColors.hostTextPrimary
        : AtrioColors.guestTextPrimary;
    final textS = isDark
        ? AtrioColors.hostTextSecondary
        : AtrioColors.guestTextSecondary;
    final textT = isDark
        ? AtrioColors.hostTextTertiary
        : AtrioColors.guestTextTertiary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                l.hostListingsEditTitle,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textP,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 22),

              _Label(text: l.hostListingsEditFieldTitle, color: textT),
              const SizedBox(height: 8),
              _Field(
                controller: _titleController,
                surface: surface,
                border: border,
                textColor: textP,
                hintColor: textT,
              ),
              const SizedBox(height: 16),

              _Label(text: l.hostListingsEditFieldDescription, color: textT),
              const SizedBox(height: 8),
              _Field(
                controller: _descController,
                surface: surface,
                border: border,
                textColor: textP,
                hintColor: textT,
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              _Label(text: l.hostListingsEditFieldPrice, color: textT),
              const SizedBox(height: 8),
              _Field(
                controller: _priceController,
                surface: surface,
                border: border,
                textColor: textP,
                hintColor: textT,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              if (widget.showCleaningFee) ...[
                const SizedBox(height: 16),
                _Label(
                  text: l.hostListingsEditFieldCleaningFee,
                  color: textT,
                ),
                const SizedBox(height: 8),
                _Field(
                  controller: _cleaningController,
                  surface: surface,
                  border: border,
                  textColor: textP,
                  hintColor: textT,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AtrioColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: AtrioColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AtrioColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _saving ? null : _save,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 56,
                    decoration: BoxDecoration(
                      color: _saving
                          ? AtrioColors.neonLime.withValues(alpha: 0.4)
                          : AtrioColors.neonLime,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              l.hostListingsEditSave,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: -0.3,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: Text(
                    l.btnCancel,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textS,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final Color surface;
  final Color border;
  final Color textColor;
  final Color hintColor;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.controller,
    required this.surface,
    required this.border,
    required this.textColor,
    required this.hintColor,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        cursorColor: textColor,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: hintColor,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
