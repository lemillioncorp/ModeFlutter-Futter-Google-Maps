import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:futter_google_maps/Config/MapKey.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolylineService {
  Future<Polyline> drawPolyline(LatLng from, LatLng to) async {
    List<LatLng> polylineCoordenates = [];

    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        mapKey,
        PointLatLng(from.latitude, from.longitude),
        PointLatLng(to.latitude, to.longitude));

    for (var point in result.points) {
      polylineCoordenates.add(LatLng(point.latitude, point.longitude));
    }
    _calcDistance(polylineCoordenates);
    return Polyline(
        polylineId: PolylineId("polyline_id ${result.points.length}"),
        color: Colors.blue,
        width: 5,
        points: polylineCoordenates);
  }

  void _calcDistance(List<LatLng> polylineCoordenates) async {
    double totalDistance = 0.0;

    // Calculating the total distance by adding the distance
    // between small segments
    for (int i = 0; i < polylineCoordenates.length - 1; i++) {
      totalDistance += _coordinateDistance(
        polylineCoordenates[i].latitude,
        polylineCoordenates[i].longitude,
        polylineCoordenates[i + 1].latitude,
        polylineCoordenates[i + 1].longitude,
      );
    }

    print("distance = ${totalDistance.toStringAsFixed(2)} km");
  }

  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
