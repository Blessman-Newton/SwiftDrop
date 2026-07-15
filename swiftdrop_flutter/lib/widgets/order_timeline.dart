import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'app_image.dart';

/// Vertical stepper showing an order's progress through the delivery lifecycle.
/// Driven by the unified [OrderStatus] model so it stays in sync with the
/// backend state machine.
class OrderTimeline extends StatelessWidget {
  final Order order;
  final bool isDark;

  const OrderTimeline({super.key, required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final stages = order.orderType == 'parcel'
        ? OrderStatusX.parcelTimelineStages
        : OrderStatusX.timelineStages;
    final currentIndex = order.status.timelineIndex;
    final cancelled = order.status.isCancelled;

    if (cancelled) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.status(OrderStatus.cancelled).withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel_rounded,
                color: AppColors.status(OrderStatus.cancelled), size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'This order was cancelled.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(stages.length, (i) {
        final done = i < currentIndex;
        final active = i == currentIndex;
        final isLast = i == stages.length - 1;
        final color = (done || active) ? AppColors.primary : AppColors.border(isDark);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Node + connector
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (done || active)
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: (done || active)
                            ? AppColors.primary
                            : AppColors.textSecondary(isDark).withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : active
                            ? const Center(
                                child: SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: done ? AppColors.primary : color,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              // Label
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stages[i].label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w600,
                          color: (done || active)
                              ? AppColors.textPrimary(isDark)
                              : AppColors.textSecondary(isDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stages[i].description,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                      // Driver profile appears once the rider has picked up.
                      if (i == 3 &&
                          currentIndex >= 3 &&
                          (order.riderName ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _driverCard(context),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _driverCard(BuildContext context) {
    final phone = order.riderPhone ?? '';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: (order.riderAvatar ?? '').isNotEmpty
                      ? AppImage(url: order.riderAvatar!, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.primary,
                          alignment: Alignment.center,
                          child: Text(
                            order.riderName!.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your rider',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                    Text(
                      order.riderName!,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                    if ((order.riderVehicleType ?? '').isNotEmpty)
                      Text(
                        order.riderVehicleType!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _driverActionButton(
                  context,
                  icon: Icons.call,
                  label: 'Call',
                  filled: true,
                  onTap: () => _launch(context, 'tel', phone, 'Calling'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _driverActionButton(
                  context,
                  icon: Icons.chat_bubble_outline,
                  label: 'Text',
                  filled: false,
                  onTap: () => _launch(context, 'sms', phone, 'Texting'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _driverActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: filled ? Colors.white : AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(BuildContext context, String scheme, String phone,
      String verb) async {
    if (phone.isEmpty) return;
    final uri = Uri(scheme: scheme, path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$verb ${order.riderName} ($phone)'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}
