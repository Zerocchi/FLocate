import 'dart:async';

import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FLocate"),
      ),
      body: Content(),
    );
  }
}

class Content extends StatefulWidget {
  @override
  _ContentState createState() => _ContentState();
}

class _ContentState extends State<Content> {

  Geolocator geolocator = Geolocator();
  LocationOptions locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
  Stream<Position> position;
  GoogleMapController mapController;
  Placemark address;
  String addressString;
  Marker marker;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
      mapController.addMarker(MarkerOptions(
        position: LatLng(0.0, 0.0)
      )).then((m)=>marker=m);
    });
  }

  Stream<Position> _getCurrentLocation() {
    return geolocator.getPositionStream(locationOptions);
  }

  _mapCurrentLocation(Position position) {
    _getCurrentLocation().listen((position) {
      mapController
      .animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          tilt: 30.0,
          zoom: 17.0,
        ),
      ));
      mapController.updateMarker(marker, MarkerOptions(
        position: LatLng(position.latitude, position.longitude)
      ));
    });
  }

  Future<List<Placemark>> _getPlacemarks(Position position) async {
    return await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
  }

  Widget _addressCard(Placemark address, Position position) {
    return Card(
      elevation: 4.0,
      child: Table(
        border: TableBorder.all(width: 0.5),
        children: [
          TableRow(children: [Text("Latitude"), Text(position?.latitude.toString() ?? "No data")]),
          TableRow(children: [Text("Longitude"), Text(position?.longitude.toString() ?? "No data")]),
          TableRow(children: [Text("Name"), Text(address?.name ?? "No data")]),
          TableRow(children: [Text("Locality"), Text(address?.locality ?? "No data")]),
          TableRow(children: [Text("Postal Code"), Text(address?.postalCode ?? "No data")]),
          TableRow(children: [Text("State/Admin Area"), Text(address?.administrativeArea ?? "No data")]),
          TableRow(children: [Text("Country"), Text(address?.country ?? "No data")]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: null,
      stream: _getCurrentLocation(),
      builder: (BuildContext context, AsyncSnapshot<Position> snapshot) {
        if(!snapshot.hasData) return Center(child: CircularProgressIndicator());
        else {
          Position position = snapshot.data;
          _mapCurrentLocation(position);
          _getPlacemarks(position)
            .then((placemark){
              setState(() {
                address = placemark[0];
              });
            });
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: null,
                height: 400.0,
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                ),
              ),
              Expanded(child: _addressCard(address, position),),
            ]
          );
        }
      },
    );
  }
}