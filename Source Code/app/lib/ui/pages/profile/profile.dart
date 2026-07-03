import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:woofcare/models/profile.dart';
import 'package:woofcare/ui/pages/settings/settings.dart';
import 'package:woofcare/ui/widgets/contact_info.dart';
import 'package:woofcare/ui/widgets/custom_button.dart';
import 'package:woofcare/ui/widgets/editable_profilepic.dart';

import '/config/colors.dart';
import '/config/constants.dart';

class ProfilePage extends StatefulWidget {
  final Profile user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

// Model class for a fact option
class FactOption {
  final IconData icon;
  final String label;

  FactOption(this.icon, this.label);
}

class _ProfilePageState extends State<ProfilePage> {
  final _bioTextController = TextEditingController();

  // Track whether we are in edit mode or view mode
  bool _editMode = false;
  ImageProvider? profileImage;
  String email = "example@email.com";
  String phone = "(123) 456-7890";
  String name = "";
  String role = "";
  String bio = "";

  bool isLoading = true;
  bool isCurrentUser = true;

  //TODO: connect to database for more facts
  final List<FactOption> _factOptions = [
    FactOption(Icons.pets, "Has a dog"),
    FactOption(Icons.volunteer_activism, "Volunteers"),
    FactOption(Icons.favorite, "Looking to adopt"),
    FactOption(Icons.school, "Dog trainer"),
    FactOption(
      Icons.health_and_safety,
      "Passionate about pet health and wellness.",
    ),
    FactOption(Icons.nature_people, "Loves outdoor activities with pets."),
    FactOption(Icons.home, "Works at an animal shelter."),
  ];

  //TODO: connect to database to save selected facts between sessions to display
  final List<FactOption> _selOptions = [];

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  void _initProfile() {
    final user = widget.user;

    setState(() {
      name = user.name;
      email = user.email;
      role = user.role;
      bio = user.bio;
      phone = user.phone;
      _bioTextController.text = bio;
      isCurrentUser = user.name.trim() == profile.name.trim();
      isLoading = false;
    });
  }

  Future<void> _openChat(BuildContext context) async {
    try {
      QuerySnapshot snapshot =
          await FIRESTORE
              .collection('conversations')
              .where("participantIds", arrayContains: profile.id)
              .get();

      var conversations = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        if (data['isReportChat'] == true) return false;
        final participantIds = data['participantIds'] as List? ?? [];
        return participantIds.contains(widget.user.id);
      });

      String chatID;
      if (conversations.isEmpty) {
        DocumentReference newConvo = await FIRESTORE
            .collection("conversations")
            .add({
              "messages": [],
              "participants": [profile.name, name],
              "participantIds": [profile.id, widget.user.id],
            });
        chatID = newConvo.id;
      } else {
        chatID = conversations.first.id;
      }

      if (context.mounted) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {'chatID': chatID, 'participant': name},
        );
      }
    } catch (e) {
      // TODO: Handle error appropriately
    }
  }

  void _showFollowBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FollowBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: WoofCareColors.primaryBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: WoofCareColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: WoofCareColors.primaryBackground,
        foregroundColor: WoofCareColors.primaryTextAndIcons,
        actions:
            isCurrentUser
                ? [
                  IconButton(
                    icon: Icon(
                      _editMode ? Icons.create_rounded : Icons.create_outlined,
                      color:
                          _editMode
                              ? WoofCareColors.buttonColor
                              : WoofCareColors.primaryTextAndIcons,
                    ),
                    tooltip: "Toggle Edit Mode",
                    onPressed: () {
                      setState(() {
                        _editMode = !_editMode;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: WoofCareColors.primaryTextAndIcons,
                    ),
                    tooltip: "Settings",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                ]
                : [],
      ),
      //Header
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Dismiss keyboard on tap outside
        },
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 20), // Spacer on the left
                // Profile Picture
                EditableProfilePicture(
                  isEditMode: _editMode && isCurrentUser,
                  image: profileImage,
                ),

                //spacer between picture and text
                const SizedBox(width: 5),

                //profile information
                Expanded(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Column(
                          mainAxisSize:
                              MainAxisSize
                                  .min, // This will minimize the space needed
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Username
                            SizedBox(
                              width: 300,
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: "Roboto",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: WoofCareColors.primaryTextAndIcons,
                                ),
                              ),
                            ),

                            // Role
                            SizedBox(
                              width: 300,
                              child: Text(
                                role,
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: "Roboto",
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: WoofCareColors.primaryTextAndIcons,
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

                            //location
                            const SizedBox(
                              width: 300,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 24,
                                    color: Color(0xFF805832),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    //TODO: connect location to database + allow privacy
                                    "Location",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontFamily: "Abeezee",
                                      fontSize: 14,
                                      color: Color(0xFF805832),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 5),

                            ContactInfoSection(
                              isEditMode: _editMode && isCurrentUser,
                              email: email,
                              phone: phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20), // Spacer on the right
              ],
            ),

            // Spacer
            const SizedBox(height: 20),

            // Button Row
            if (!isCurrentUser)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 0, right: 0),
                    child: CustomButton(
                      height: 60,
                      width: 200,
                      color: WoofCareColors.backgroundElementColor,
                      fontColor: WoofCareColors.primaryTextAndIcons,
                      fontSize: 14,
                      borderRadius: 16,
                      text: "Message",
                      onTap: () => _openChat(context),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10, left: 0),
                      child: CustomButton(
                        height: 60,
                        color: WoofCareColors.buttonColor,
                        borderRadius: 16,
                        text: "Follow",
                        fontSize: 14,
                        onTap: () {
                          _showFollowBottomSheet(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),

            // Spacer
            const SizedBox(height: 20),

            // AboutInformation
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: WoofCareColors.offWhite,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    /*
                    // Row of two buttons
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(100, 25),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
    
                                vertical: 12,
    
                              ),
                              backgroundColor: WoofCareColors.buttonColor,
                            ),
                            child: Text(
                              'About',
                              style: TextStyle(
                                fontSize: 12,
                                color: WoofCareColors.offWhite,
                              ),
                            ),
                          ),
                          SizedBox(width: 25),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(100, 25),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
    
                                vertical: 12,
    
                              ),
                              backgroundColor:
                                  WoofCareColors.backgroundElementColor,
                            ),
                            child: Text(
                              'Posts',
                              style: TextStyle(
                                fontSize: 12,
                                color: WoofCareColors.primaryTextAndIcons,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    */

                    /*
                    //Stats
                    //TODO: connect stats to database
                    if (!_editMode) //Hide stats in edit mod
                      Container(
                        height:
                            60, // controls vertical height of stats and dividers
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            custom_stat('1.2K', 'Posts'),
                            VerticalDivider(
                              color: WoofCareColors.dividerColor,
                              thickness: 1,
                              indent: 10,
                              endIndent: 10,
                            ),
                            custom_stat('345', 'Followers'),
                            VerticalDivider(
                              color: WoofCareColors.dividerColor,
                              thickness: 1,
                              indent: 10,
                              endIndent: 10,
                            ),
                            custom_stat('87', 'Following'),
                            VerticalDivider(
                              color: WoofCareColors.dividerColor,
                              thickness: 1,
                              indent: 10,
                              endIndent: 10,
                            ),
                            custom_stat('5', 'Reports'),
                          ],
                        ),
                      ),
                    */

                    // Spacer
                    if (!_editMode) const SizedBox(height: 10),

                    // Biography Section
                    Text(
                      'About:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: WoofCareColors.primaryTextAndIcons,
                      ),
                    ),

                    // Biography box
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: WoofCareColors.offWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          isCurrentUser && _editMode
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  TextField(
                                    controller: _bioTextController,
                                    maxLines: 5,
                                    maxLength: 500,
                                    buildCounter: (
                                      BuildContext context, {
                                      required int currentLength,
                                      required bool isFocused,
                                      required int? maxLength,
                                    }) {
                                      return Text(
                                        '$currentLength / $maxLength',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              WoofCareColors
                                                  .primaryTextAndIcons,
                                        ),
                                      );
                                    },

                                    style: TextStyle(
                                      fontSize: 12,
                                      color: WoofCareColors.primaryTextAndIcons,
                                    ),

                                    decoration: const InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                        borderSide: BorderSide(
                                          color:
                                              WoofCareColors
                                                  .backgroundElementColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                        borderSide: BorderSide(
                                          color:
                                              WoofCareColors
                                                  .backgroundElementColor,
                                        ),
                                      ),
                                      hintText: 'Enter your biography...',
                                      hintStyle: TextStyle(
                                        color:
                                            WoofCareColors.primaryTextAndIcons,
                                      ),
                                      fillColor: WoofCareColors.textBoxColor,
                                    ),
                                  ),

                                  SizedBox(height: 10),

                                  CustomButton(
                                    text: "Save",
                                    onTap: () {},
                                    width: 120,
                                    fontSize: 16,
                                    margin: 10,
                                    borderRadius: 16,
                                    verticalPadding: 12,
                                    horizontalPadding: 12,
                                  ), //TODO: add save functionality
                                ],
                              )
                              : Text(
                                bio.isEmpty ? 'No biography available.' : bio,
                                maxLines: 5,
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: WoofCareColors.primaryTextAndIcons,
                                ),
                              ),
                    ),

                    Divider(
                      color: WoofCareColors.dividerColor,
                      thickness: 2,
                      indent: 16,
                      endIndent: 16,
                    ),

                    // List of fact item
                    Expanded(
                      child: ListView.builder(
                        itemCount:
                            isCurrentUser && _editMode
                                ? _selOptions.length + 1
                                : _selOptions.length,
                        itemBuilder: (context, index) {
                          // "add a fact" button at top of list if in edit mode
                          if (isCurrentUser && _editMode && index == 0) {
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 0,
                              ),
                              leading: Icon(
                                Icons.add,
                                color: WoofCareColors.buttonColor,
                              ),
                              title: Text(
                                "Add a new fact",
                                style: TextStyle(
                                  color: WoofCareColors.buttonColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () async {
                                FactOption?
                                newFact = await showDialog<FactOption>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    FactOption? selectedFact =
                                        _factOptions.first;
                                    return AlertDialog(
                                      backgroundColor: WoofCareColors.offWhite,
                                      title: Text(
                                        "Choose a fact",
                                        style: TextStyle(
                                          color:
                                              WoofCareColors
                                                  .primaryTextAndIcons,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: StatefulBuilder(
                                        builder: (context, setModalState) {
                                          return DropdownButton<FactOption>(
                                            isExpanded: true,
                                            value: selectedFact,
                                            dropdownColor:
                                                WoofCareColors.offWhite,
                                            items:
                                                _factOptions.map((fact) {
                                                  return DropdownMenuItem<
                                                    FactOption
                                                  >(
                                                    value: fact,
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          fact.icon,
                                                          color:
                                                              WoofCareColors
                                                                  .primaryTextAndIcons,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Flexible(
                                                          child: Text(
                                                            fact.label,
                                                            softWrap: true,
                                                            overflow:
                                                                TextOverflow
                                                                    .visible,
                                                            style: TextStyle(
                                                              color:
                                                                  WoofCareColors
                                                                      .primaryTextAndIcons,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                            onChanged: (value) {
                                              setModalState(() {
                                                selectedFact = value!;
                                              });
                                            },
                                          );
                                        },
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, null),
                                          child: Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (selectedFact == null) return;

                                            // Check if the fact already exists in the list
                                            final alreadyExists = _selOptions
                                                .any(
                                                  (f) =>
                                                      f.label ==
                                                      selectedFact!.label,
                                                );

                                            if (alreadyExists) {
                                              // Show alert/snackbar
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "This fact is already in your list.",
                                                  ),
                                                  duration: Duration(
                                                    seconds: 2,
                                                  ),
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                ),
                                              );
                                            } else {
                                              Navigator.pop(
                                                context,
                                                selectedFact,
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                WoofCareColors.buttonColor,
                                          ),
                                          child: const Text(
                                            "Add",
                                            style: TextStyle(
                                              color: WoofCareColors.offWhite,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (newFact == null) return;

                                // Add the chosen fact
                                setState(() {
                                  _selOptions.add(newFact);
                                });
                              },
                            );
                          }

                          final fact =
                              _selOptions[index -
                                  (isCurrentUser && _editMode
                                      ? 1
                                      : 0)]; // Adjust index if in edit mode
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 0,
                            ),
                            leading: Icon(
                              fact.icon,
                              color: WoofCareColors.primaryTextAndIcons,
                            ),
                            title: Text(
                              fact.label,
                              style: TextStyle(
                                color: WoofCareColors.primaryTextAndIcons,
                                fontSize: 12,
                              ),
                            ),

                            //show delete only in edit mode
                            trailing:
                                isCurrentUser && _editMode
                                    ? IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: WoofCareColors.buttonColor,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selOptions.removeAt(index - 1);
                                        });
                                      },
                                    )
                                    : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FollowBottomSheet extends StatefulWidget {
  const FollowBottomSheet({super.key});

  @override
  State<FollowBottomSheet> createState() => _FollowBottomSheetState();
}

class _FollowBottomSheetState extends State<FollowBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  //TODO: connect to database for following and followers list
  //Dummy List for users that use is following
  final List<Map<String, dynamic>> _following = [
    {'name': 'Alice Johnson', 'role': 'Pet Owner', 'photoID': 0},
    {'name': 'Bob Smith', 'role': 'Veterinarian', 'photoID': 1},
    {'name': 'Carol Williams', 'role': 'Dog Trainer', 'photoID': 2},
    {'name': 'David Brown', 'role': 'Pet Owner', 'photoID': 3},
    {'name': 'Emma Davis', 'role': 'Shelter Worker', 'photoID': 4},
  ];

  //Dummy List for users that follow the user
  final List<Map<String, dynamic>> _followers = [
    {'name': 'Frank Miller', 'role': 'Pet Owner', 'photoID': 5},
    {'name': 'Grace Wilson', 'role': 'Dog Trainer', 'photoID': 6},
    {'name': 'Henry Moore', 'role': 'Veterinarian', 'photoID': 7},
    {'name': 'Ivy Taylor', 'role': 'Pet Owner', 'photoID': 8},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: WoofCareColors.primaryBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: WoofCareColors.primaryTextAndIcons.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Tab bar
              TabBar(
                controller: _tabController,
                labelColor: WoofCareColors.buttonColor,
                unselectedLabelColor: WoofCareColors.primaryTextAndIcons,
                indicatorColor: WoofCareColors.buttonColor,
                tabs: const [Tab(text: 'Following'), Tab(text: 'Followers')],
              ),

              // Tab views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserList(_following, scrollController),
                    _buildUserList(
                      _followers,
                      scrollController,
                      isFollowers: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserList(
    List<Map<String, dynamic>> users,
    ScrollController scrollController, {
    bool isFollowers = false,
  }) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          'No ${isFollowers ? 'followers' : 'following'} yet',
          style: TextStyle(
            color: WoofCareColors.primaryTextAndIcons,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: WoofCareColors.offWhite,

            child: Icon(
              Icons.person,
              color: WoofCareColors.primaryTextAndIcons,
            ),
          ),
          title: Text(
            user['name'],
            style: const TextStyle(
              fontFamily: "Roboto",
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: WoofCareColors.primaryTextAndIcons,
            ),
          ),
          subtitle: Text(
            user['role'],
            style: const TextStyle(
              fontFamily: "Roboto",
              fontSize: 12,
              color: WoofCareColors.primaryTextAndIcons,
            ),
          ),
          trailing:
              isFollowers
                  ? IconButton(
                    icon: const Icon(Icons.person_add),
                    color: WoofCareColors.buttonColor,
                    onPressed: () {
                      // TODO: Add follow back functionality
                    },
                  )
                  : null,
          onTap: () {
            // Navigate to user profile page
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ViewProfilePage(
                      userName: user['name'],
                      photoID: user['photoID'],
                    ),
              ),
            );
          },
        );
      },
    );
  }
}

class ViewProfilePage extends StatelessWidget {
  final String userName;
  final int photoID;

  const ViewProfilePage({
    super.key,
    required this.userName,
    required this.photoID,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile?>(
      future: Profile.fromName(userName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: WoofCareColors.primaryBackground,
            body: Center(
              child: CircularProgressIndicator(
                color: WoofCareColors.buttonColor,
              ),
            ),
          );
        }

        final loadedProfile = snapshot.data;
        if (loadedProfile == null) {
          return Scaffold(
            backgroundColor: WoofCareColors.primaryBackground,
            appBar: AppBar(
              backgroundColor: WoofCareColors.primaryBackground,
              foregroundColor: WoofCareColors.primaryTextAndIcons,
            ),
            body: Center(
              child: Text(
                "Profile not found",
                style: TextStyle(
                  color: WoofCareColors.primaryTextAndIcons.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ),
          );
        }

        return ProfilePage(user: loadedProfile);
      },
    );
  }
}
