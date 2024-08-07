import 'dart:async';
 
import 'package:flutter/material.dart';
import 'package:flutter_geo_poc/services/http_service.dart';
import 'package:flutter_geo_poc/services/sql_service.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:app_settings/app_settings.dart';
import 'package:url_launcher/url_launcher.dart';
 
 
class HomePageScreen extends StatefulWidget {
  const HomePageScreen({super.key});
 
  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}
 
class _HomePageScreenState extends State<HomePageScreen> {
  final DatabaseService dbService = DatabaseService();
  final HttpService httpService = HttpService();
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
      await permission.Permission.ignoreBatteryOptimizations.request();

      // OPPO Y A SABER PHONES TIENEN QUE ACTIVAR OPCION BACKGROUND!
      //await AppSettings.openAppSettings(type: AppSettingsType.settings);
      
      await permission.Permission.notification.request();      
      _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          return;
        }
      }
 
      _permissionGranted = await location.hasPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          return;
        }
      }
      await location.changeSettings(distanceFilter: 1);

      await enableBackgroundMode();

      location.onLocationChanged.listen((LocationData position) async {
        sqlLogs = [];
        await dbService.insertGeofencingIteration(
          {
            'latitude': position.latitude.toString(), 
            'longitude': position.longitude.toString(), 
            'time': DateTime.fromMillisecondsSinceEpoch(position.time!.toInt()).toString()
          }
        );
        try {
          final httpServiceResponse = await httpService.getRequest('/users/getAllAddresses', {});
          final geofencingIterations = await dbService.getGeofencingIterations();        
          setState(() {
            httpLogs.add("TEST: " + httpServiceResponse.toString());
            for (int i = 0; i < geofencingIterations.length; i++) {
              sqlLogs.add("NEW LOCATION:\n   - latitude: ${geofencingIterations[i].latitude.toString()}\n   - longitude: ${geofencingIterations[i].longitude.toString()}\n   - time: ${geofencingIterations[i].date}");            
            }
          });
        }
        catch (e) {
            httpLogs.add("TEST: ${e}");
        }        
      });
    }

    Future<bool> enableBackgroundMode() async {
      bool bgModeEnabled = await location.isBackgroundModeEnabled();
      if (bgModeEnabled) {
        return true;
      } else {
        try {
          await location.enableBackgroundMode();
        } catch (e) {
          debugPrint(e.toString());
        }
        try {
          bgModeEnabled = await location.enableBackgroundMode();
        } catch (e) {
          debugPrint(e.toString());
        }
        return bgModeEnabled;
      }
    }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: TextButton(child: Text("OPEN EYE"), onPressed: () => 
        launchUrl(Uri.parse('com.cotecna.eye://app')
      )),
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
                      child: Text(log, style: const TextStyle(color: Colors.blue)),
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