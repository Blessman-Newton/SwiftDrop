path = r'C:\Users\user\SwiftDrop\swiftdrop_flutter\lib\services\tomtom_service.dart'
with open(path, encoding='utf-8') as f:
    s = f.read()

old = '''  Future<TomTomRouteResult?> getRoute(LatLng start, LatLng end, {String? travelMode}) async {
    try {
      final response = await _dio.get(
        '\/routing/1/calculateRoute/\,\:\,\/json',
        queryParameters: {
          'key': _apiKey,
          'language': 'en-GB',
          'instructionsType': 'text',
          'routeType': 'fastest',
          'traffic': 'true',
          'travelMode': travelMode ?? 'car',
        },
      );'''

new = '''  Future<TomTomRouteResult?> getRoute(LatLng start, LatLng end, {String? travelMode}) async {
    try {
      final response = await _dio.get(
        '\/api/v1/maps/route',
        queryParameters: {
          'fromLat': start.latitude,
          'fromLon': start.longitude,
          'toLat': end.latitude,
          'toLon': end.longitude,
          'travelMode': travelMode ?? 'car',
        },
      );'''

if old not in s:
    print('NOT_FOUND')
    raise SystemExit
s2 = s.replace(old, new)
with open(path, 'w', encoding='utf-8') as f:
    f.write(s2)
print('done')
