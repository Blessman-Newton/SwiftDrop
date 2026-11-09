path = r'C:\Users\user\SwiftDrop\swiftdrop_flutter\lib\services\tomtom_service.dart'
with open(path, encoding='utf-8') as f:
    s = f.read()

# Try different pattern - look for getRoute and the routing URL
old = '''        '/routing/1/calculateRoute/,:,/json','''
new = '''        '/api/v1/maps/route','''

if old not in s:
    print('NOT_FOUND')
    raise SystemExit
# Also remove key and adjust params
s2 = s.replace(old, new)
# Remove 'key': _apiKey line in route context
s2 = s2.replace("          'key': _apiKey,\n", "")
s2 = s2.replace("          'language': 'en-GB',\n", "")
s2 = s2.replace("          'instructionsType': 'text',\n", "")
s2 = s2.replace("          'routeType': 'fastest',\n", "")
s2 = s2.replace("          'traffic': 'true',\n", "")
# Add fromLat/fromLon/toLat/toLon if missing
oldp = """        queryParameters: {
          'travelMode': travelMode ?? 'car',
        },"""
newp = """        queryParameters: {
          'fromLat': start.latitude,
          'fromLon': start.longitude,
          'toLat': end.latitude,
          'toLon': end.longitude,
          'travelMode': travelMode ?? 'car',
        },"""
if oldp in s2 and "'fromLat'" not in s2:
    s2 = s2.replace(oldp, newp)
with open(path, 'w', encoding='utf-8') as f:
    f.write(s2)
print('done')
