import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:ybs/controllers/hex_color.dart';
import 'package:ybs/controllers/search_route_controller.dart';
import 'package:ybs/data/app_data.dart';
import 'package:ybs/models/bus.dart';
import 'package:ybs/models/bus_stop.dart';
import 'package:ybs/models/route_data.dart';
import 'package:latlong2/latlong.dart';
import 'package:ybs/views/tracking_page.dart';

class RouteFinder extends StatefulWidget {
  final LatLng userPosition;
  const RouteFinder({super.key, required this.userPosition});

  @override
  State<RouteFinder> createState() => _RouteFinderState();
}

class _RouteFinderState extends State<RouteFinder> {
  MapController controller = MapController(
    initMapWithUserPosition: UserTrackingOption(),
  );
  OSMOption option = OSMOption(
    zoomOption: ZoomOption(initZoom: 13),
    showZoomController: true,
  );
  List<GeoPoint> markers = [];
  LatLng? pointLocation;
  BusStop? selectedStartBusStop;
  BusStop? selectedEndBusStop;
  List<RouteData> selectedBusRoute = [];
  List<LatLng> routePoints = [];
  bool isLoading = false;

  String start = "";
  String end = "";

  Future<void> setBusStopMarker(BuildContext context) async {
    markers.clear();
    for (var i in AppData.testStop) {
      markers.add(GeoPoint(latitude: i.latitude, longitude: i.longitude));
    }
    for (var i in markers) {
      await controller.addMarker(
        i,
        markerIcon: MarkerIcon(
          icon: Icon(Icons.location_on_rounded, size: 50, color: Colors.red),
        ),
      );
    }
  }

  clearAllData() {
    selectedStartBusStop = null;
    selectedEndBusStop = null;
    start = "";
    end = "";
    controller.removeMarkers(markers);
    controller.clearAllRoads();
    markers.clear();
    setState(() {});
  }

  showAvaliableRoute(BuildContext context) {
    if (selectedStartBusStop != null && selectedEndBusStop != null) {
      List<List<RouteData>> routeDataList = SearchRouteController().searchRoute(
        selectedStartBusStop!,
        selectedEndBusStop!,
      );
      setState(() {});
      showModalBottomSheet(
        context: context,
        builder: (context) => AvaliableRouteWidget(
          selectedStartBusStop: selectedStartBusStop,
          selectedEndBusStop: selectedEndBusStop,
          routeList: routeDataList,
          onSelectRoute: (selectedRoute) async {
            selectedBusRoute = selectedRoute;
            Navigator.pop(context);
            await controller.removeMarkers(markers);
            await controller.clearAllRoads();
            markers.clear();
            for (var i in selectedRoute) {
              markers.add(
                GeoPoint(
                  latitude: i.busStop.latitude,
                  longitude: i.busStop.longitude,
                ),
              );
            }
            for (var i in markers) {
              await controller.addMarker(i);
            }
            await controller.drawRoad(
              GeoPoint(
                latitude: selectedRoute.first.busStop.latitude,
                longitude: selectedRoute.first.busStop.longitude,
              ),
              GeoPoint(
                latitude: selectedRoute.last.busStop.latitude,
                longitude: selectedRoute.last.busStop.longitude,
              ),
              intersectPoint: [
                for (var i in selectedRoute)
                  GeoPoint(
                    latitude: i.busStop.latitude,
                    longitude: i.busStop.longitude,
                  ),
              ],
              roadOption: RoadOption(
                roadColor: Colors.red,
                roadWidth: 10,
                zoomInto: false,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              alignment: Alignment.bottomCenter,
              children: [
                OSMFlutter(
                  controller: controller,
                  osmOption: option,
                  onMapIsReady: (p0) async {
                    await setBusStopMarker(context);
                  },
                ),

                Positioned(
                  top: 40,
                  left: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        context: context,
                        builder: (context) => BusStopSearch(
                          onSelect: (selectedStop) {
                            selectedStartBusStop = selectedStop;
                            setState(() {
                              start = selectedStop.name;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ).then((value) {
                        if (context.mounted) {
                          showAvaliableRoute(context);
                        }
                      });
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        spacing: 5,
                        children: [
                          Icon(Icons.location_on, color: Colors.red),
                          start == ""
                              ? Text(
                                  "စမှတ်တိုင်",
                                  style: TextStyle(color: Colors.grey),
                                )
                              : Text(start),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 100,
                  left: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        context: context,
                        builder: (context) => BusStopSearch(
                          onSelect: (selectedStop) {
                            selectedEndBusStop = selectedStop;
                            setState(() {
                              end = selectedStop.name;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ).then((value) {
                        if (context.mounted) {
                          showAvaliableRoute(context);
                        }
                      });
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        spacing: 5,
                        children: [
                          Icon(Icons.location_on, color: Colors.blue),
                          end == ""
                              ? Text(
                                  "ဆုံးမှတ်တိုင်",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                )
                              : Text(
                                  end,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: IconButton.filled(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.white),
                    ),
                    onPressed: () {
                      clearAllData();
                      if (selectedBusRoute.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrackingPage(
                              route: selectedBusRoute,
                              userPosition: GeoPoint(
                                latitude: widget.userPosition.latitude,
                                longitude: widget.userPosition.longitude,
                              ),
                            ),
                          ),
                        ).then((value) {
                          selectedBusRoute.clear();
                          if (context.mounted) {
                            setBusStopMarker(context);
                          }
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.black38,
                            content: Text("Bus လမ်းကြောင်းရွေးချယ်ပါ။"),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.gps_fixed, color: Colors.blue),
                  ),
                ),
              ],
            ),
    );
  }
}

class BusStopSearch extends StatefulWidget {
  final Function(BusStop selectedStop) onSelect;
  const BusStopSearch({super.key, required this.onSelect});

  @override
  State<BusStopSearch> createState() => _BusStopSearchState();
}

class _BusStopSearchState extends State<BusStopSearch> {
  List<BusStop> busStopList = AppData.testStop;
  TextEditingController controller = TextEditingController();
  FocusNode focusNode = FocusNode();

  filterStop(String filterText) {
    setState(() {
      busStopList = AppData.testStop
          .where(
            (e) =>
                e.name.contains(filterText) ||
                e.nearPlaces.contains(filterText) ||
                e.township.contains(filterText),
          )
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      minChildSize: 0.2,
      shouldCloseOnMinExtent: true,
      builder: (context, scrollController) => Container(
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
            Text(
              "မှတ်တိုင်ရွေးချယ်ပါ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color.fromARGB(255, 243, 243, 243),
                  labelText: "မှတ်တိုင်အမည်၊ နေရာဖြင့် ရှာပါ",
                  labelStyle: TextStyle(fontSize: 12, color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  suffixIcon: controller.text != ""
                      ? IconButton(
                          onPressed: () {
                            controller.text = "";
                            filterStop("");
                            focusNode.unfocus();
                          },
                          icon: Icon(Icons.cancel, color: Colors.grey),
                        )
                      : null,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 5,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  filterStop(value);
                },
                onTapOutside: (event) {
                  focusNode.unfocus();
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: EdgeInsets.only(bottom: 5),
              width: double.infinity,
              child: Text(
                "မှတ်တိုင်များ",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(
              child: busStopList.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text("မှတ်တိုင် မတွေ့ရှိပါ။")],
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: busStopList.length,
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () {
                          widget.onSelect.call(busStopList[index]);
                        },
                        child: Container(
                          margin: EdgeInsets.only(left: 5, right: 5, bottom: 5),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 216, 238, 255),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: Text(
                                        busStopList[index].name,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Text(
                                        busStopList[index].nearPlaces,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.location_on),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class AvaliableRouteWidget extends StatelessWidget {
  final BusStop? selectedStartBusStop;
  final BusStop? selectedEndBusStop;
  final List<List<RouteData>> routeList;
  final Function(List<RouteData>) onSelectRoute;

  const AvaliableRouteWidget({
    super.key,
    required this.selectedStartBusStop,
    required this.selectedEndBusStop,
    required this.routeList,
    required this.onSelectRoute,
  });

  @override
  Widget build(BuildContext context) {
    List<Set<Bus>> buses = [];
    for (var i in routeList) {
      Set<Bus> busSet = {};
      for (var j in i) {
        busSet.add(j.bus);
      }
      buses.add(busSet);
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 20, left: 10, right: 10),
      child: Column(
        children: [
          Text(
            "လမ်းကြောင်းများ",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    selectedStartBusStop!.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.arrow_forward),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    selectedEndBusStop!.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: routeList.length,
              itemBuilder: (context, index) =>
                  routeButton(context, routeList[index], buses[index], () {
                    onSelectRoute.call(routeList[index]);
                  }),
            ),
          ),
        ],
      ),
    );
  }

  Widget routeButton(
    BuildContext context,
    List<RouteData> routeList,
    Set<Bus> buses,
    Function() onTap,
  ) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 3),
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 241, 241, 241),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 20,
                      child: buses.length == 1
                          ? Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: HexColor(buses.elementAt(0).colorCode),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.directions_bus,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    buses.elementAt(0).name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) => Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: HexColor(
                                    buses.elementAt(index).colorCode,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_bus,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    Text(
                                      buses.elementAt(index).name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              separatorBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Icon(
                                  Icons.directions_walk,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              itemCount: buses.length,
                            ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        "Distance: 12 km",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      "20 min",
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      "200 MMK",
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
