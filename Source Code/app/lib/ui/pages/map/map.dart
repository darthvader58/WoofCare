import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    final isReport = markerData['type'] == 'report';
    final title = _markerTitle(markerData);
    final images = _markerImages(markerData);

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
            initialChildSize: 0.54,
            minChildSize: 0.28,
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

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MarkerPreviewImage(images: images),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      height: 1.15,
                                      fontWeight: FontWeight.w800,
                                      color: WoofCareColors.primaryTextAndIcons,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _MarkerMeta(markerData: markerData),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _MarkerActions(
                          markerData: markerData,
                          onDirections: () async {
                            Navigator.of(context).pop();
                            await _openDirections(markerData);
                          },
                          onCall: () => _launchPhone(_markerPhone(markerData)),
                          onWebsite: () => _openWebsite(markerData),
                          onChat:
                              isReport
                                  ? () => _startChatWithReporter(markerData)
                                  : null,
                        ),

                        const SizedBox(height: 18),

                        Divider(
                          color: WoofCareColors.primaryTextAndIcons.withValues(
                            alpha: 0.18,
                          ),
                          height: 1,
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _MarkerAbout(markerData: markerData, images: images),

                        if (isReport && images.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Photos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: WoofCareColors.primaryTextAndIcons,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _MarkerImageStrip(images: images),
                        ],

                        if (isReport &&
                            (markerData['reporterName'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _ReporterCard(markerData: markerData),
                        ],

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

  String _markerTitle(Map<String, dynamic> markerData) {
    final title = markerData['title'] ?? markerData['name'];
    final value = title?.toString().trim();
    if (value == null || value.isEmpty) return 'Unknown';
    return value;
  }

  List<String> _markerImages(Map<String, dynamic> markerData) {
    final values = <String>[];
    final imageFields = [
      markerData['imageUrls'],
      markerData['images'],
      markerData['photos'],
    ];

    for (final field in imageFields) {
      if (field is List) {
        values.addAll(
          field
              .map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty),
        );
      }
    }

    final singleImage = markerData['imageUrl']?.toString().trim();
    if (singleImage != null && singleImage.isNotEmpty) {
      values.add(singleImage);
    }

    return values;
  }

  String? _markerPhone(Map<String, dynamic> markerData) {
    final value =
        markerData['type'] == 'report'
            ? markerData['reporterPhone']
            : markerData['phone'];
    final phone = value?.toString().trim();
    if (phone == null || phone.isEmpty) return null;
    return phone;
  }

  Future<void> _launchPhone(String? phone) async {
    if (phone == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWebsite(Map<String, dynamic> markerData) async {
    final website = markerData['website'];
    if (website == null || website.toString().trim().isEmpty) return;

    var uri = Uri.parse(website.toString().trim());
    if (!uri.hasScheme) {
      uri = Uri.parse('https://${website.toString().trim()}');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _startChatWithReporter(Map<String, dynamic> markerData) async {
    final reporterName =
        (markerData['actualReporterName'] ?? markerData['reporterName'])
            ?.toString()
            .trim();
    if (reporterName == null || reporterName.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporter profile is unavailable')),
      );
      return;
    }

    if (reporterName == profile.name) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('This is your report')));
      return;
    }

    final snapshot =
        await FIRESTORE
            .collection('conversations')
            .where('participants', arrayContains: profile.name)
            .get();

    final conversations =
        snapshot.docs.where((doc) {
          final data = doc.data();
          final participants = data['participants'] as List? ?? [];
          return participants.contains(reporterName) &&
              data['isReportChat'] == true &&
              data['reportId'] == markerData['id'];
        }).toList();

    final isAnonymous = markerData['isAnonymous'] == true;
    final requesterDisplayName =
        profile.shareProfile ? profile.name : 'Anonymous User';
    final reporterDisplayName =
        isAnonymous ? 'Anonymous Reporter' : reporterName;
    final existingData =
        conversations.isNotEmpty ? conversations.first.data() : null;

    final conversationData = {
      'messages': [],
      'participants': [profile.name, reporterName],
      'isReportChat': true,
      'reportId': markerData['id'],
      'anonymousReporter': isAnonymous,
      'reporterName': reporterName,
      'reporterDisplayName': reporterDisplayName,
      'requesterName': profile.name,
      'requesterDisplayName': requesterDisplayName,
      'requesterProfileShared': profile.shareProfile,
      if (isAnonymous && existingData?['expiresAt'] == null)
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 48)),
        ),
    };

    final chatID =
        conversations.isEmpty
            ? (await FIRESTORE
                .collection('conversations')
                .add(conversationData)).id
            : conversations.first.id;

    if (conversations.isNotEmpty) {
      await conversations.first.reference.set(
        conversationData,
        SetOptions(merge: true),
      );
    }

    if (!mounted) return;

    Navigator.of(context).pop();
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {'chatID': chatID, 'participant': reporterDisplayName},
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
        final isAnonymous = data['isAnonymous'] == true;
        final shareReporterPhone =
            !isAnonymous && data['shareReporterPhone'] == true;
        String? reporterName = data['reporterName']?.toString();
        String? reporterPhone =
            shareReporterPhone ? data['reporterPhone']?.toString() : null;
        String? reporterEmail = data['reporterEmail']?.toString();
        final reporterId = data['userID']?.toString();

        if ((reporterName == null ||
                (shareReporterPhone && reporterPhone == null)) &&
            reporterId != null &&
            reporterId.isNotEmpty) {
          try {
            final userDoc =
                await FIRESTORE.collection("users").doc(reporterId).get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              reporterName ??= userData?['name']?.toString();
              if (shareReporterPhone) {
                reporterPhone ??= userData?['phone']?.toString();
              }
              reporterEmail ??= userData?['email']?.toString();
            }
          } catch (_) {
            // Keep report marker usable even if reporter lookup is unavailable.
          }
        }

        Map<String, dynamic> marker = {
          'id': doc.id,
          'latitude': (data['latitude'] as num).toDouble(),
          'longitude': (data['longitude'] as num).toDouble(),
          'title': data['title'] ?? data['name'] ?? 'Unknown report',
          'name': data['title'] ?? data['name'] ?? 'Unknown report',
          'description': data['description'] ?? '',
          'location_description': data['location_description'],
          'address': data['address'],
          'extraNotes': data['extraNotes'],
          'phone': reporterPhone,
          'shareReporterPhone': shareReporterPhone,
          'reporterPhone': reporterPhone,
          'reporterName': isAnonymous ? 'Anonymous Reporter' : reporterName,
          'actualReporterName': reporterName,
          'reporterEmail': reporterEmail,
          'website': '',
          'imageUrl': data['imageUrl'],
          'imageUrls': data['imageUrls'] ?? data['images'] ?? data['photos'],
          'icon': dogMarker,
          'selectIcon': dogSelectMarker,
          'type': 'report',
          'urgency': data['urgency'] ?? "low",
          'userReported': reporterId,
          'isAnonymous': isAnonymous,
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

class _MarkerPreviewImage extends StatelessWidget {
  final List<String> images;

  const _MarkerPreviewImage({required this.images});

  @override
  Widget build(BuildContext context) {
    final image = images.isNotEmpty ? images.first : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 96,
        height: 96,
        child:
            image == null
                ? Image.asset(
                  'assets/images/placeholders/placeholder.jpeg',
                  fit: BoxFit.cover,
                )
                : Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Image.asset(
                        'assets/images/placeholders/placeholder.jpeg',
                        fit: BoxFit.cover,
                      ),
                ),
      ),
    );
  }
}

class _MarkerMeta extends StatelessWidget {
  final Map<String, dynamic> markerData;

  const _MarkerMeta({required this.markerData});

  @override
  Widget build(BuildContext context) {
    final isReport = markerData['type'] == 'report';

    if (isReport) {
      final urgency = _urgencyLabel(markerData['urgency']);
      final color = _urgencyColor(markerData['urgency']);

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _InfoPill(
            icon: Icons.priority_high_rounded,
            label: urgency,
            color: color,
          ),
          if ((markerData['reporterName'] ?? '').toString().trim().isNotEmpty)
            _InfoPill(
              icon: Icons.person_rounded,
              label: markerData['reporterName'].toString(),
              color: WoofCareColors.mutedText,
            ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        _InfoPill(
          icon: Icons.verified_rounded,
          label: 'Organization',
          color: WoofCareColors.buttonColor,
        ),
      ],
    );
  }
}

class _MarkerActions extends StatelessWidget {
  final Map<String, dynamic> markerData;
  final VoidCallback onDirections;
  final VoidCallback onCall;
  final VoidCallback onWebsite;
  final VoidCallback? onChat;

  const _MarkerActions({
    required this.markerData,
    required this.onDirections,
    required this.onCall,
    required this.onWebsite,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final isReport = markerData['type'] == 'report';
    final hasWebsite =
        !isReport && (markerData['website'] ?? '').toString().trim().isNotEmpty;
    final hasPhone =
        (isReport ? markerData['reporterPhone'] : markerData['phone'])
            ?.toString()
            .trim()
            .isNotEmpty ==
        true;

    final actions = [
      _MarkerActionButton(
        icon: Icons.directions_rounded,
        label: 'Directions',
        onTap: onDirections,
      ),
      if (hasPhone)
        _MarkerActionButton(
          icon: Icons.call_rounded,
          label: 'Call',
          onTap: onCall,
        ),
      if (isReport && onChat != null)
        _MarkerActionButton(
          icon: Icons.chat_bubble_rounded,
          label: 'Chat',
          onTap: onChat!,
        ),
      if (hasWebsite)
        _MarkerActionButton(
          icon: Icons.public_rounded,
          label: 'Website',
          onTap: onWebsite,
        ),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(child: actions[i]),
          if (i != actions.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _MarkerActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MarkerActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: WoofCareColors.buttonColor,
        foregroundColor: WoofCareColors.offWhite,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _MarkerAbout extends StatelessWidget {
  final Map<String, dynamic> markerData;
  final List<String> images;

  const _MarkerAbout({required this.markerData, required this.images});

  @override
  Widget build(BuildContext context) {
    final isReport = markerData['type'] == 'report';
    final description = _nonEmptyString(markerData['description']);

    if (!isReport) {
      return Text(
        description ?? 'No description available.',
        style: const TextStyle(
          color: WoofCareColors.primaryTextAndIcons,
          fontSize: 15,
          height: 1.45,
        ),
      );
    }

    final details = [
      if (description != null)
        _DetailRow(
          icon: Icons.notes_rounded,
          label: 'Description',
          value: description,
        ),
      if (_nonEmptyString(markerData['location_description']) != null)
        _DetailRow(
          icon: Icons.place_rounded,
          label: 'Location notes',
          value: _nonEmptyString(markerData['location_description'])!,
        ),
      if (_nonEmptyString(markerData['address']) != null)
        _DetailRow(
          icon: Icons.map_rounded,
          label: 'Nearest address',
          value: _nonEmptyString(markerData['address'])!,
        ),
      if (_nonEmptyString(markerData['extraNotes']) != null)
        _DetailRow(
          icon: Icons.info_rounded,
          label: 'Additional notes',
          value: _nonEmptyString(markerData['extraNotes'])!,
        ),
    ];

    if (details.isEmpty) {
      return const Text(
        'No report details available.',
        style: TextStyle(
          color: WoofCareColors.primaryTextAndIcons,
          fontSize: 15,
          height: 1.45,
        ),
      );
    }

    return Column(children: details);
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WoofCareColors.offWhite.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: WoofCareColors.buttonColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: WoofCareColors.mutedText.withValues(alpha: 0.82),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: WoofCareColors.primaryTextAndIcons,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkerImageStrip extends StatelessWidget {
  final List<String> images;

  const _MarkerImageStrip({required this.images});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder:
            (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                images[index],
                width: 132,
                height: 108,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      width: 132,
                      height: 108,
                      color: WoofCareColors.textBoxColor,
                      child: const Icon(
                        Icons.image_not_supported_rounded,
                        color: WoofCareColors.primaryTextAndIcons,
                      ),
                    ),
              ),
            ),
      ),
    );
  }
}

class _ReporterCard extends StatelessWidget {
  final Map<String, dynamic> markerData;

  const _ReporterCard({required this.markerData});

  @override
  Widget build(BuildContext context) {
    final name = markerData['reporterName']?.toString() ?? 'Reporter';
    final phone = markerData['reporterPhone']?.toString();
    final sharePhone = markerData['shareReporterPhone'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WoofCareColors.buttonColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WoofCareColors.buttonColor.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: WoofCareColors.buttonColor,
            foregroundColor: WoofCareColors.offWhite,
            child: Icon(Icons.person_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WoofCareColors.primaryTextAndIcons,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  !sharePhone || phone == null || phone.trim().isEmpty
                      ? 'Phone not shared'
                      : phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: WoofCareColors.mutedText.withValues(alpha: 0.82),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _urgencyLabel(Object? value) {
  final urgency = value?.toString().trim();
  if (urgency == null || urgency.isEmpty) return 'Unknown urgency';
  return urgency;
}

Color _urgencyColor(Object? value) {
  final urgency = value?.toString().toLowerCase() ?? '';
  if (urgency.contains('high')) return const Color(0xFFC0392B);
  if (urgency.contains('medium')) return const Color(0xFFB76E22);
  return const Color(0xFF2F7D52);
}

String? _nonEmptyString(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'NA') return null;
  return text;
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
