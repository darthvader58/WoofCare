import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';

import '/config/constants.dart';
import '/services/auth.dart';
import '/ui/widgets/auth_background.dart';
import '/ui/widgets/auth_container.dart';
import '/ui/widgets/custom_button.dart';
import '/ui/widgets/custom_textfield.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();
  final _errorTextController = TextEditingController();
  var _visibleMessage = false;
  var _hidePassword = true;

  String? errorMessage = "";
  bool rememberMe = false;

  // Hide error or other messages after a set amount of time
  void hideMessage() {
    // Future.delayed used to hide message after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _visibleMessage = false;
        });
      }
    });
  }

  // Toggle the visibility of password
  void _showPassword() {
    setState(() {
      _hidePassword = !_hidePassword;
    });
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
                    //Welcome Back Message
                    const Text(
                      textAlign: TextAlign.center,
                      "Welcome Back to WoofCare!",
                      style: TextStyle(
                        color: WoofCareColors.primaryTextAndIcons,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Divider(
                      color: WoofCareColors.primaryTextAndIcons,
                      thickness: 3,
                      indent: 50,
                      endIndent: 50,
                    ),

                    const SizedBox(height: 35),

                    //Email Field
                    CustomTextField(
                      controller: _emailTextController,
                      hintText: "Email",
                      prefix: Icons.email,
                    ),

                    const SizedBox(height: 35),

                    CustomTextField(
                      controller: _passwordTextController,
                      hintText: "Password",
                      obscureText: _hidePassword,
                      prefix: Icons.lock,
                      onSuffixTap: () => _showPassword(),
                      suffix:
                          _hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                      maxLines: 1,
                    ),

                    const SizedBox(height: 7),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //Remember Me Text & Checkbox
                          Row(
                            children: [
                              const Text(
                                "Remember Me",
                                style: TextStyle(
                                  color: WoofCareColors.primaryTextAndIcons,
                                  fontSize: 12,
                                ),
                              ),
                              Checkbox(
                                value: rememberMe,
                                side: const BorderSide(
                                  color: WoofCareColors.primaryTextAndIcons,
                                ),
                                activeColor: WoofCareColors.buttonColor,
                                onChanged: (bool? value) {
                                  setState(() {
                                    rememberMe = value ?? false;
                                  });
                                },
                              ),
                            ],
                          ),

                          // Forgot Password Button
                          RichText(
                            text: TextSpan(
                              text: "Forgot Password?",
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: WoofCareColors.interactibleText,
                              ),
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap =
                                        () => Navigator.pushNamed(
                                          context,
                                          "/forgotpw",
                                        ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25.0),

                    //Log In Button
                    CustomButton(
                      text: "Log In",
                      icon: Icons.login,
                      // margin: 30,
                      onTap:
                          () => Auth.login(
                            context: context,
                            email: _emailTextController.text.trim(),
                            password: _passwordTextController.text.trim(),
                            error: (e) {
                              // If email is not valid, then display error message
                              setState(() {
                                _visibleMessage = true;

                                if (e.code == "channel-error") {
                                  // Could be improved upon
                                  errorMessage =
                                      "Please provide an email and/or password";
                                } else if (e.code == "invalid-email") {
                                  errorMessage =
                                      "Email address is badly formatted";
                                } else if (e.code == "invalid-credential") {
                                  errorMessage =
                                      "Auth credential is malformed or has expired.";
                                }

                                _errorTextController.text = errorMessage ?? '';
                              });

                              hideMessage();
                            },
                          ),
                    ),

                    const SizedBox(height: 15),

                    //First Time User? Sign Up Button
                    RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: const TextStyle(
                          fontFamily: "ABeeZee",
                          color: WoofCareColors.primaryTextAndIcons,
                          fontSize: 12,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: "Sign Up",
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: WoofCareColors.interactibleText,
                            ),
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap =
                                      () => Navigator.pushNamed(
                                        context,
                                        "/signup",
                                      ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Error Message
                    AnimatedOpacity(
                      opacity: _visibleMessage ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          textAlign: TextAlign.center,
                          _errorTextController.text,
                          style: const TextStyle(
                            color: WoofCareColors.errorMessageColor,
                            fontSize: 12,
                          ),
                        ),
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
