// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/models/profile.dart';

late Profile profile;
late ThemeData theme;

const bool TESTING = kDebugMode;

final FirebaseFirestore FIRESTORE = FirebaseFirestore.instance;
final FirebaseAuth AUTH = FirebaseAuth.instance;

final GlobalKey<NavigatorState> NAVIGATOR_KEY = GlobalKey<NavigatorState>();
