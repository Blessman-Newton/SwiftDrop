import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'app_image.dart';

/// Opens the two-part post-delivery rating sheet (rate driver + rate food).
Future<void> showOrderRatingSheet(BuildContext context, Order order) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OrderRatingSheet(order: order),
  );
}

class _OrderRatingSheet extends StatefulWidget {
  final Order order;
  const _OrderRatingSheet({required this.order});

  @override
  State<_OrderRatingSheet> createState() => _OrderRatingSheetState();
}

class _OrderRatingSheetState extends State<_OrderRatingSheet> {
  int _driverRating = 0;
  int _foodRating = 0;
  final _driverNote = TextEditingController();
  final _foodNote = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _driverNote.dispose();
    _foodNote.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'swiftdrop_rating_${widget.order.id}';
    await prefs.setString(
      key,
      jsonEncode({
        'driverRating': _driverRating,
        'foodRating': _foodRating,
        'driverNote': _driverNote.text,
        'foodNote': _foodNote.text,
        'ratedAt': DateTime.now().toIso8601String(),
      }),
    );
    if (mounted) setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final driverName = widget.order.riderName ?? 'your rider';

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: BoxDecoration(
        color: AppColors.background(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _submitted
          ? _buildThanks(isDark)
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border(isDark),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Rate your order', style: AppText.heading(isDark)),
                  const SizedBox(height: 4),
                  Text(
                    'Your feedback helps us improve future orders.',
                    style: AppText.secondary(isDark),
                  ),
                  const SizedBox(height: 20),

                  // ── Driver ──
                  _sectionCard(
                    isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipOval(
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: (widget.order.riderAvatar ?? '')
                                        .isNotEmpty
                                    ? AppImage(
                                        url: widget.order.riderAvatar!,
                                        fit: BoxFit.cover)
                                    : Container(
                                        color: AppColors.primary,
                                        alignment: Alignment.center,
                                        child: Text(
                                          driverName
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'How was your experience with $driverName?',
                                style: AppText.title(isDark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _stars(_driverRating,
                            (v) => setState(() => _driverRating = v)),
                        const SizedBox(height: 12),
                        _noteField(_driverNote, 'Leave a note for the driver…',
                            isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Food ──
                  _sectionCard(
                    isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('How was your food?',
                            style: AppText.title(isDark)),
                        const SizedBox(height: 12),
                        _stars(_foodRating,
                            (v) => setState(() => _foodRating = v)),
                        const SizedBox(height: 12),
                        _noteField(
                            _foodNote, 'Tell us about the food…', isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (_driverRating == 0 && _foodRating == 0)
                          ? null
                          : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Submit feedback',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildThanks(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded,
                color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Thank you!', style: AppText.heading(isDark)),
          const SizedBox(height: 8),
          Text(
            'Your feedback has been submitted and helps us improve future orders.',
            textAlign: TextAlign.center,
            style: AppText.secondary(isDark),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Done',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: child,
    );
  }

  Widget _stars(int value, ValueChanged<int> onChanged) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < value;
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: filled ? const Color(0xFFFFCB11) : Colors.grey,
              size: 34,
            ),
          ),
        );
      }),
    );
  }

  Widget _noteField(
      TextEditingController ctrl, String hint, bool isDark) {
    return TextField(
      controller: ctrl,
      maxLines: 2,
      style: GoogleFonts.inter(
          fontSize: 13, color: AppColors.textPrimary(isDark)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textSecondary(isDark)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: AppColors.background(isDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(isDark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
