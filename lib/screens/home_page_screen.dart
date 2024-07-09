import 'dart:async';
 
import 'package:flutter/material.dart';
import 'package:flutter_geo_poc/services/sql_service.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
 
 
class HomePageScreen extends StatefulWidget {
  const HomePageScreen({super.key});
 
  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}
 
class _HomePageScreenState extends State<HomePageScreen> {
  final DatabaseService dbService = DatabaseService();
  List<GeofencingIteration> geofencingIterations = [];
  List<String> sqlLogs = [];
  List<String> httpLogs = [];
 
  Location location = Location();
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
 
  @override
    void initState() {
      super.initState();
        startLocationUpdates();
    }
 
    startLocationUpdates() async {
      await permission.Permission.notification.request();
      _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          return;
        }
      }
 
      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          return;
        }
      }
      await location.changeSettings(distanceFilter: 1);
      await location.enableBackgroundMode(enable: true);
      location.onLocationChanged.listen((LocationData position) async {
        sqlLogs = [];
        httpLogs = [];
        await dbService.insertGeofencingIteration(
          {
            'latitude': position.latitude.toString(), 
            'longitude': position.longitude.toString(), 
            'time': DateTime.fromMillisecondsSinceEpoch(position.time!.toInt()).toString()
          }
        );
        final geofencingIterations = await dbService.getGeofencingIterations();        
        setState(() {
          httpLogs.add("NEW LOCATION:\n   - latitude: ${geofencingIterations[0].latitude.toString()}\n   - longitude: ${geofencingIterations[0].longitude.toString()}\n   - time: ${geofencingIterations[0].date}");
          for (int i = 0; i < geofencingIterations.length; i++) {
            sqlLogs.add("NEW LOCATION:\n   - latitude: ${geofencingIterations[i].latitude.toString()}\n   - longitude: ${geofencingIterations[i].longitude.toString()}\n   - time: ${geofencingIterations[i].date}");
            
          }
        });
      });
    }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofencing POC'),
      ),
      body: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: sqlLogs.map((log) =>
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(log),
                  )
                ).toList(),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children:
                  httpLogs.map((log) =>
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(log, style: const TextStyle(color: Colors.red)),
                    )
                  ).toList(),
                ),
              ),
            ),
          ],
        )
      )
    );
  }
}