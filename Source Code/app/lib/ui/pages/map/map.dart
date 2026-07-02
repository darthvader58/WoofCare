import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/config/constants.dart';
import 'package:woofcare/config/map_style.dart';
import 'package:woofcare/ui/widgets/app_chrome.dart';

import '/ui/pages/export.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final locationController = Location();
  GoogleMapController? _mapController;
  LatLng? currentPosition;

  List<Map<String, dynamic>> markers = [];

  BitmapDescriptor currentMarker = BitmapDescriptor.defaultMarker;

  BitmapDescriptor vetMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor vetSelectMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor ngoMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor ngoSelectMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor shelterMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor shelterSelectMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor dogMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor dogSelectMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor adoptMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor adoptSelectMarker = BitmapDescriptor.defaultMarker;

  StreamSubscription<LocationData>? _locationSubscription;
  String selectedMarkerType = 'all';

  @override
  void initState() {
    super.initState();

    _initializeMap();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    await _updateMarkerIcons();
    if (!mounted) return;

    await _fetchLocation(context);
    if (!mounted) return;

    await _fetchMarkers();
  }

  Future<void> _showMarkerBottomSheet(int index) async {
    Map<String, dynamic> markerData = markers[index];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PopScope(
          onPopInvokedWithResult: (bool pop, _) {
            if (mounted) {
              setState(() {
                markers[index]["selected"] = false;
              });
            }
          },
          child: DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.15,
            maxChildSize: 0.75,
            builder: (sheetContext, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: WoofCareColors.secondaryBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(
                      color: WoofCareColors.borderOutline,
                      width: 2.0,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 12,
                      bottom: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 12),
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: WoofCareColors.primaryTextAndIcons,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        // Title row with image, name and rating/state
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Placeholder image (replace with network/image if available)
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                                image: const DecorationImage(
                                  image: AssetImage(
                                    'assets/images/placeholders/placeholder.jpeg',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Name and metadata
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ((markerData['name'] ?? "Unknown")
                                            as String)
                                        .capitalize!,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: WoofCareColors.primaryTextAndIcons,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '4.3',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '(59)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '• 2 min',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Action buttons row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMapAction(
                              icon: Icons.directions,
                              label: 'Directions',
                              onTap: () async {
                                Navigator.of(context).pop();
                                await _openDirections(markerData);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildMapAction(
                              icon: Icons.call,
                              label: 'Call',
                              onTap: () async {
                                final phone = markerData['phone'];

                                if (phone != null &&
                                    phone.toString().isNotEmpty) {
                                  final uri = Uri(
                                    scheme: 'tel',
                                    path: phone.toString(),
                                  );

                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildMapAction(
                              icon: Icons.public,
                              label: 'Website',
                              onTap: () async {
                                final website = markerData['website'];
                                if (website != null &&
                                    website.toString().isNotEmpty) {
                                  var uri = Uri.parse(website.toString());

                                  if (!uri.hasScheme) {
                                    uri = Uri.parse(
                                      'https://${website.toString()}',
                                    );
                                  }
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildMapAction(
                              icon: Icons.share,
                              label: 'Share',
                              onTap: () {},
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        const Divider(color: Colors.black, height: 2.0),

                        const SizedBox(height: 12),

                        // About / Description
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          markerData['description'] ??
                              'No description available.',
                        ),

                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child:
                  currentPosition == null
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: WoofCareColors.buttonColor,
                        ),
                      )
                      : GoogleMap(
                        style: WoofCareMapStyle.light,
                        gestureRecognizers: {
                          Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        },
                        myLocationButtonEnabled: true,
                        myLocationEnabled: true,
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: false,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        compassEnabled: true,
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                        rotateGesturesEnabled: true,
                        tiltGesturesEnabled: true,
                        padding: const EdgeInsets.only(top: 132, bottom: 108),
                        mapType: MapType.normal,
                        initialCameraPosition: CameraPosition(
                          target: currentPosition!,
                          zoom: 13,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId("currentPos"),
                            icon: currentMarker,
                            position: currentPosition!,
                          ),
                          for (final i in _visibleMarkerIndexes())
                            Marker(
                              markerId: MarkerId(markers[i]["id"]),
                              icon:
                                  markers[i]["selected"]
                                      ? markers[i]["selectIcon"]
                                      : markers[i]["icon"],
                              position: LatLng(
                                markers[i]["latitude"],
                                markers[i]["longitude"],
                              ),
                              onTap: () {
                                _handleMarkerTap(i);
                              },
                            ),
                        },
                      ),
            ),
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: _MapToolbar(
                onReportTap: _reportDogButtonPressed,
                onProfileTap: () => Navigator.pushNamed(context, "/profile"),
              ),
            ),
            Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: _MapFilterBar(
                selectedType: selectedMarkerType,
                onSelected:
                    (type) => setState(() {
                      selectedMarkerType = type;
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Iterable<int> _visibleMarkerIndexes() sync* {
    for (var i = 0; i < markers.length; i++) {
      if (_markerMatchesFilter(markers[i])) {
        yield i;
      }
    }
  }

  bool _markerMatchesFilter(Map<String, dynamic> marker) {
    if (selectedMarkerType == 'all') return true;
    return marker['type'] == selectedMarkerType;
  }

  Widget _buildMapAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: WoofCareColors.buttonColor,
          foregroundColor: WoofCareColors.offWhite,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Future<void> _openDirections(Map<String, dynamic> markerData) async {
    final maps = Uri.parse(
      "https://www.google.com/maps?q=${markerData['latitude']},${markerData['longitude']}",
    );

    if (await canLaunchUrl(maps)) {
      await launchUrl(maps, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> fetchLocationUpdates(BuildContext context) async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await locationController.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        // What if the permission status is grantedLimited?
        return;
      }
    }

    await _locationSubscription?.cancel();
    _locationSubscription = locationController.onLocationChanged.listen((
      currentLocation,
    ) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null &&
          context.mounted) {
        setState(() {
          currentPosition = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );
        });
      }
    });
  }

  void _reportDogButtonPressed() {
    // Show the bottom sheet when the button is pressed
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          // Make the bottom sheet draggable
          initialChildSize: 0.75,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (sheetContext, scrollController) {
            return Container(
              // Container to store the drag handle and the ReportingPage
              decoration: const BoxDecoration(
                color: WoofCareColors.secondaryBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: WoofCareColors.borderOutline,
                    width: 2.0,
                  ),
                ),
              ),

              // Children of the container => drag handle and the ReportingPage
              child: Column(
                children: [
                  // Drag handle (necessary since modal bottom sheet's handle doesn't align with the current setup)
                  Container(
                    margin: const EdgeInsets.only(top: 20, bottom: 16),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: WoofCareColors.primaryTextAndIcons,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  const Text(
                    'Dog Report',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w200,
                      color: WoofCareColors.primaryTextAndIcons,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Divider(color: Colors.black, height: 2.0),

                  // The ReportingPage (uses Expanded to take up the rest of the space)
                  Expanded(
                    child: SafeArea(
                      top: false,
                      left: false,
                      right: false,
                      child: ReportPage(scrollController: scrollController),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateMarkerIcons() async {
    currentMarker = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/images/map/current.png',
    );

    vetMarker = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/images/map/vet.png',
    );
    vetSelectMarker = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/images/map/vetSelect.png',
    );

    ngoMarker = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/images/map/ngo.png',
    );
    ngoSelectMarker = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/images/map/ngoSelect.png',
    );

    shelterMarker = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/images/map/shelter.png',
    );
    shelterSelectMarker = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/images/map/shelterSelect.png',
    );

    dogMarker = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/images/map/dog.png',
    );
    dogSelectMarker = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/images/map/dogSelect.png',
    );

    adoptMarker = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/images/map/adopt.png',
    );
    adoptSelectMarker = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/images/map/adoptSelect.png',
    );
  }

  Future<void> _fetchMarkers() async {
    final List<Map<String, dynamic>> loadedMarkers = [];

    for (QueryDocumentSnapshot doc
        in (await FIRESTORE.collection("locations").get()).docs) {
      final data = doc.data() as Map<String, dynamic>?;

      if (data != null &&
          data['latitude'] != null &&
          data['longitude'] != null) {
        Map<String, dynamic> marker = {
          'id': doc.id,
          'latitude': (data['latitude'] as num).toDouble(),
          'longitude': (data['longitude'] as num).toDouble(),
          'name': data['name'] ?? 'Unknown',
          'description': data['description'] ?? 'NA',
          'phone': data['phone'],
          'website': data['website'],
          'type': data['type'] ?? 'dog',
          'selected': false,
        };

        switch (data['type']) {
          case 'vet':
            marker['icon'] = vetMarker;
            marker['selectIcon'] = vetSelectMarker;
            break;
          case 'ngo':
            marker['icon'] = ngoMarker;
            marker['selectIcon'] = ngoSelectMarker;
            break;
          case 'shelter':
            marker['icon'] = shelterMarker;
            marker['selectIcon'] = shelterSelectMarker;
            break;
          case 'dog':
            marker['icon'] = dogMarker;
            marker['selectIcon'] = dogSelectMarker;
            break;
          case 'local':
            marker['icon'] = adoptMarker;
            marker['selectIcon'] = adoptSelectMarker;
            break;
          default:
            marker['icon'] = dogMarker;
        }

        loadedMarkers.add(marker);
      }
    }

    for (QueryDocumentSnapshot doc
        in (await FIRESTORE.collection("reports").get()).docs) {
      final data = doc.data() as Map<String, dynamic>?;

      // TODO: Expiry Date and Other Fields
      if (data != null &&
          data['latitude'] != null &&
          data['longitude'] != null) {
        Map<String, dynamic> marker = {
          'id': doc.id,
          'latitude': (data['latitude'] as num).toDouble(),
          'longitude': (data['longitude'] as num).toDouble(),
          'name': data['name'] ?? 'Unknown',
          'description': data['description'] ?? 'NA',
          'phone': data['phone'],
          'website': data['website'] ?? "",
          'icon': dogMarker,
          'selectIcon': dogSelectMarker,
          'type': 'report',
          'urgency': data['urgency'] ?? "low",
          'userReported': data['userID'],
          'selected': false,
        };

        loadedMarkers.add(marker);
      }
    }

    if (!mounted) return;

    setState(() {
      markers = loadedMarkers;
    });
  }

  Future<void> _handleMarkerTap(int index) async {
    setState(() {
      for (final marker in markers) {
        marker["selected"] = false;
      }
      markers[index]["selected"] = true;
    });

    await _showMarkerBottomSheet(index);
  }

  Future<void> _fetchLocation(BuildContext context) async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await locationController.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    final initialLocation = await locationController.getLocation();
    await _updateCurrentPosition(initialLocation, moveCamera: false);

    await _locationSubscription?.cancel();
    _locationSubscription = locationController.onLocationChanged.listen((
      currentLocation,
    ) {
      _updateCurrentPosition(currentLocation);
    });
  }

  Future<void> _updateCurrentPosition(
    LocationData location, {
    bool moveCamera = true,
  }) async {
    if (location.latitude == null || location.longitude == null || !mounted) {
      return;
    }

    final position = LatLng(location.latitude!, location.longitude!);

    setState(() {
      currentPosition = position;
    });

    if (moveCamera) {
      await _mapController?.animateCamera(CameraUpdate.newLatLng(position));
    }
  }
}

class _MapToolbar extends StatelessWidget {
  final VoidCallback onReportTap;
  final VoidCallback onProfileTap;

  const _MapToolbar({required this.onReportTap, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: WoofCareColors.offWhite.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nearby Help',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: WoofCareColors.primaryTextAndIcons,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Shelters, vets, reports, and adopters',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: WoofCareColors.mutedText.withValues(alpha: 0.82),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Report dog',
            onPressed: onReportTap,
            icon: const FaIcon(
              FontAwesomeIcons.bullhorn,
              color: WoofCareColors.buttonColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 4),
          WoofCareProfileAvatar(onTap: onProfileTap),
        ],
      ),
    );
  }
}

class _MapFilterBar extends StatefulWidget {
  final String selectedType;
  final ValueChanged<String> onSelected;

  const _MapFilterBar({required this.selectedType, required this.onSelected});

  @override
  State<_MapFilterBar> createState() => _MapFilterBarState();
}

class _MapFilterBarState extends State<_MapFilterBar> {
  final ScrollController _scrollController = ScrollController();

  static const filters = [
    ('all', 'All'),
    ('report', 'Reports'),
    ('dog', 'Dogs'),
    ('vet', 'Vets'),
    ('shelter', 'Shelters'),
    ('ngo', 'NGOs'),
    ('local', 'Adopt'),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;

    final target = (_scrollController.offset + delta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            padding: const EdgeInsets.fromLTRB(56, 8, 56, 8),
            itemCount: filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = filters[index];
              return WoofCareFilterPill(
                label: filter.$2,
                selected: widget.selectedType == filter.$1,
                onTap: () => widget.onSelected(filter.$1),
              );
            },
          ),
          Positioned(
            left: 10,
            child: _FilterScrollButton(
              icon: Icons.chevron_left_rounded,
              onTap: () => _scrollBy(-180),
            ),
          ),
          Positioned(
            right: 10,
            child: _FilterScrollButton(
              icon: Icons.chevron_right_rounded,
              onTap: () => _scrollBy(180),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterScrollButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FilterScrollButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WoofCareColors.offWhite.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            color: WoofCareColors.primaryTextAndIcons,
            size: 24,
          ),
        ),
      ),
    );
  }
}
