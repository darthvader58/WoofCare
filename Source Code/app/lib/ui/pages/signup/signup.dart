import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/config/constants.dart';

import '/services/auth.dart';
import '/ui/widgets/auth_account_type_tabs.dart';
import '/ui/widgets/auth_background.dart';
import '/ui/widgets/auth_container.dart';
import '/ui/widgets/custom_button.dart';
import '/ui/widgets/custom_dropdown.dart';
import '/ui/widgets/custom_textfield.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameTextController = TextEditingController();
  final TextEditingController _phoneTextController = TextEditingController();
  final TextEditingController _dateOfBirthTextController =
      TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _passwordConfirmTextController =
      TextEditingController();
  final TextEditingController _errorTextController = TextEditingController();

  final TextEditingController _organizationNameTextController =
      TextEditingController();
  final TextEditingController _organizationStreet1TextController =
      TextEditingController();
  final TextEditingController _organizationStreet2TextController =
      TextEditingController();
  final TextEditingController _organizationWebsiteTextController =
      TextEditingController();
  final TextEditingController _organizationNotesTextController =
      TextEditingController();

  AuthAccountType _accountType = AuthAccountType.member;
  bool _visible = false;
  bool _acceptedTerms = false;

  final List<String> roles = [
    "Animal Lover",
    "NGO Representative",
    "Looking to Adopt",
    "Dog Feeder",
    "Veterinarian",
  ];

  final List<String> organizationTypes = [
    "Animal Shelter",
    "Veterinary Clinic",
    "Rescue NGO",
    "Adoption Center",
    "Feeding Group",
    "Other",
  ];

  String role = "";
  String organizationType = "";
  String? errorMessage = "";

  @override
  void initState() {
    super.initState();
    _passwordTextController.addListener(_clearPasswordMatchError);
    _passwordConfirmTextController.addListener(_clearPasswordMatchError);
  }

  @override
  void dispose() {
    _nameTextController.dispose();
    _phoneTextController.dispose();
    _dateOfBirthTextController.dispose();
    _emailTextController.dispose();
    _passwordTextController.dispose();
    _passwordConfirmTextController.dispose();
    _errorTextController.dispose();
    _organizationNameTextController.dispose();
    _organizationStreet1TextController.dispose();
    _organizationStreet2TextController.dispose();
    _organizationWebsiteTextController.dispose();
    _organizationNotesTextController.dispose();
    super.dispose();
  }

  void hideMessage() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _visible = false;
        });
      }
    });
  }

  void _showError(String message) {
    setState(() {
      _visible = true;
      _errorTextController.text = message;
    });
    hideMessage();
  }

  void _clearPasswordMatchError() {
    if (_errorTextController.text == "Passwords do not match!" &&
        _passwordTextController.text == _passwordConfirmTextController.text) {
      setState(() {
        _visible = false;
        _errorTextController.clear();
      });
    }
  }

  void signup() {
    if (!_acceptedTerms) {
      _showError("Please accept the terms to continue");
      return;
    }

    if (!_hasRequiredFields()) {
      _showError("Please complete every required field");
      return;
    }

    if (!_passwordsMatch()) {
      _showError("Passwords do not match!");
      return;
    }

    Auth.signup(
      context: context,
      email: _emailTextController.text.trim(),
      password: _passwordTextController.text.trim(),
      data:
          _accountType == AuthAccountType.organization
              ? _organizationSignupData()
              : _memberSignupData(),
      error: (e) {
        setState(() {
          _visible = true;

          if (e.code == "channel-error") {
            errorMessage = "Please provide an email and/or password";
          } else if (e.code == "invalid-email") {
            errorMessage = "Email address is badly formatted";
          } else {
            errorMessage = e.message;
          }

          _errorTextController.text = errorMessage ?? '';
        });

        hideMessage();
      },
    );
  }

  bool _hasRequiredFields() {
    final sharedFieldsAreFilled =
        _emailTextController.text.trim().isNotEmpty &&
        _phoneTextController.text.trim().isNotEmpty &&
        _passwordTextController.text.trim().isNotEmpty &&
        _passwordConfirmTextController.text.trim().isNotEmpty;

    if (!sharedFieldsAreFilled) return false;

    if (_accountType == AuthAccountType.organization) {
      return _organizationNameTextController.text.trim().isNotEmpty &&
          _organizationStreet1TextController.text.trim().isNotEmpty &&
          organizationType.isNotEmpty;
    }

    return _nameTextController.text.trim().isNotEmpty &&
        _dateOfBirthTextController.text.trim().isNotEmpty &&
        role.isNotEmpty;
  }

  bool _passwordsMatch() {
    return _passwordTextController.text == _passwordConfirmTextController.text;
  }

  Map<String, dynamic> _memberSignupData() {
    return {
      "accountType": AuthAccountType.member.name,
      "bio": "",
      "phone": _phoneTextController.text.trim(),
      "dob": _dateOfBirthTextController.text.trim(),
      "email": _emailTextController.text.trim(),
      "name": _nameTextController.text.trim(),
      "role": role,
      "shareProfile": true,
      "verified": false,
    };
  }

  Map<String, dynamic> _organizationSignupData() {
    return {
      "accountType": AuthAccountType.organization.name,
      "bio": _organizationNotesTextController.text.trim(),
      "phone": _phoneTextController.text.trim(),
      "email": _emailTextController.text.trim(),
      "name": _organizationNameTextController.text.trim(),
      "role": organizationType,
      "organizationType": organizationType,
      "website": _organizationWebsiteTextController.text.trim(),
      "addressStreet1": _organizationStreet1TextController.text.trim(),
      "addressStreet2": _organizationStreet2TextController.text.trim(),
      "verified": false,
      "shareProfile": true,
    };
  }

  void pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      lastDate: DateTime.now(),
      firstDate: DateTime(1980),
      initialDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.aBeeZeeTextTheme(),
            colorScheme: ThemeData.light().colorScheme.copyWith(
              primary: Colors.white,
              secondary: Colors.white,
              onSurface: Colors.black,
              onPrimary: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFA66E38),
                textStyle: GoogleFonts.aBeeZee(),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              labelStyle: GoogleFonts.aBeeZee(),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate == null) return;

    _dateOfBirthTextController.text = DateFormat(
      "yyyy-MM-dd",
    ).format(pickedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WoofCareColors.primaryBackground,
      resizeToAvoidBottomInset: true,
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                25,
                24,
                25,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: AuthContainer(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AuthAccountTypeTabs(
                      selected: _accountType,
                      onChanged: (type) {
                        setState(() {
                          _accountType = type;
                          _visible = false;
                          _errorTextController.clear();
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Create Your Account",
                      style: TextStyle(
                        color: WoofCareColors.primaryTextAndIcons,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),

                    const SizedBox(height: 24),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child:
                          _accountType == AuthAccountType.organization
                              ? _buildOrganizationFields()
                              : _buildMemberFields(),
                    ),

                    const SizedBox(height: 10),

                    _buildTermsRow(),

                    const SizedBox(height: 10),

                    AnimatedOpacity(
                      opacity: _visible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _errorTextController.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: WoofCareColors.errorMessageColor,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    CustomButton(
                      text: "Sign Up",
                      icon:
                          _accountType == AuthAccountType.organization
                              ? Icons.business
                              : Icons.person_add_alt_1,
                      onTap: signup,
                    ),

                    const SizedBox(height: 16),

                    RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: const TextStyle(
                          fontFamily: "ABeeZee",
                          color: WoofCareColors.primaryTextAndIcons,
                          fontSize: 12,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: "Sign In",
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: WoofCareColors.interactibleText,
                            ),
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap =
                                      () => Navigator.pushNamed(
                                        context,
                                        "/login",
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberFields() {
    return Column(
      key: const ValueKey('member-fields'),
      children: [
        CustomTextField(
          controller: _nameTextController,
          hintText: "Name",
          prefix: Icons.person,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _phoneTextController,
          hintText: "Phone",
          prefix: Icons.phone,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _dateOfBirthTextController,
          hintText: "Date of Birth",
          prefix: Icons.calendar_today,
          suffix: Icons.arrow_drop_down,
          onTap: () => pickDate(context),
        ),
        _buildDropdownPadding(
          child: CustomDropdown<String>(
            heading: "Role",
            title: "Select a Role",
            label: "Search",
            itemAsString: (val) => val,
            icon: Icons.work,
            selectedItem: role.isEmpty ? null : role,
            items: roles,
            onChanged: (String? val) {
              setState(() {
                role = val ?? "";
              });
            },
          ),
        ),
        _buildSharedCredentialFields(),
      ],
    );
  }

  Widget _buildOrganizationFields() {
    return Column(
      key: const ValueKey('organization-fields'),
      children: [
        CustomTextField(
          controller: _organizationNameTextController,
          hintText: "Organization Name",
          prefix: Icons.business,
        ),
        const SizedBox(height: 10),
        _buildSharedCredentialFields(includePhone: false),
        const SizedBox(height: 10),
        _buildSectionLabel("Location:"),
        CustomTextField(
          controller: _organizationStreet1TextController,
          hintText: "Street Address 1",
          prefix: Icons.location_on,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _organizationStreet2TextController,
          hintText: "Street Address 2",
          prefix: Icons.location_on_outlined,
        ),
        const SizedBox(height: 10),
        _buildSectionLabel("Contact:"),
        CustomTextField(
          controller: _organizationWebsiteTextController,
          hintText: "Website",
          prefix: Icons.public,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _phoneTextController,
          hintText: "Phone",
          prefix: Icons.phone,
        ),
        _buildDropdownPadding(
          child: CustomDropdown<String>(
            heading: "Organization Type",
            title: "Type of Organization",
            label: "Search",
            itemAsString: (val) => val,
            icon: Icons.apartment,
            selectedItem: organizationType.isEmpty ? null : organizationType,
            items: organizationTypes,
            onChanged: (String? val) {
              setState(() {
                organizationType = val ?? "";
              });
            },
          ),
        ),
        CustomTextField(
          controller: _organizationNotesTextController,
          hintText: "Anything else we need to know about your organization?",
          prefix: Icons.notes,
          minLines: 3,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildSharedCredentialFields({bool includePhone = true}) {
    return Column(
      children: [
        if (includePhone) ...[
          CustomTextField(
            controller: _phoneTextController,
            hintText: "Phone",
            prefix: Icons.phone,
          ),
          const SizedBox(height: 10),
        ],
        CustomTextField(
          controller: _emailTextController,
          hintText: "Email",
          prefix: Icons.email,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _passwordTextController,
          hintText: "Password",
          obscureText: true,
          prefix: Icons.lock,
          maxLines: 1,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _passwordConfirmTextController,
          hintText: "Confirm Password",
          obscureText: true,
          prefix: Icons.lock,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildDropdownPadding({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: child,
    );
  }

  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: Text(
          text,
          style: const TextStyle(
            color: WoofCareColors.primaryTextAndIcons,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptedTerms,
          activeColor: WoofCareColors.buttonColor,
          side: const BorderSide(color: WoofCareColors.backgroundElementColor),
          onChanged: (value) {
            setState(() {
              _acceptedTerms = value ?? false;
            });
          },
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text.rich(
              TextSpan(
                text: "By clicking on ‘sign up’, you’re agreeing to the ",
                children: const [
                  TextSpan(
                    text: "WoofCare Terms of Service",
                    style: TextStyle(color: Color(0xFF007AFF)),
                  ),
                  TextSpan(text: " and "),
                  TextSpan(
                    text: "Privacy Policy",
                    style: TextStyle(color: Color(0xFF007AFF)),
                  ),
                ],
              ),
              style: const TextStyle(
                color: WoofCareColors.primaryTextAndIcons,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
