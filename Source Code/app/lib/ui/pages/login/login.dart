import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/ui/widgets/web_design_system.dart';

import '/config/constants.dart';
import '/services/auth.dart';
import '/ui/widgets/auth_account_type_tabs.dart';
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
  AuthAccountType _accountType = AuthAccountType.individual;

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
    final web = WoofCareWebDesign.enabled;

    return Scaffold(
      backgroundColor: web
          ? WoofCareWebDesign.canvas
          : WoofCareColors.primaryBackground,
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
                          _visibleMessage = false;
                          _errorTextController.clear();
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    //Welcome Back Message
                    Text(
                      textAlign: TextAlign.center,
                      web
                          ? 'Sign in to your workspace'
                          : _accountType == AuthAccountType.organization
                          ? "Welcome Back, Organization"
                          : "Welcome Back to WoofCare!",
                      style: TextStyle(
                        color: web
                            ? WoofCareWebDesign.text
                            : WoofCareColors.primaryTextAndIcons,
                        fontSize: web ? 25 : 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: web ? -0.4 : 0,
                      ),
                    ),

                    SizedBox(height: web ? 9 : 5),

                    if (web)
                      const Text(
                        'Enter your credentials to access WoofCare.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: WoofCareWebDesign.textMuted,
                          fontSize: 14,
                        ),
                      ),

                    if (!web)
                      const Divider(
                        color: WoofCareColors.primaryTextAndIcons,
                        thickness: 3,
                        indent: 50,
                        endIndent: 50,
                      ),

                    SizedBox(height: web ? 28 : 35),

                    //Email Field
                    CustomTextField(
                      controller: _emailTextController,
                      hintText: "Email",
                      prefix: Icons.email,
                    ),

                    SizedBox(height: web ? 18 : 35),

                    CustomTextField(
                      controller: _passwordTextController,
                      hintText: "Password",
                      obscureText: _hidePassword,
                      prefix: Icons.lock,
                      onSuffixTap: () => _showPassword(),
                      suffix: _hidePassword
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
                              recognizer: TapGestureRecognizer()
                                ..onTap = () =>
                                    Navigator.pushNamed(context, "/forgotpw"),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: web ? 20 : 25),

                    //Log In Button
                    CustomButton(
                      text: "Log In",
                      icon: Icons.login,
                      // margin: 30,
                      onTap: () => Auth.login(
                        context: context,
                        email: _emailTextController.text.trim(),
                        password: _passwordTextController.text.trim(),
                        expectedAccountType: _accountType.name,
                        error: (e) {
                          // If email is not valid, then display error message
                          setState(() {
                            _visibleMessage = true;

                            if (e.code == "channel-error") {
                              // Could be improved upon
                              errorMessage =
                                  "Please provide an email and/or password";
                            } else if (e.code == "invalid-email") {
                              errorMessage = "Email address is badly formatted";
                            } else if (e.code == "invalid-credential") {
                              errorMessage =
                                  "Auth credential is malformed or has expired.";
                            } else if (e.code == "wrong-account-type") {
                              errorMessage = e.message;
                            } else {
                              errorMessage = e.message;
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
                        style: TextStyle(
                          fontFamily: web ? null : "ABeeZee",
                          color: web
                              ? WoofCareWebDesign.textMuted
                              : WoofCareColors.primaryTextAndIcons,
                          fontSize: web ? 13 : 12,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: "Sign Up",
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: WoofCareColors.interactibleText,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () =>
                                  Navigator.pushNamed(context, "/signup"),
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
