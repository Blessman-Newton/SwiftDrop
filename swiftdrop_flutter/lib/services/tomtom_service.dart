import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class TomTomSearchResult {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const TomTomSearchResult({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}

class TomTomRouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final int durationSeconds;
  final List<TomTomManeuver> maneuvers;

  const TomTomRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuvers,
  });

  String get distanceText {
    if (distanceMeters < 1000) return '${distanceMeters.round()}m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }

  String get durationText {
    final mins = durationSeconds ~/ 60;
    if (mins < 60) return '$mins min';
    final hrs = mins ~/ 60;
    final remMins = mins % 60;
    return '$hrs hr $remMins min';
  }
}

class TomTomManeuver {
  final String instruction;
  final double distanceMeters;
  final LatLng point;

  const TomTomManeuver({
    required this.instruction,
    required this.distanceMeters,
    required this.point,
  });

  String get distanceText {
    if (distanceMeters < 1000) return '${distanceMeters.round()}m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }
}

class TomTomService {
  static const String _apiKey = 'ewNoi22dTJTv9gbvIzlOdUXQZULLTKgy';
  static const String _baseUrl = 'https://api.tomtom.com';
  static const String _tileUrl =
      'https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key=$_apiKey';

  // Default center: Sunyani, Ghana
  static const LatLng defaultCenter = LatLng(7.3349, -2.3266);

  final Dio _dio;

  TomTomService() : _dio = Dio();

  static String get tileUrl => _tileUrl;

  Future<List<TomTomSearchResult>> search(String query, {LatLng? bias}) async {
    if (query.trim().isEmpty) return [];

    final params = <String, dynamic>{
      'key': _apiKey,
      'query': query,
      'limit': 8,
      'countrySet': 'GH',
      'language': 'en-GB',
    };
    if (bias != null) {
      params['lat'] = bias.latitude;
      params['lon'] = bias.longitude;
      params['radius'] = 50000;
    }

    try {
      final response = await _dio.get(
        '$_baseUrl/search/2/search/${Uri.encodeComponent(query)}.json',
        queryParameters: params,
      );

      final results = <TomTomSearchResult>[];
      final features = response.data['results'] as List? ?? [];
      for (final f in features) {
        final pos = f['position'];
        final addr = f['address'];
        if (pos != null) {
          results.add(TomTomSearchResult(
            name: f['poi']?['name'] ?? addr?['freeformAddress'] ?? query,
            address: addr?['freeformAddress'] ?? '',
            latitude: pos['lat'].toDouble(),
            longitude: pos['lon'].toDouble(),
          ));
        }
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  Future<TomTomSearchResult?> reverseGeocode(LatLng point) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/search/2/reverseGeocode/${point.latitude},${point.longitude}.json',
        queryParameters: {
          'key': _apiKey,
          'language': 'en-GB',
          'radius': 100,
        },
      );

      final results = response.data['addresses'] as List? ?? [];
      if (results.isNotEmpty) {
        final addr = results[0]['address'] as Map<String, dynamic>?;
        String formattedShort = '';
        
        if (addr != null) {
          final street = addr['streetName'] as String? ?? addr['street'] as String? ?? '';
          final subdivision = addr['municipalitySubdivision'] as String? ?? '';
          final municipality = addr['municipality'] as String? ?? addr['localName'] as String? ?? '';

          final parts = <String>[];
          if (subdivision.isNotEmpty) {
            parts.add(subdivision);
          }
          if (street.isNotEmpty) {
            parts.add(street);
          }
          if (parts.isEmpty && municipality.isNotEmpty) {
            parts.add(municipality);
          }

          formattedShort = parts.isNotEmpty ? parts.join(', ') : (addr['freeformAddress'] as String? ?? '');
        }

        if (formattedShort.isEmpty) {
          formattedShort = 'Current Location';
        }

        return TomTomSearchResult(
          name: formattedShort,
          address: formattedShort,
          latitude: point.latitude,
          longitude: point.longitude,
        );
      }
    } catch (e) {}
    return null;
  }

  Future<TomTomRouteResult?> calculateRoute(
    LatLng origin,
    LatLng destination, {
    String? travelMode,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/routing/1/calculateRoute/${origin.latitude},${origin.longitude}:${destination.latitude},${destination.longitude}/json',
        queryParameters: {
          'key': _apiKey,
          'language': 'en-GB',
          'instructionsType': 'text',
          'routeType': 'fastest',
          'traffic': 'true',
          'travelMode': travelMode ?? 'car',
        },
      );

      final routes = response.data['routes'] as List? ?? [];
      if (routes.isEmpty) return null;

      final route = routes[0];
      final summary = route['summary'];
      final legs = route['legs'] as List? ?? [];

      // Decode polyline from legs
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

  static LatLng parseLatLng(dynamic lat, dynamic lng) {
    if (lat == null || lng == null) return defaultCenter;
    final latD = lat is num ? lat.toDouble() : double.tryParse(lat.toString()) ?? 7.3349;
    final lngD = lng is num ? lng.toDouble() : double.tryParse(lng.toString()) ?? -2.3266;
    return LatLng(latD, lngD);
  }
}
