import 'package:flutter/material.dart';
import 'package:woofcare/services/auth.dart';
import 'package:woofcare/ui/widgets/web_design_system.dart';

import '/config/colors.dart';
import '/config/constants.dart';
import '/ui/widgets/auth_background.dart';
import '/ui/widgets/auth_container.dart';
import '/ui/widgets/custom_button.dart';
import '/ui/widgets/custom_textfield.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailTextController = TextEditingController();
  final _notificationTextController = TextEditingController();
  var _visible = false;
  var _verified = false;

  String? errorMessage = "";

  @override
  void dispose() {
    _emailTextController.dispose();
    super.dispose();
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

  void passwordReset() {
    Auth.passwordReset(
      email: _emailTextController.text.trim(),
      context: context,
      success: () {
        setState(() {
          _visible = true;
          _verified = true;

          _notificationTextController.text = "Check your email inbox!";
        });
      },
      error: (e) {
        setState(() {
          _visible = true;

          if (e.code == "channel-error") {
            // Could be improved upon
            errorMessage = "Please provide an email";
          } else if (e.code == "invalid-email") {
            errorMessage = "Email address is badly formatted";
          } else {
            errorMessage = e.message;
          }

          _notificationTextController.text = errorMessage ?? '';
        });

        hideMessage();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final web = WoofCareWebDesign.enabled;

    return Scaffold(
      backgroundColor: web
          ? WoofCareWebDesign.canvas
          : WoofCareColors.primaryBackground,
      resizeToAvoidBottomInset: false,
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: AuthContainer(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,

                  children: [
                    // Back button (return to login page)
                    Container(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          tooltip: "Back to Log In",
                          color: WoofCareColors.primaryTextAndIcons,
                        ),
                      ),
                    ),

                    // Heading
                    Text(
                      textAlign: TextAlign.center,
                      "Reset your password",
                      style: TextStyle(
                        color: web
                            ? WoofCareWebDesign.text
                            : WoofCareColors.primaryTextAndIcons,
                        fontSize: web ? 25 : 25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: web ? -0.4 : 0,
                      ),
                    ),

                    const SizedBox(height: 5.0),

                    // Body text
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 10.0,
                      ),
                      child: Text(
                        web
                            ? 'Enter the email associated with your account. We will send you a secure reset link.'
                            : "No worries, we got you! Just provide your email and we will send a link to help you reset your password",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: web
                              ? WoofCareWebDesign.textMuted
                              : WoofCareColors.primaryTextAndIcons,
                          fontSize: web ? 14 : 13.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10.0),

                    //Email Field
                    CustomTextField(
                      controller: _emailTextController,
                      hintText: "Email",
                      prefix: Icons.email,
                    ),

                    const SizedBox(height: 35.0),

                    // "Reset Password" button
                    CustomButton(
                      text: "Reset Password",
                      margin: 40,
                      onTap: () => passwordReset(),
                    ),

                    // Error Message
                    AnimatedOpacity(
                      opacity: _visible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          textAlign: TextAlign.center,
                          _notificationTextController.text,
                          style: TextStyle(
                            color: _verified
                                ? WoofCareColors.primaryTextAndIcons
                                : WoofCareColors.errorMessageColor,
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
