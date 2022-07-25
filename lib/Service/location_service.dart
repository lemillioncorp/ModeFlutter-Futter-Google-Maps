import "package:location/location.dart";

class LocationService {
  Future<LocationData> getLocation() async {
    Location _location = Location();
    bool _serviceEnable;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnable = await _location.serviceEnabled();

    if (!_serviceEnable) {
      _serviceEnable = await _location.requestService();
      if (!_serviceEnable) {
        throw Exception("Enable service of the Location");
      }

      _permissionGranted = await _location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await _location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          throw Exception("Permission locatoion is granted");
        }
      }
    }
    _locationData = await _location.getLocation();
    return _locationData;
  }
}
