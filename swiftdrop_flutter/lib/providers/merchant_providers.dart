import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

// Rider Dark Mode
final riderDarkModeProvider = StateProvider<bool>((ref) => false);

// Rider Online Status
final riderOnlineProvider = StateProvider<bool>((ref) => false);

// Rider Active Screen
final riderScreenProvider = StateProvider<RiderScreen>((ref) => RiderScreen.login);

// Rider Delivery State
final deliveryStateProvider = StateProvider<DeliveryState>((ref) => DeliveryState.enRoute);

// Rider Toasts
final riderToastsProvider =
    StateNotifierProvider<ToastsNotifier, List<ToastMessage>>((ref) {
  return ToastsNotifier();
});

class ToastsNotifier extends StateNotifier<List<ToastMessage>> {
  ToastsNotifier() : super([]);

  void add(String message, ToastType type) {
    final toast = ToastMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      type: type,
    );
    state = [...state, toast];
  }

  void dismiss(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}

// Rider Navigation Distance
final navigationDistanceProvider = StateProvider<int>((ref) => 200);
