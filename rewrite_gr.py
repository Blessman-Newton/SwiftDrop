path = r"C:\Users\user\SwiftDrop\swiftdrop_flutter\lib\services\tomtom_service.dart"
with open(path, encoding="utf-8") as f:
    content = f.read()

start = content.find("  Future<TomTomRouteResult?> getRoute")
end = content.find("\n  static LatLng parseLatLng")
if start == -1 or end == -1:
    raise SystemExit("bad")

new_method = '''  Future<TomTomRouteResult?> getRoute(LatLng start, LatLng end, {String? travelMode}) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.baseUrl}/api/v1/maps/route',
        queryParameters: {
          'fromLat': start.latitude,
          'fromLon': start.longitude,
          'toLat': end.latitude,
          'toLon': end.longitude,
          'travelMode': travelMode ?? 'car',
        },
      );

      final routes = response.data['routes'] as List? ?? [];
      if (routes.isEmpty) return null;

      final route = routes[0];
      final summary = route['summary'];
      final legs = route['legs'] as List? ?? [];

      final points = <LatLng>[];
      final maneuvers = <TomTomManeuver>[];

      for (final leg in legs) {
        for (final point in leg['points'] as List? ?? []) {
          points.add(LatLng(
            point['latitude'].toDouble(),
            point['longitude'].toDouble(),
          ));
        }

        for (final action in leg['actions'] as List? ?? []) {
          final maneuverPoint = action['point'];
          maneuvers.add(TomTomManeuver(
            instruction: action['instruction'] ?? '',
            distanceMeters: (action['length'] ?? 0).toDouble(),
            point: LatLng(
              maneuverPoint['latitude'].toDouble(),
              maneuverPoint['longitude'].toDouble(),
            ),
          ));
        }
      }

      return TomTomRouteResult(
        points: points,
        distanceMeters: (summary['lengthInMeters'] ?? 0).toDouble(),
        durationSeconds: summary['travelTimeInSeconds'] ?? 0,
        maneuvers: maneuvers,
      );
    } catch (e) {
      return null;
    }
  }
'''

new_content = content[:start] + new_method + content[end:]
with open(path, "w", encoding="utf-8") as f:
    f.write(new_content)
print("done")
