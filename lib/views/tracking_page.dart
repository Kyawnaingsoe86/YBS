import 'dart:convert';
import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:minimize_flutter_app/minimize_flutter_app.dart';
import 'package:ybs/data/app_data.dart';
import 'package:ybs/main.dart';
import 'package:ybs/models/bus.dart';
import 'package:ybs/models/bus_stop.dart';
import 'package:ybs/models/route_data.dart';

class TrackingPage extends StatefulWidget {
  final List<RouteData> route;
  final GeoPoint userPosition;
  const TrackingPage({
    super.key,
    required this.route,
    required this.userPosition,
  });

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  late BusStop nextStop;
  int currentIndex = 0;
  String currentLocation = "You are not currently tracking!!";
  bool isTracking = false;
  bool locationEnable = false;
  bool notiShown = false;
  bool isMapReady = false;
  String stageImage = "assets/images/navigation.gif";
  late MapController controller;
  OSMOption option = OSMOption(zoomOption: ZoomOption(initZoom: 14));
  late GeoPoint userLocation = widget.userPosition;
  String distance = "";
  List<BusStop> arrivedStops = [];

  showNoti() {
    notiShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(duration: Duration(seconds: 1), content: Text(currentLocation)),
    );
  }

  Future<void> _requestPermissions() async {
    // Android 13+, you need to allow notification permission to display foreground service notification.
    //
    // iOS: If you need notification, ask for permission.
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      // Android 12+, there are restrictions on starting a foreground service.
      //
      // To restart the service on device reboot or unexpected problem, you need to allow below permission.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }
  }

  Future<void> _initService() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
      ),
    );
  }

  Future<ServiceRequestResult> _startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'YBS',
        notificationText: 'Your location is tracking',
        notificationIcon: NotificationIcon(
          metaDataName: "@mipmap/launcher_icon",
        ),
        callback: startCallback,
      );
    }
  }

  Future<ServiceRequestResult> _stopService() {
    return FlutterForegroundTask.stopService();
  }

  Future<void> _onReceiveTaskData(Object data) async {
    final obj = jsonDecode(jsonEncode(data));
    final location = GeoPoint(
      latitude: double.parse(obj["lat"]),
      longitude: double.parse(obj["lon"]),
    );

    if (isMapReady) {
      controller.removeMarker(userLocation);
      userLocation = location;
      controller.addMarker(
        location,
        markerIcon: MarkerIcon(
          icon: Icon(Icons.location_history, size: 50, color: Colors.blue),
        ),
      );
      controller.moveTo(location, animate: false);
    }
    if (isTracking) {
      print("Change Location");
      checkLocation(double.parse(obj["lat"]), double.parse(obj["lon"]));
    }
  }

  liveTrack(BuildContext context) async {
    nextStop = widget.route.first.busStop;
    await _startService();
    setState(() {
      isTracking = true;
    });
  }

  void checkLocation(double lat, double lon) {
    final distance = Geolocator.distanceBetween(
      lat,
      lon,
      widget.route[currentIndex].busStop.latitude,
      widget.route[currentIndex].busStop.longitude,
    );
    if (distance < 30 && distance > 10) {
      currentLocation = widget.route[currentIndex].busStop.name;
      stageImage = "assets/images/bus_stop.gif";
      if (currentIndex < widget.route.length - 1 &&
          widget.route[currentIndex].busStop.id ==
              widget.route[currentIndex + 1].busStop.id) {
        currentIndex = currentIndex + 1;
        currentLocation =
            "$currentLocation\nTransit bus stop!! Take off and transfer to ${widget.route[currentIndex].bus.name}";
        stageImage = "assets/images/bus_stop.gif";
      } else if (currentIndex < widget.route.length - 1 &&
          widget.route[currentIndex].bus.id !=
              widget.route[currentIndex + 1].bus.id) {
        currentLocation =
            "Take off at this bus stop!!\nWalk to ${widget.route[currentIndex + 1].busStop.name} and take ${widget.route[currentIndex + 1].bus.name}";
      }
      if (context.mounted) {
        setState(() {});
      }
      if (notiShown == false) {
        AppData.flutterTts.speak(currentLocation);
        showNoti();
      }
    } else if (distance < 10) {
      arrivedStops.add(widget.route[currentIndex].busStop);
      if (currentIndex < widget.route.length - 1) {
        currentIndex = currentIndex + 1;
        nextStop = widget.route[currentIndex].busStop;
      } else {
        currentLocation = "You are arrived to your destination";
        stageImage = "assets/images/bus_stop.png";
        if (notiShown == false) {
          AppData.flutterTts.speak(currentLocation);
          _stopService();
          AppData.positionStreamSubscription?.cancel();
          showNoti();
        }
      }
      if (context.mounted) {
        setState(() {});
      }
    } else {
      notiShown = false;
      if (currentIndex == 0) {
        stageImage = "assets/images/walking.gif";
      } else {
        stageImage = "assets/images/way_to.gif";
      }
      currentLocation = "Way to ${widget.route[currentIndex].busStop.name}";
      if (context.mounted) {
        setState(() {});
      }
    }
  }

  Future<void> setRoad() async {
    List<GeoPoint> markers = [];
    for (var i in widget.route) {
      markers.add(
        GeoPoint(latitude: i.busStop.latitude, longitude: i.busStop.longitude),
      );
    }
    for (var i in markers) {
      await controller.addMarker(i);
    }
    controller.addMarker(
      userLocation,
      markerIcon: MarkerIcon(
        icon: Icon(Icons.location_history, size: 50, color: Colors.blue),
      ),
    );
    await controller.drawRoad(
      markers.first,
      markers.last,
      intersectPoint: markers,
      roadOption: RoadOption(roadColor: Colors.green, zoomInto: false),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = MapController(initPosition: userLocation);
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
      _initService();
    });
    distance =
        "${(Geolocator.distanceBetween(widget.route.first.busStop.latitude, widget.route.first.busStop.longitude, widget.route.last.busStop.latitude, widget.route.last.busStop.longitude) / 1000).toStringAsFixed(2)} Km";
    liveTrack(context);
  }

  @override
  void dispose() {
    controller.dispose();
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isTracking,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final navigator = Navigator.of(context);
        bool value = await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => AlertDialog(
            content: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.asset(
                      "assets/images/tracking.gif",
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: 320,
                    child: Text(
                      "Your location is currently tracing. Do you want to minimize the app and keep tracking or close the app and stop tracking?",
                      textAlign: TextAlign.center,
                      style: TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: 320,
                height: 50,
                child: MaterialButton(
                  color: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onPressed: () async {
                    try {
                      await MinimizeFlutterApp.minimizeApp();
                    } catch (e) {
                      print('Error minimizing app: $e');
                    }
                    if (context.mounted) {
                      Navigator.pop(context, false);
                    }
                  },
                  child: Text(
                    "Keep Tracking",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 320,
                height: 50,
                child: MaterialButton(
                  color: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onPressed: () async {
                    Navigator.pop(context, true);
                    isTracking = false;
                    _stopService();
                    AppData.positionStreamSubscription?.cancel();
                  },
                  child: Text(
                    "Stop Tracking",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        if (value) {
          navigator.pop(result);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            OSMFlutter(
              controller: controller,
              osmOption: option,
              mapIsLoading: Container(
                alignment: Alignment.center,
                child: Image.asset("assets/images/navigation.gif", width: 120),
              ),
              onMapIsReady: (isReady) async {
                if (isReady) {
                  isMapReady = isReady;
                  await setRoad();
                }
              },
            ),
            Positioned(
              bottom: 0,
              child: TrackingWidget(
                currentLocation: currentLocation,
                distance: distance,
                route: widget.route,
                arrivedStops: arrivedStops,
                nextStop: nextStop,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrackingWidget extends StatefulWidget {
  const TrackingWidget({
    super.key,
    required this.currentLocation,
    required this.distance,
    required this.route,
    required this.arrivedStops,
    required this.nextStop,
  });

  final String currentLocation;
  final String distance;
  final List<RouteData> route;
  final List<BusStop> arrivedStops;
  final BusStop nextStop;

  @override
  State<TrackingWidget> createState() => _TrackingWidgetState();
}

class _TrackingWidgetState extends State<TrackingWidget> {
  bool showTrack = false;

  bool isTransitStop(int index, BusStop stop) {
    if (index < widget.route.length - 1 &&
        widget.route[index + 1].busStop == stop) {
      return true;
    }
    return false;
  }

  bool isShowStop(int index, BusStop stop) {
    if (index > 0 && widget.route[index - 1].busStop == stop) {
      return false;
    }
    return true;
  }

  bool isTransitWay(int index, Bus bus) {
    if (index > 0 && widget.route[index - 1].bus != bus) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(top: 5, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 10,
              children: [
                Container(
                  padding: EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_bus, color: Colors.white),
                      Text("Track", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.route.first.busStop.name,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Text(" ➠ "),
                          Expanded(
                            child: Text(
                              widget.route.last.busStop.name,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      Text(widget.distance, style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showTrack = !showTrack;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Image.asset("assets/images/track.png", width: 24),
                        Text(showTrack ? "Hide" : "Track"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          showTrack
              ? SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            spacing: 5,
                            children: [
                              Icon(Icons.directions_walk, color: Colors.grey),
                              SizedBox(height: 18),
                            ],
                          ),
                        ),
                        for (int i = 0; i < widget.route.length; i++)
                          isTransitStop(i, widget.route[i].busStop)
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 30,
                                        width: 4,
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              widget.arrivedStops.contains(
                                                widget.route[i].busStop,
                                              )
                                              ? Colors.green
                                              : Colors.grey,
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(4),
                                            bottom: Radius.circular(4),
                                          ),
                                        ),
                                      ),
                                      Row(
                                        spacing: 5,
                                        children: [
                                          Icon(
                                            Icons.compare_arrows,
                                            color:
                                                widget.arrivedStops.contains(
                                                  widget.route[i].busStop,
                                                )
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                          widget.route[i].busStop ==
                                                  widget.nextStop
                                              ? SizedBox(
                                                  height: 18,
                                                  child: AnimatedTextKit(
                                                    repeatForever: true,
                                                    animatedTexts: [
                                                      FadeAnimatedText(
                                                        widget
                                                            .route[i]
                                                            .busStop
                                                            .name,
                                                        textStyle: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : widget.arrivedStops.contains(
                                                  widget.route[i].busStop,
                                                )
                                              ? Text(
                                                  widget.route[i].busStop.name,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                )
                                              : Text(
                                                  widget.route[i].busStop.name,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : isShowStop(i, widget.route[i].busStop)
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      isTransitWay(i, widget.route[i].bus)
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                  ),
                                              child: Icon(
                                                Icons.directions_walk,
                                                color:
                                                    widget.arrivedStops
                                                        .contains(
                                                          widget
                                                              .route[i]
                                                              .busStop,
                                                        )
                                                    ? Colors.green
                                                    : Colors.grey,
                                              ),
                                            )
                                          : Container(
                                              height: 30,
                                              width: 4,
                                              margin: EdgeInsets.symmetric(
                                                horizontal: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    widget.arrivedStops
                                                        .contains(
                                                          widget
                                                              .route[i]
                                                              .busStop,
                                                        )
                                                    ? Colors.green
                                                    : Colors.grey,
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                      top: Radius.circular(4),
                                                      bottom: Radius.circular(
                                                        4,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                      Row(
                                        spacing: 5,
                                        children: [
                                          Icon(
                                            Icons.fiber_manual_record,
                                            color:
                                                widget.arrivedStops.contains(
                                                  widget.route[i].busStop,
                                                )
                                                ? Colors.amber
                                                : Colors.grey,
                                          ),
                                          widget.route[i].busStop ==
                                                  widget.nextStop
                                              ? SizedBox(
                                                  height: 18,
                                                  child: AnimatedTextKit(
                                                    repeatForever: true,
                                                    animatedTexts: [
                                                      FadeAnimatedText(
                                                        widget
                                                            .route[i]
                                                            .busStop
                                                            .name,
                                                        textStyle: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : widget.arrivedStops.contains(
                                                  widget.route[i].busStop,
                                                )
                                              ? Text(
                                                  widget.route[i].busStop.name,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                )
                                              : Text(
                                                  widget.route[i].busStop.name,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox(),
                      ],
                    ),
                  ),
                )
              : SizedBox(),
        ],
      ),
    );
  }
}
