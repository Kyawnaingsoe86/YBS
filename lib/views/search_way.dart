// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:timeline_tile/timeline_tile.dart';
// import 'package:ybs/controllers/hex_color.dart';
// import 'package:ybs/data/app_data.dart';
// import 'package:ybs/models/bus.dart';
// import 'package:ybs/models/bus_stop.dart';
// import 'package:ybs/models/bus_stop_distance.dart';
// import 'package:ybs/models/route_data.dart';
// import 'package:ybs/views/location_pick.dart';

// class SearchWay extends StatefulWidget {
//   final LatLng userPosition;
//   const SearchWay({super.key, required this.userPosition});

//   @override
//   State<SearchWay> createState() => _SearchWayState();
// }

// class _SearchWayState extends State<SearchWay> {
//   List<Marker> markers = [];
//   List<BusStopDistance> busStopDistanceList = [];

//   List<Bus> startPointArrivalBusList = [];
//   List<Bus> endPointArrivalBusList = [];

//   BusStop? start;
//   BusStop? end;

//   List<RouteData> avaliableRoute = [];

//   List<RouteData> getSameBusRoute(Bus bus, BusStop start, BusStop end) {
//     List<RouteData> route = [];
//     bool startStopFound = false;
//     bool endStopFound = false;
//     bool isRouteOne = false;
//     for (var id in bus.routeOne) {
//       startStopFound = id == start.id;
//       endStopFound = id == end.id;
//       if (startStopFound) {
//         isRouteOne = true;
//         break;
//       } else if (endStopFound) {
//         isRouteOne = false;
//         break;
//       }
//     }

//     if (isRouteOne) {
//       final startIndex = bus.routeOne.indexOf(start.id);
//       final endIndex = bus.routeOne.indexOf(end.id);
//       for (int i = startIndex; i <= endIndex; i++) {
//         route.add(
//           RouteData(
//             bus: bus,
//             busStop: AppData.testStop.firstWhere(
//               (stop) => stop.id == bus.routeOne[i],
//             ),
//           ),
//         );
//       }
//       return route;
//     } else {
//       final startIndex = bus.routeTwo.indexOf(start.id);
//       final endIndex = bus.routeTwo.indexOf(end.id);
//       for (int i = startIndex; i <= endIndex; i++) {
//         route.add(
//           RouteData(
//             bus: bus,
//             busStop: AppData.testStop.firstWhere(
//               (stop) => stop.id == bus.routeTwo[i],
//             ),
//           ),
//         );
//       }
//       return route;
//     }
//   }

//   List<RouteData> getRoute(BusStop startStop, BusStop endStop) {
//     Bus startBus = AppData.testbus.firstWhere(
//       (bus) => bus.routeOne.contains(startStop.id),
//     );
//     Bus endBus = AppData.testbus.firstWhere(
//       (bus) => bus.routeOne.contains(endStop.id),
//     );

//     // TODO: update for more than 2 bus route or no overlap bus stop
//     // Current code is only work for the overlap bus stop trip
//     // The following cade are chekcing the ways that have overlap bus stop withing two bus lines.
//     List<int> sameStopIds = [];
//     for (var id1 in startBus.routeOne) {
//       for (var id2 in endBus.routeOne) {
//         if (id1 == id2) {
//           sameStopIds.add(id1);
//         }
//       }
//     }
//     if (sameStopIds.isNotEmpty) {
//       List<RouteData> finalRoute = [];
//       int lenght = 0;
//       for (var i in sameStopIds) {
//         List<RouteData> route = [];
//         route = getSameBusRoute(
//           startBus,
//           startStop,
//           AppData.testStop.firstWhere((stop) => stop.id == i),
//         );

//         if (lenght == 0 || lenght > route.length) {
//           lenght = route.length;
//           final route2 = getSameBusRoute(
//             endBus,
//             AppData.testStop.firstWhere((stop) => stop.id == i),
//             endStop,
//           );
//           route.addAll(route2);
//           finalRoute.clear();
//           finalRoute = route;
//         }
//       }
//       return finalRoute;
//     }

//     // find the distance between bus1 bus stopes and bus2 bus stopes.
//     // the nearest distance will be the transit bus stop.
//     // This saniro will only work for two bus transit.
//     // if the route have more that one transit point, we have to think another way.

//     for (var id1 in startBus.routeOne) {
//       final busStop1 = AppData.testStop.firstWhere((e) => e.id == id1);
//       for (var id2 in endBus.routeOne) {
//         final busStop2 = AppData.testStop.firstWhere((e) => e.id == id2);
//         busStopDistanceList.add(
//           BusStopDistance(
//             distance: Geolocator.distanceBetween(
//               busStop1.latitude,
//               busStop1.longitude,
//               busStop2.latitude,
//               busStop2.longitude,
//             ),
//             busStopOne: busStop1,
//             busStopTwo: busStop2,
//           ),
//         );
//       }
//     }

//     busStopDistanceList.sort((a, b) => a.distance.compareTo(b.distance));

//     List<RouteData> finalRoute = [];
//     final route1 = getSameBusRoute(
//       startBus,
//       startStop,
//       busStopDistanceList.first.busStopOne,
//     );
//     final route2 = getSameBusRoute(
//       endBus,
//       busStopDistanceList.first.busStopTwo,
//       endStop,
//     );
//     route1.addAll(route2);
//     finalRoute.clear();
//     finalRoute = route1;
//     busStopDistanceList.clear();

//     return finalRoute;
//   }

//   List<RouteData> searchRoute(BusStop startStop, BusStop endStop) {
//     avaliableRoute.clear();
//     startPointArrivalBusList.clear();
//     endPointArrivalBusList.clear();

//     for (var bus in AppData.testbus) {
//       if (bus.routeOne.contains(startStop.id) &&
//           bus.routeOne.contains(endStop.id)) {
//         return getSameBusRoute(bus, startStop, endStop);
//       }
//     }

//     return getRoute(startStop, endStop);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           SizedBox(height: 40),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 5),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Container(
//                     padding: EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(5),
//                       border: Border.all(width: 0.5, color: Colors.grey),
//                     ),
//                     child: Text(
//                       start == null ? "စမှတ်တိုင် ရွေးချယ်ပါ။" : start!.name,
//                       maxLines: 1,
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: start == null ? Colors.grey : Colors.black,
//                       ),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () async {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) =>
//                             LocationPick(currentPosition: widget.userPosition),
//                       ),
//                     ).then((value) {
//                       setState(() {
//                         start = value;
//                       });
//                     });
//                   },
//                   icon: Icon(Icons.map),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 5),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Container(
//                     padding: EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(5),
//                       border: Border.all(width: 0.5, color: Colors.grey),
//                     ),
//                     child: Text(
//                       end == null ? "ဆုံးမှတ်တိုင် ရွေးချယ်ပါ။" : end!.name,
//                       maxLines: 1,
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: end == null ? Colors.grey : Colors.black,
//                       ),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) =>
//                             LocationPick(currentPosition: widget.userPosition),
//                       ),
//                     ).then((value) {
//                       setState(() {
//                         end = value;
//                       });
//                     });
//                   },
//                   icon: Icon(Icons.map),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 10),
//           MaterialButton(
//             color: Theme.of(context).colorScheme.primary,
//             onPressed: () {
//               if (start != null && end != null) {
//                 avaliableRoute = searchRoute(start!, end!);
//                 setState(() {});
//               }
//             },
//             child: Text("လမ်းကြောင်းရှာပါ"),
//           ),
//           Expanded(
//             child: avaliableRoute.isEmpty
//                 ? Center(child: Text("လမ်းကြောင်း မရှိပါ။"))
//                 : ListView.builder(
//                     itemCount: avaliableRoute.length,
//                     itemBuilder: (context, index) => SizedBox(
//                       height: 50,
//                       child: TimelineTile(
//                         axis: TimelineAxis.vertical,
//                         alignment: TimelineAlign.manual,
//                         lineXY: 0.25,
//                         startChild:
//                             index == 0 ||
//                                 avaliableRoute[index].bus.id !=
//                                     avaliableRoute[index - 1].bus.id
//                             ? Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 4,
//                                 ),
//                                 child: Text(
//                                   avaliableRoute[index].bus.name,
//                                   textAlign: TextAlign.right,
//                                 ),
//                               )
//                             : null,
//                         endChild: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 5),
//                           child: Text(
//                             avaliableRoute[index].busStop.name,
//                             style: TextStyle(
//                               fontSize: 11,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         indicatorStyle: IndicatorStyle(
//                           width: 15,
//                           height: 15,
//                           color: HexColor(avaliableRoute[index].bus.colorCode),
//                         ),
//                         beforeLineStyle: LineStyle(
//                           color: HexColor(avaliableRoute[index].bus.colorCode),
//                         ),
//                         isFirst: index == 0,
//                       ),
//                     ),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class BusStopCard extends StatelessWidget {
//   final BusStop busStop;
//   final Function onTap;
//   const BusStopCard({super.key, required this.busStop, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         onTap.call();
//       },
//       child: Container(
//         margin: EdgeInsets.only(right: 3),
//         padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
//         decoration: BoxDecoration(
//           color: Theme.of(context).colorScheme.primary,
//           borderRadius: BorderRadius.circular(5),
//         ),
//         child: Row(
//           spacing: 5,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.asset("assets/images/bus_stop_2.png", width: 16),
//             Text(
//               busStop.name,
//               style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
