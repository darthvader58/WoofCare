import 'package:flutter/material.dart';
import 'package:woofcare/config/constants.dart';
import 'package:woofcare/services/auth.dart';
import 'package:woofcare/ui/pages/export.dart';
import 'package:woofcare/ui/widgets/custom_button.dart';
import 'package:woofcare/ui/widgets/responsive.dart';

import '/config/colors.dart' as app_colors;
import '/ui/widgets/custom_textfield.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _passwordTextController = TextEditingController();
  final _emailTextController = TextEditingController();

  // Independent dropdown values
  String selectedLanguage = "English";
  String selectedLocationSharing = "Friends Only";
  late String selectedProfileViewing;

  @override
  void initState() {
    super.initState();
    selectedProfileViewing = profile.shareProfile ? "On" : "Off";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.WoofCareColors.secondaryBackground,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
            color: app_colors.WoofCareColors.primaryTextAndIcons,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: app_colors.WoofCareColors.primaryTextAndIcons,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background images
          Align(
            alignment: Alignment.topLeft,
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                "assets/images/patterns/BigPawPattern.png",
                width: 200,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                "assets/images/patterns/SmallPawPattern.png",
                width: 150,
              ),
            ),
          ),

          // Content
          Positioned.fill(
            child: WoofCareContentSurface(
              maxWidth: 760,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Account"),
                    _buildSectionCard([
                      _buildExpansionTile(
                        icon: Icons.email_outlined,
                        title: "Change Email",
                        children: [
                          _buildTextField(_emailTextController, "New Email"),
                          const SizedBox(height: 10),
                          _buildTextField(
                            _emailTextController,
                            "Confirm New Email",
                          ),
                          const SizedBox(height: 12),
                          _buildSaveButton(),
                        ],
                      ),
                      _buildDivider(),
                      _buildExpansionTile(
                        icon: Icons.lock_outline,
                        title: "Change Password",
                        children: [
                          _buildTextField(
                            _passwordTextController,
                            "New Password",
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            _passwordTextController,
                            "Confirm New Password",
                          ),
                          const SizedBox(height: 12),
                          _buildSaveButton(),
                        ],
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _buildSectionHeader("Preferences"),
                    _buildSectionCard([
                      _buildDropdownTile(
                        icon: Icons.language,
                        title: "Language",
                        value: selectedLanguage,
                        items: ["English", "Spanish", "French"],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedLanguage = val);
                          }
                        },
                      ),
                      _buildDivider(),
                      SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: app_colors.WoofCareColors.primaryBackground
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color:
                                app_colors.WoofCareColors.primaryTextAndIcons,
                          ),
                        ),
                        title: const Text(
                          "Notifications",
                          style: TextStyle(
                            color:
                                app_colors.WoofCareColors.primaryTextAndIcons,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        value: true,
                        activeThumbColor: app_colors.WoofCareColors.buttonColor,
                        onChanged: (val) {},
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _buildSectionHeader("Privacy & Security"),
                    _buildSectionCard([
                      _buildDropdownTile(
                        icon: Icons.location_on_outlined,
                        title: "Location Sharing",
                        value: "While Using",
                        items: ["Always", "While Using", "Never"],
                        onChanged: (val) {},
                      ),
                      _buildDivider(),
                      _buildDropdownTile(
                        icon: Icons.visibility_outlined,
                        title: "Profile Sharing",
                        value: selectedProfileViewing,
                        items: ["On", "Off"],
                        onChanged: (val) async {
                          if (val == null) return;
                          final shareProfile = val == "On";
                          setState(() => selectedProfileViewing = val);
                          profile.shareProfile = shareProfile;
                          await profile.reference.update({
                            "shareProfile": shareProfile,
                          });
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _buildSectionHeader("Support"),
                    _buildSectionCard([
                      _buildLinkTile(Icons.info_outline, "About Us", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
                        );
                      }),
                      _buildDivider(),
                      _buildLinkTile(
                        Icons.privacy_tip_outlined,
                        "Privacy Policy",
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HomePage()),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildLinkTile(
                        Icons.description_outlined,
                        "Terms & Conditions",
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HomePage()),
                          );
                        },
                      ),
                    ]),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Auth.logOut(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF926C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          "Log Out",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: app_colors.WoofCareColors.dividerColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
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

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Color(0xFFF0F0F0),
    );
  }

  Widget _buildExpansionTile({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: app_colors.WoofCareColors.primaryBackground.withValues(
              alpha: 0.2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: app_colors.WoofCareColors.primaryTextAndIcons,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: app_colors.WoofCareColors.primaryTextAndIcons,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        iconColor: app_colors.WoofCareColors.primaryTextAndIcons,
        collapsedIconColor: app_colors.WoofCareColors.primaryTextAndIcons,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: children,
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: app_colors.WoofCareColors.primaryBackground.withValues(
            alpha: 0.2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: app_colors.WoofCareColors.primaryTextAndIcons),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: app_colors.WoofCareColors.primaryTextAndIcons,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: app_colors.WoofCareColors.primaryTextAndIcons,
          ),
          style: const TextStyle(
            color: app_colors.WoofCareColors.primaryTextAndIcons,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLinkTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: app_colors.WoofCareColors.primaryBackground.withValues(
            alpha: 0.2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: app_colors.WoofCareColors.primaryTextAndIcons),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: app_colors.WoofCareColors.primaryTextAndIcons,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return CustomTextField(
      controller: controller,
      hintText: hint,
      maxLines: 1,
      obscureText: true,
    );
  }

  Widget _buildSaveButton() {
    return CustomButton(
      text: "Save",
      onTap: () {},
      width: double.infinity,
      fontSize: 16,
      margin: 0,
      borderRadius: 12,
      verticalPadding: 12,
      horizontalPadding: 0,
    );
  }
}
