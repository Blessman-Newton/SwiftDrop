path = r"C:\Users\user\SwiftDrop\swiftdrop_flutter\lib\services\tomtom_service.dart"
with open(path, encoding="utf-8") as f:
    s = f.read()
if "Future<TomTomRouteResult?> getRoute" not in s and "calculateRoute" in s:
    wrapper = """

  Future<TomTomRouteResult?> getRoute(LatLng start, LatLng end, {String? travelMode}) async {
    return calculateRoute(start, end, travelMode: travelMode);
  }
"""
    idx = s.find("\n  static LatLng parseLatLng")
    if idx >= 0:
        s2 = s[:idx] + wrapper + s[idx:]
        with open(path, "w", encoding="utf-8") as f:
            f.write(s2)
        print("added")
    else:
        print("noidx")
else:
    print("exists")
