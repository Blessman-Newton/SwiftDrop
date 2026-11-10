import 'dart:math' as math;

const double baseDeliveryFee = 10.0;
const double perKilometerDeliveryFee = 5.0;

double calculateDeliveryFee({
  required double? pickupLat,
  required double? pickupLng,
  required double? deliveryLat,
  required double? deliveryLng,
}) {
  if ([pickupLat, pickupLng, deliveryLat, deliveryLng].any((value) => value == null)) {
    return baseDeliveryFee;
  }

  final lat1 = _radians(pickupLat!);
  final lat2 = _radians(deliveryLat!);
  final deltaLat = _radians(deliveryLat - pickupLat);
  final deltaLng = _radians(deliveryLng! - pickupLng!);
  final a = math.pow(math.sin(deltaLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLng / 2), 2);
  final distanceKm = 6371.0 * 2 * math.asin(math.sqrt(a));
  final billableKilometers = distanceKm > 0 ? distanceKm.ceil() : 0;
  return baseDeliveryFee + billableKilometers * perKilometerDeliveryFee;
}

double _radians(double value) => value * math.pi / 180;
