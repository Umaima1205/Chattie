
import 'package:chatapp/Screens/ChatRoom.dart';
import 'package:chatapp/authentication/Methods.dart';
import 'package:chatapp/utility/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? userMap;
  bool isLoading = false;
  final TextEditingController _search = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    setStatus("Online");
  }

  void setStatus(String status) async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      "status": status,
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // online
      setStatus("Online");
    } else {
      // offline
      setStatus("Offline");
    }
  }

  String chatRoomId(String user1, String user2) {
    if (user1[0].toLowerCase().codeUnits[0] >
        user2.toLowerCase().codeUnits[0]) {
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }

  void onSearch() async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;

    setState(() {
      isLoading = true;
    });

    await _firestore
        .collection('users')
        .where("email", isEqualTo: _search.text)
        .get()
        .then((value) {
      setState(() {
        userMap = value.docs[0].data();
        isLoading = false;
      });
      print(userMap);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
        appBar:AppBar(
  backgroundColor: const Color.fromARGB(255, 17, 110, 187),
  title: const Text(
    "Chattie",
    style: TextStyle(
      fontSize: 18,
      letterSpacing: 2,
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w400,
      color: Colors.white,
    ),
  ),
  centerTitle: true,
  toolbarHeight: 70,
  elevation: 0,
  leading: IconButton(
    icon: const Icon(
      CupertinoIcons.profile_circled,
      size: 30, // Adjust the size of the icon
      color: Colors.white,
    ),
    onPressed: () {
      // Handle the leading icon tap event
    },
  ),
  
 actions: [
  GestureDetector(
    onTap: () {
      logOut(context); // Call your logOut method here
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 18.0),
      child: const Icon(
        CupertinoIcons.arrow_right_circle_fill,
        size: 25.0,
        color: Colors.white,
      ),
    ),
  ),
],


),

      body: isLoading
          ? Center(
              child: Container(
                height: size.height / 20,
                width: size.height / 20,
                child: const CircularProgressIndicator(),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: size.height / 20,
                ),
               Container(
  height: size.height / 14,
  width: size.width,
  alignment: Alignment.center,
  child: Container(
    height: size.height / 14,
    width: size.width / 1.15,
    child: TextField(
      controller: _search,
      decoration: InputDecoration(
        hintText: "Search",
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color:  Color.fromARGB(255, 17, 110, 187)), // Set the focused border color here
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey), // Set the default border color here
        ),
      ),
    ),
  ),


                ),
                 SizedBox(
                  height: size.height / 36,
                ),
                Container(
  height: 50, // Set the desired height
  width: 320, // Set the desired width
  child: ElevatedButton(
    onPressed: onSearch,
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white, 
      backgroundColor: AppColors.MyColor, // Text color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0), // Rounded corners
      ),
    ),
    child: const Text(
      "Search",
      style: TextStyle(
         fontSize: 16,
          
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,// Text size
      ),
    ),
  ),
),

                SizedBox(
                  height: size.height / 30,
                ),
                userMap != null
                    ? ListTile(
                        onTap: () {
                          String roomId = chatRoomId(
                              _auth.currentUser!.displayName!,
                              userMap!['name']);

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatRoom(
                                chatRoomId: roomId,
                                userMap: userMap!,
                              ),
                            ),
                          );
                        },
                        leading: const Icon(CupertinoIcons.person_circle_fill, color:AppColors.MyColor,size: 35),
                        title: Text(
                          userMap!['name'],
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(userMap!['email'],
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),),
                        trailing: const Icon(CupertinoIcons.bubble_left_bubble_right, color:AppColors.MyColor,size: 35,),
                      )
                    : Container(),
              ],
            ),
  
    );
  }
}