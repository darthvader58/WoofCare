import 'package:cloud_firestore/cloud_firestore.dart';

import '/config/constants.dart';

class Profile {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final DocumentReference reference;
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
  });

  static Future<Profile> fromID(String id) async {
    final DocumentSnapshot doc =
        await FIRESTORE.collection("users").doc(id).get();

    if (!doc.exists) {
      throw StateError("No profile document found for signed-in user $id");
    }

    return Profile(
      id: id,
      name: doc.get("name") as String,
      email: doc.get("email") as String,
      role: doc.get("role") as String,
      bio: doc.get("bio") as String,
      phone: doc.get("phone") as String,
      reference: doc.reference,
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
      return Profile(
        id: doc.id,
        name: doc.get("name") as String,
        email: doc.get("email") as String,
        role: doc.get("role") as String,
        bio: doc.get("bio") as String,
        phone: doc.get("phone") as String,
        reference: doc.reference,
      );
    }
    return null;
  }

  Future<void> updateProfile() async {
    try {
      await reference.update({'bio': bio});
    } catch (e) {
      // TODO: Handle error appropriately
    }
  }

  Map<String, dynamic> toJson() => {"name": name, "email": email, "role": role};
}
