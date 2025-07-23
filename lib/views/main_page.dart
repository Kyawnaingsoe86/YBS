import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:ybs/data/app_data.dart';
import 'package:ybs/models/bus_stop.dart';
import 'package:ybs/views/bus_list_page.dart';
import 'package:ybs/views/notification_page.dart';
import 'package:ybs/views/route_finder.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool isLoading = false;

  Position? userPosition;
  int selectedIndex = 0;
  late Widget homeTab;
  late Widget busesTab;
  late Widget notiTab;
  List<Widget> pages = [];

  Future<void> loadBusStops() async {
    final data = await rootBundle.loadString('assets/ybs_dump.json');
    final json = jsonDecode(data);
    for (var i in json) {
      final stops = i["stop_list"];
      for (var stop in stops) {
        AppData.busStopList.add(
          BusStop(
            id: stop["line_no"],
            name: stop["stop_mm"],
            latitude: double.parse(stop["lat"]),
            longitude: double.parse(stop["lng"]),
          ),
        );
      }
    }
  }

  Future<Position?> getPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return await AppData.geolocatorPlatform.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          foregroundNotificationConfig: ForegroundNotificationConfig(
            notificationTitle: "notificationTitle",
            notificationText: "notificationText",
          ),
        ),
      );
    }
    return null;
  }

  initData(BuildContext context) async {
    setState(() {
      isLoading = true;
    });
    await loadBusStops();
    try {
      userPosition = await getPosition();
      if (userPosition != null) {
        homeTab = RouteFinder(
          userPosition: LatLng(userPosition!.latitude, userPosition!.longitude),
        );
      } else {
        homeTab = Center(child: Text("Notification not allowed."));
      }
      busesTab = BusListPage();
      notiTab = NotificationPage();
      if (context.mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
    pages = [homeTab, busesTab, notiTab];
  }

  @override
  void initState() {
    super.initState();
    initData(context);
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
            body: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/icons/icon.png", width: 90),
                  SizedBox(height: 40),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          )
        : Scaffold(
            body: pages[selectedIndex],
            bottomNavigationBar: NavigationBar(
              animationDuration: Duration(milliseconds: 200),
              selectedIndex: selectedIndex,
              destinations: [
                NavigationDestination(icon: Icon(Icons.home), label: "Home"),
                NavigationDestination(
                  icon: Icon(Icons.directions_bus),
                  label: "Buses",
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications),
                  label: "Notification",
                ),
              ],
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
            ),
          );
  }
}
