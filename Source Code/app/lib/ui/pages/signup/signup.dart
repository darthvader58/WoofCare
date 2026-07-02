import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/config/constants.dart';

import '/services/auth.dart';
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
  var _visible = false;

  final List<String> roles = [
    "Animal Lover",
    "NGO Representative",
    "Looking to Adopt",
    "Dog Feeder",
    "Veterinarian",
  ];

  String role = "";
  String? errorMessage = "";

  @override
  void initState() {
    super.initState();
    _passwordTextController.addListener(passwordChecker);
    _passwordConfirmTextController.addListener(passwordChecker);
    _passwordConfirmTextController.addListener(() {
      setState(() {});
    });
  }

  void hideMessage() {
    // Future.delayed used to hide message after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _visible = false;
        });
      }
    });
  }

  void signup() {
    // var progress = 0.0;

    // final controllers = [
    //   _nameTextController,
    //   _emailTextController,
    //   _passwordTextController,
    //   _passwordConfirmTextController,
    // ];

    // for (final controller in controllers) {
    //   if (controller.value.text.isNotEmpty) {
    //     progress += 1 / controllers.length;
    //   }
    // }

    if (_nameTextController.text.trim().isNotEmpty &&
        _phoneTextController.text.trim().isNotEmpty &&
        _dateOfBirthTextController.text.trim().isNotEmpty &&
        _emailTextController.text.trim().isNotEmpty &&
        _passwordTextController.text.trim().isNotEmpty &&
        _passwordConfirmTextController.text.trim().isNotEmpty &&
        role.isNotEmpty) {
      if (passwordChecker()) {
        Auth.signup(
          context: context,
          email: _emailTextController.text.trim(),
          password: _passwordTextController.text.trim(),
          data: {
            "bio": "",
            "phone": _phoneTextController.text.trim(),
            "dob": _dateOfBirthTextController.text.trim(),
            "email": _emailTextController.text.trim(),
            "name": _nameTextController.text.trim(),
            "role": role,
          },
          error: (e) {
            setState(() {
              _visible = true;

              if (e.code == "channel-error") {
                // Could be improved upon
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
    } else {
      setState(() {
        _visible = true;
        _errorTextController.text = "Please complete every required field";
      });

      hideMessage();
    }
  }

  bool passwordChecker() {
    if (_passwordTextController.text != _passwordConfirmTextController.text) {
      setState(() {
        _visible = true;
        _errorTextController.text = "Passwords do not match!";
      });

      return false;
    } else {
      setState(() {
        _visible = false;
        _errorTextController.text = "";
      });
      return true;
    }
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
                    Text(
                      "Create Your Account",
                      style: TextStyle(
                        color: WoofCareColors.primaryTextAndIcons,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Divider(
                      height: 0,
                      color: WoofCareColors.primaryTextAndIcons,
                      thickness: 1,
                      indent: 45,
                      endIndent: 45,
                    ),

                    const SizedBox(height: 25),

                    // Name text entry.
                    CustomTextField(
                      controller: _nameTextController,
                      hintText: "Name",
                      prefix: Icons.person,
                    ),

                    const SizedBox(height: 10),

                    // Name text entry.
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

                    // const SizedBox(height: 2),

                    // Selection of role.
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      child: CustomDropdown<String>(
                        heading: "Role",
                        title: "Select a Role",
                        label: "Search",
                        itemAsString: (val) => val,
                        icon: Icons.work,
                        items:
                            roles.map((String roles) {
                              return roles;
                            }).toList(),
                        onChanged: (String? val) {
                          setState(() {
                            role = val!;
                          });
                        },
                      ),
                    ),

                    // Email Text Entry
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
                      prefix: Icons.password,
                      maxLines: 1,
                    ),

                    const SizedBox(height: 10),

                    CustomTextField(
                      controller: _passwordConfirmTextController,
                      hintText: "Confirm Password",
                      obscureText: true,
                      prefix: Icons.password,
                      maxLines: 1,
                    ),

                    const SizedBox(height: 10),

                    // Passwords match OR error text.
                    AnimatedOpacity(
                      opacity: _visible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _errorTextController.text,
                        style: const TextStyle(
                          color: WoofCareColors.errorMessageColor,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    CustomButton(
                      text: "Sign up",
                      icon: Icons.person_add_alt_1,
                      onTap: signup,
                    ),

                    const SizedBox(height: 15),

                    //First Time User? Sign Up Button
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
                            text: "Log In",
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
}
