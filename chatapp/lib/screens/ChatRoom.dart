import 'dart:io';
import 'package:chatapp/utility/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ChatRoom extends StatelessWidget {
  final Map<String, dynamic> userMap;
  final String chatRoomId;

  ChatRoom({required this.chatRoomId, required this.userMap});

  final TextEditingController _message = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  File? imageFile;

  Future getImage() async {
    ImagePicker picker = ImagePicker();

    await picker.pickImage(source: ImageSource.gallery).then((xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        uploadImage();
      }
    });
  }

  Future uploadImage() async {
    String fileName = const Uuid().v1();
    int status = 1;

    await _firestore
        .collection('chatroom')
        .doc(chatRoomId)
        .collection('chats')
        .doc(fileName)
        .set({
      "sendby": _auth.currentUser!.displayName,
      "message": "",
      "type": "img",
      "time": FieldValue.serverTimestamp(),
      "status": "sent", // Set the initial status as "sent"
    });

    var ref =
        FirebaseStorage.instance.ref().child('images').child("$fileName.jpg");

    // ignore: body_might_complete_normally_catch_error
    var uploadTask = await ref.putFile(imageFile!).catchError((error) async {
      await _firestore
          .collection('chatroom')
          .doc(chatRoomId)
          .collection('chats')
          .doc(fileName)
          .delete();

      status = 0;
    });

    if (status == 1) {
      String imageUrl = await uploadTask.ref.getDownloadURL();

      await _firestore
          .collection('chatroom')
          .doc(chatRoomId)
          .collection('chats')
          .doc(fileName)
          .update({
        "message": imageUrl,
        "status": "sent"
      }); // Update the status to "sent" when the image is uploaded

      print(imageUrl);
    }
  }

  void onSendMessage() async {
    if (_message.text.isNotEmpty) {
      Map<String, dynamic> messages = {
        "sendby": _auth.currentUser!.displayName,
        "message": _message.text,
        "type": "text",
        "time": FieldValue.serverTimestamp(),
        "status": "sent", // Set the initial status as "sent"
      };

      _message.clear();
      await _firestore
          .collection('chatroom')
          .doc(chatRoomId)
          .collection('chats')
          .add(messages);
    } else {
      print("Enter Some Text");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 17, 110, 187),
        title: StreamBuilder<DocumentSnapshot>(
          stream:
              _firestore.collection("users").doc(userMap['uid']).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.data != null) {
              return Container(
                child: Column(
                  children: [
                    Text(
                      userMap['name'],
                      style: TextStyle(
                        fontSize: 20,
                        letterSpacing: 1,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      snapshot.data!['status'],
                      style: const TextStyle(
                        fontSize: 14,
                        letterSpacing: 1,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Container();
            }
          },
        ),
        toolbarHeight: 50,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18.0),
            child: const Icon(
              CupertinoIcons.phone,
              size: 25.0,
              color: Colors.white,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18.0),
            child: const Icon(
              CupertinoIcons.camera,
              size: 25.0,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: size.height / 1.25,
              width: size.width,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chatroom')
                    .doc(chatRoomId)
                    .collection('chats')
                    .orderBy("time", descending: false)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.data != null) {
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> map = snapshot.data!.docs[index]
                            .data() as Map<String, dynamic>;
                        return messages(size, map, context);
                      },
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(bottom: 40.0), // Add margin bottom here
              child: Container(
                height: size.height / 10,
                width: size.width,
                alignment: Alignment.center,
                child: Container(
                  height: size.height / 12,
                  width: size.width / 1.1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: size.height / 10,
                        width: size.width / 1.3,
                        child: TextField(
                          controller: _message,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              onPressed: () => getImage(),
                              icon: const Icon(Icons.photo,
                                  color: AppColors.MyColor),
                            ),
                            hintText: "Send Message",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: AppColors.MyColor,
                        ),
                        onPressed: onSendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  Widget messages(Size size, Map<String, dynamic> map, BuildContext context) {
  return map['type'] == "text"
      ? GestureDetector(
          onLongPress: () {
            if (map['sendby'] == _auth.currentUser!.displayName) {
              _showEditDeleteDialog(context, map);
            }
          },
          child: Container(
            width: size.width,
            alignment: map['sendby'] == _auth.currentUser!.displayName
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: map['sendby'] == _auth.currentUser!.displayName ? 
                BorderRadius.only(
                  bottomRight: Radius.circular(15.0),
                  topRight: Radius.circular(0.0),
                  topLeft: Radius.circular(15.0),
                  bottomLeft: Radius.circular(15.0),
                ):
                BorderRadius.only(
                  bottomRight: Radius.circular(15.0),
                  topRight: Radius.circular(15.0),
                  topLeft: Radius.circular(0.0),
                  bottomLeft: Radius.circular(15.0),
                ),
                color: map['sendby'] == _auth.currentUser!.displayName
                    ? AppColors.MyColor
                    : Colors.blue[50],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    map['message'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: map['sendby'] == _auth.currentUser!.displayName
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      : GestureDetector(
          onLongPress: () {
            if (map['sendby'] == _auth.currentUser!.displayName) {
              _showEditDeleteDialog(context, map);
            }
          },
          child: Container(
            height: size.height / 2.3,
            width: size.width,
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5), // Adjust padding here
            alignment: map['sendby'] == _auth.currentUser!.displayName
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: ClipRect(
              child: Container(
                height: size.height / 3, // Adjust the height as needed
                width: size.width / 2,  // Adjust the width as needed
                alignment: map['type'] == "img" && map['message'] == ""
                    ? Alignment.center
                    : null,
                child: Column(
                  children: [
                    Container(
                      height: size.height / 3, // Adjust the height as needed
                      width: size.width / 2,  // Adjust the width as needed
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15.0),
                        color: map['sendby'] == _auth.currentUser!.displayName
                            ? AppColors.MyColor
                            : Colors.blue[50],
                      ),
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ShowImage(
                              imageUrl: map['message'],
                            ),
                          ),
                        ),
                        child: Image.network(
                          map['message'],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (map['sendby'] != _auth.currentUser!.displayName &&
                        map['status'] == 'seen')
                      const Icon(
                        Icons.done_all,
                        color: Colors.blue,
                        size: 16.0,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
}


  void _showEditDeleteDialog(BuildContext context, Map<String, dynamic> map) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Message Options"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.MyColor,
                    backgroundColor: Colors.white),
                onPressed: () {
                  // Implement edit functionality here
                  Navigator.pop(context); // Close the dialog
                },
                child: Text("Edit"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.MyColor,
                ),
                onPressed: () {
                  // Implement delete functionality here
                  Navigator.pop(context); // Close the dialog
                },
                child: Text("Delete"),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ShowImage extends StatelessWidget {
  final String imageUrl;

  const ShowImage({required this.imageUrl, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        color: Colors.black,
        child: Image.network(imageUrl),
      ),
    );
  }
}
