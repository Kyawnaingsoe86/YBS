import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:minimize_flutter_app/minimize_flutter_app.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:ybs/controllers/hex_color.dart';
import 'package:ybs/data/app_data.dart';
import 'package:ybs/main.dart';
import 'package:ybs/models/bus_stop.dart';
import 'package:ybs/models/route_data.dart';
import 'package:ybs/views/components/bus_card.dart';

enum CurrentStage { wayToBusStop, onBus, transit, arrive }

class RoutePage extends StatefulWidget {
  final List<RouteData> route;
  const RoutePage({super.key, required this.route});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  BusStop? currentStop;
  BusStop? nextStop;
  int currentIndex = 0;
  String currentLocation = "You are not currently tracking!!";
  bool isTracking = false;
  bool locationEnable = false;
  bool notiShown = false;
  CurrentStage currentStage = CurrentStage.wayToBusStop;
  String stageImage = "assets/images/navigation.gif";

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

  void _onReceiveTaskData(Object data) {
    final obj = jsonDecode(jsonEncode(data));
    if (isTracking) {
      print("Change Location");
      checkLocation(double.parse(obj["lat"]), double.parse(obj["lon"]));
    }
  }

  liveTrack(BuildContext context) async {
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
      if (currentIndex < widget.route.length - 1) {
        currentIndex = currentIndex + 1;
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

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
      _initService();
    });
  }

  @override
  void dispose() {
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
        bool value = await showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
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
                SizedBox(height: 30),
                SizedBox(
                  width: 320,
                  height: 50,
                  child: MaterialButton(
                    color: Colors.blue,
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
          ),
        );
        if (value) {
          navigator.pop(result);
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(120),
                    child: Image.asset(stageImage, height: 120),
                  ),
                  SizedBox(
                    width: 320,
                    height: 60,
                    child: Center(child: Text(currentLocation)),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 245, 245, 245),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  Text(widget.route.first.busStop.name),
                  Icon(
                    Icons.directions_bus,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Text(widget.route.last.busStop.name),
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: ListView.builder(
                itemCount: widget.route.length,
                itemBuilder: (context, index) => SizedBox(
                  height: 50,
                  child: TimelineTile(
                    axis: TimelineAxis.vertical,
                    alignment: TimelineAlign.center,
                    startChild:
                        index == 0 ||
                            widget.route[index].bus.id !=
                                widget.route[index - 1].bus.id
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [BusCard(bus: widget.route[index].bus)],
                          )
                        : null,
                    endChild: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        widget.route[index].busStop.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    indicatorStyle: IndicatorStyle(
                      width: 15,
                      height: 15,
                      color: HexColor(widget.route[index].bus.colorCode),
                    ),
                    beforeLineStyle: LineStyle(
                      color: HexColor(widget.route[index].bus.colorCode),
                    ),
                    isFirst: index == 0,
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: isTracking
            ? FloatingActionButton.extended(
                onPressed: () {
                  setState(() {
                    isTracking = false;
                    currentLocation = "You are not currently tracking!!";
                    stageImage = "assets/images/navigation.gif";
                    _stopService();
                    AppData.positionStreamSubscription?.cancel();
                  });
                },
                icon: Icon(Icons.stop),
                label: Text("Stop tracking"),
              )
            : FloatingActionButton.extended(
                onPressed: () {
                  liveTrack(context);
                },
                icon: Icon(Icons.my_location),
                label: Text("Start Tracking"),
              ),
      ),
    );
  }
}
