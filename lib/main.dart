import 'dart:async';

import 'package:flutter/material.dart';
import 'package:futter_google_maps/Config/MapKey.dart';
import 'package:futter_google_maps/Service/location_service.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';

import 'Service/polyline_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taxi Services',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  const MapSample({Key? key}) : super(key: key);

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer();

  static late CameraPosition _position = CameraPosition(
    target: LatLng(-15.721387, -48.0774461),
    zoom: 12,
  );

  Set<Marker> _marker = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    _buildMarkerFromAssets();
    _getMyLocation();
    super.initState();
  }

  BitmapDescriptor? _locationIcon;
  LatLng _currentLocation = _position.target;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
            onPressed: () => showSearchDialog(), icon: const Icon(Icons.search))
      ]),
      body: Stack(children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _position,
          markers: _marker,
          polylines: _polylines,
          onMapCreated: (GoogleMapController controller) async {
            String style = await DefaultAssetBundle.of(context)
                .loadString('assets/map/mapstyle.json');
            controller.setMapStyle(style);
            _controller.complete(controller);
          },
          onCameraMove: (e) => _currentLocation = e.target,
        ),
        Center(
          child: SizedBox(
            height: 40,
            width: 40,
            child: Image.asset("assets/img/marcador.png"),
          ),
        )
      ]),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            elevation: 10,
            onPressed: () => _drawerPolyline(
                LatLng(-15.7940991, -47.8820108), _currentLocation),
            child: const Icon(Icons.settings_ethernet),
          ),
          SizedBox(
            height: 10,
          ),
          FloatingActionButton(
            elevation: 10,
            onPressed: () => _setMarker(_currentLocation),
            child: const Icon(Icons.location_on),
          ),
          SizedBox(
            height: 10,
          ),
          FloatingActionButton(
            elevation: 10,
            onPressed: () => _getMyLocation(),
            child: const Icon(Icons.gps_fixed),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.lightBlue,
        height: 35,
        alignment: Alignment.center,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                      "Lat: ${_currentLocation.latitude.round()}, | Long: ${_currentLocation.longitude.round()}"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _drawerPolyline(LatLng from, LatLng to) async {
    Polyline polyline = await PolylineService().drawPolyline(from, to);
    _polylines.add(polyline);
    setState(() {
      _setMarker(from);
      _setMarker(to);
    });
  }

  Future<void> _setMarker(LatLng _location) async {
    MarkerId markerId = MarkerId(_location.toString());
    Marker newMarker = Marker(
      markerId: markerId,
      icon: BitmapDescriptor.defaultMarker,
      // icon: _locationIcon,
      position: _currentLocation,
      visible: true,
      infoWindow: InfoWindow(
        title: "Location",
        snippet: "${_currentLocation.latitude}, ${_currentLocation.longitude}",
      ),
    );

    setState(() {
      _marker.add(newMarker);
    });

    print("=======================================================");
    print(markerId.value);
  }

  Future<void> _buildMarkerFromAssets() async {
    String iconLocation = "assets/img/local_destino.png";
    if (_locationIcon == null) {
      _locationIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(22, 22)), iconLocation);

      setState(() {});
    }
  }

  Future<void> showSearchDialog() async {
    var p = await PlacesAutocomplete.show(
        context: context,
        apiKey: mapKey,
        mode: Mode.overlay, // Mode.fullscreen and overlay
        language: "pt",
        region: "br",
        offset: 0,
        hint: "Search",
        radius: 1000,
        types: [],
        strictbounds: false,
        components: [Component(Component.country, "br")]);

    _getLocationFromPlaceId(p!.placeId!);
  }

  Future _getLocationFromPlaceId(var placeId) async {
    // LocationData _myLocation = await LocationService().getLocation();
    GoogleMapsPlaces _googleMapsPlaces = GoogleMapsPlaces(
        apiKey: mapKey,
        apiHeaders: await const GoogleApiHeaders().getHeaders());

    PlacesDetailsResponse details =
        await _googleMapsPlaces.getDetailsByPlaceId(placeId);
    _animateCamara(LatLng(details.result.geometry!.location.lat,
        details.result.geometry!.location.lng));
  }

  Future<void> _getMyLocation() async {
    LocationData _myLocation = await LocationService().getLocation();
    _animateCamara(LatLng(_myLocation.latitude!, _myLocation.longitude!));
    print(
        "««««««««««««««««««««««««« - Get My Location - «««««««««««««««««««««««««««««««");
    print(_myLocation);
  }

  Future<void> _animateCamara(LatLng _locationData) async {
    final GoogleMapController controller = await _controller.future;
    CameraPosition _cameraPosition = CameraPosition(
        target: LatLng(_locationData.latitude, _locationData.longitude),
        zoom: 17.4746);

    print(
        "««««««««««««««««««««««« - AnimateCamara - «««««««««««««««««««««««««««««««««");
    print(
        "Animating camera to: (lat ${_locationData.latitude}, ${_locationData.longitude}");
    controller.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
    _setMarker(LatLng(_locationData.latitude, _locationData.longitude));
  }
}
