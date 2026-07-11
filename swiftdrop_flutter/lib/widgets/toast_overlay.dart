import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/merchant_providers.dart';
import 'swift_drop_toast.dart';

class ToastOverlay extends ConsumerWidget {
  final Widget child;

  const ToastOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasts = ref.watch(riderToastsProvider);

    return Stack(
      children: [
        child,
        if (toasts.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Column(
              children: toasts.map((toast) {
                return SwiftDropToast(
                  message: toast.message,
                  type: toast.type,
                  onDismiss: () {
                    ref.read(riderToastsProvider.notifier).dismiss(toast.id);
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
