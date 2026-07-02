import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart';
import 'package:woofcare/config/colors.dart';

import '/config/constants.dart';
import '/ui/widgets/custom_button.dart';
import '/ui/widgets/custom_textfield.dart';

// TODO: Drop Pin, Address, Photos
class ReportPage extends StatefulWidget {
  final ScrollController scrollController;

  const ReportPage({super.key, required this.scrollController});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _reportTitleController = TextEditingController();
  final _dogDescriptionController = TextEditingController();
  final _locationDescriptionController = TextEditingController();
  final _nearestAddressController = TextEditingController();
  final _extraNotesController = TextEditingController();

  String? dropdownValue;
  final List<String> urgencyList = [
    'High Urgency',
    'Medium Urgency',
    'Low Urgency',
  ];

  bool useCurrentLocation = true;
  // bool dropPin = false;
  bool anonymousReport = false;
  bool shareReporterPhone = false;

  void submitReport() async {
    CollectionReference reports = FIRESTORE.collection('reports');

    double? latitude;
    double? longitude;

    // if (useCurrentLocation) {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();
    latitude = locationData.latitude;
    longitude = locationData.longitude;
    // }

    // Expiry date 2 weeks from now
    DateTime expiryDate = DateTime.now().add(const Duration(days: 14));

    Map<String, dynamic> newReportData = {
      'userID': profile.id,
      'reporterName': profile.name,
      'shareReporterPhone': shareReporterPhone,
      'reporterPhone': shareReporterPhone ? profile.phone : null,
      'reporterEmail': profile.email,
      'title': _reportTitleController.text,
      'description': _dogDescriptionController.text,
      'location_description': _locationDescriptionController.text,
      'urgency': dropdownValue,
      'latitude': latitude,
      'longitude': longitude,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'timestamp': Timestamp.now(),
      'isAnonymous': anonymousReport,
      'address': _nearestAddressController.text,
      'extraNotes': _extraNotesController.text,
    };

    try {
      await reports.add(newReportData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Report successfully submitted!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit report: $e"),
            backgroundColor: WoofCareColors.errorMessageColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 120,
        top: 20,
      ),
      child: Container(
        color: WoofCareColors.secondaryBackground,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildSectionHeader('Report Details'),
            _buildCard(
              children: [
                CustomTextField(
                  controller: _reportTitleController,
                  hintText: 'Report Title',
                  prefix: Icons.title,
                ),
                const SizedBox(height: 16),
                _buildUrgencyDropdown(),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _dogDescriptionController,
                  hintText: 'Dog Description (Features, injuries, etc.)',
                  minLines: 3,
                  maxLines: 5,
                ),
              ],
            ),

            const SizedBox(height: 20),
            _buildSectionHeader('Photos'),
            _buildPhotoSection(),

            const SizedBox(height: 20),
            _buildSectionHeader('Location'),
            _buildCard(
              children: [
                _buildSwitchTile(
                  title: "Use Current Location",
                  value: useCurrentLocation,
                  onChanged: (val) => setState(() => useCurrentLocation = val),
                ),
                // _buildSwitchTile(
                //   title: "Drop Pin on Map",
                //   value: dropPin,
                //   onChanged: (val) => setState(() => dropPin = val),
                // ),
                // const SizedBox(height: 10),
                // CustomTextField(
                //   controller: _nearestAddressController,
                //   hintText: 'Nearest Address',
                //   prefix: Icons.location_on,
                // ),
                // const SizedBox(height: 16),
                // CustomTextField(
                //   controller: _locationDescriptionController,
                //   hintText: 'Location Details (Landmarks, etc.)',
                //   minLines: 2,
                //   maxLines: 4,
                // ),
              ],
            ),

            const SizedBox(height: 20),
            _buildSectionHeader('Additional Info'),
            _buildCard(
              children: [
                _buildSwitchTile(
                  title: "Submit Anonymously",
                  value: anonymousReport,
                  onChanged: (val) => setState(() => anonymousReport = val),
                ),
                const SizedBox(height: 10),
                _buildSwitchTile(
                  title: "Share My Phone Number",
                  value: shareReporterPhone,
                  onChanged: (val) => setState(() => shareReporterPhone = val),
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: _extraNotesController,
                  hintText: 'Any other notes?',
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),

            const SizedBox(height: 30),
            CustomButton(
              text: 'Submit Report',
              onTap: submitReport,
              margin: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.aBeeZee(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: WoofCareColors.primaryTextAndIcons,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildUrgencyDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonFormField<String>(
        initialValue: dropdownValue,

        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 22, 16, 16),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: const BorderSide(
              color: WoofCareColors.primaryTextAndIcons,
            ),
          ),
          fillColor: WoofCareColors.textfieldBackground.withValues(alpha: 0.3),
          filled: true,
        ),
        hint: Text(
          'Select Urgency Level',
          style: TextStyle(
            color: WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.5),
            fontWeight: FontWeight.w200,
            fontSize: 13,
          ),
        ),
        icon: const Icon(
          Icons.arrow_drop_down,
          color: WoofCareColors.primaryTextAndIcons,
        ),
        items:
            urgencyList.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                ),
              );
            }).toList(),
        onChanged: (newValue) => setState(() => dropdownValue = newValue),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: () {
              // TODO: Add photo upload functionality
            },
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: WoofCareColors.textfieldBackground.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: WoofCareColors.primaryTextAndIcons,
                  style: BorderStyle.solid,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.add_a_photo,
                    size: 32,
                    color: WoofCareColors.primaryTextAndIcons,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Add Photo",
                    style: TextStyle(
                      fontSize: 12,
                      color: WoofCareColors.primaryTextAndIcons,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: WoofCareColors.primaryTextAndIcons,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: WoofCareColors.primaryTextAndIcons,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
