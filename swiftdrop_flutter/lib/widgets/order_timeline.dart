import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

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
}
