import 'package:cloud_firestore/cloud_firestore.dart';

import '/config/constants.dart';

class Profile {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final DocumentReference reference;
  bool shareProfile;
  String bio;
  var chats = [];

  Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.bio,
    required this.phone,
    required this.reference,
    this.shareProfile = true,
  });

  static Future<Profile> fromID(String id) async {
    final DocumentSnapshot doc =
        await FIRESTORE.collection("users").doc(id).get();

    if (!doc.exists) {
      throw StateError("No profile document found for signed-in user $id");
    }

    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Profile(
      id: id,
      name: data["name"] as String,
      email: data["email"] as String,
      role: data["role"] as String,
      bio: data["bio"] as String,
      phone: data["phone"] as String,
      reference: doc.reference,
      shareProfile: data["shareProfile"] as bool? ?? true,
    );
  }

  static Future<Profile?> fromName(String name) async {
    final QuerySnapshot snapshot =
        await FIRESTORE
            .collection("users")
            .where("name", isEqualTo: name)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return Profile(
        id: doc.id,
        name: data["name"] as String,
        email: data["email"] as String,
        role: data["role"] as String,
        bio: data["bio"] as String,
        phone: data["phone"] as String,
        reference: doc.reference,
        shareProfile: data["shareProfile"] as bool? ?? true,
      );
    }
    return null;
  }

  Future<void> updateProfile() async {
    try {
      await reference.update({'bio': bio, 'shareProfile': shareProfile});
    } catch (e) {
      // TODO: Handle error appropriately
    }
  }

  Map<String, dynamic> toJson() => {"name": name, "email": email, "role": role};
}
