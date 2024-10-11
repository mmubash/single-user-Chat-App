import 'dart:convert';
import 'package:chat_app/View/messageScreen.dart';
import 'package:chat_app/View/shimmerLoading.dart';
import 'package:chat_app/View/usersModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'chat_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class RoomListScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;

  RoomListScreen({required this.currentUserId, required this.currentUserName});

  @override
  _RoomListScreenState createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  late IO.Socket socket;
  List<GetUsers> users = [];
  String? conversationId;
  GetUsers selectedUser = GetUsers();
  bool isConversationRequested = false;
  List<String> membersOnline = [];
  Map<String?, bool> userStatusMap = {};
  late String currentUser;
  late String adminName;
  @override
  void initState() {
    super.initState();
    print("This is User Id on Room List Screen${widget.currentUserId}");
    socket = IO.io('ws://192.168.2.189:3000', IO.OptionBuilder()
        .setTransports(['websocket'])
        .build());
    socket.connect();
    socket.onConnect((_) {
      print('Connected to the server(RoomListScreen)');
      socket.emit('getAdmins');
      socket.emit("userOnline", [widget.currentUserId]);
      getAllUser();
      updateUser();
    });

  }

  void updateUser() {
    socket.on("updateUserStatus", (data) {
      Map onlineUsers = data["onlineUsers"];
      membersOnline.clear();
      onlineUsers.forEach((key, value) {
        if (value != null) {
          membersOnline.add(key);
          print("members that online:$membersOnline");
        }
      });
      setState(() {
        for (var user in users) {
          userStatusMap[user.sId] = membersOnline.contains(user.sId);
        }
      });
      print("This is Update User status Dat$data");
    });
  }

  void getAllUser() {
    socket.on('getAdmins', (data) {
      print('Received all users: $data');
      setState(() {
        adminName=data[0]["name"];
        print("This is Admin name$adminName");
        users = (data as List).map((json) => GetUsers.fromJson(json)).toList();
        userStatusMap = {};
        for (var user in users) {
          userStatusMap[user.sId] = membersOnline.contains(user.sId);
        }
      });
      print('User Status Map List on mySide: $userStatusMap');
    });
  }

  @override
  Widget build(BuildContext context) {

    if (users.isEmpty) {
      double screenWidth= MediaQuery.of(context).size.width;
      double screenHeight= MediaQuery.of(context).size.height;
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading....'),
          backgroundColor: Color(0xff72BF78),
          automaticallyImplyLeading: false,
        ),
        body: ShimmerLoading(
          height: screenHeight*.30,
          width: screenWidth,
        ),
        // body: Center(
        //   child:CircularProgressIndicator(color:Color(0xff72BF78),),
        // ),
      );
    } else {
      final adminUser = users.firstWhere((user) => user.sId != widget.currentUserId);

      return Scaffold(
        appBar: AppBar(
          title: Text('Admin Contact',),
          backgroundColor: Color(0xff72BF78),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Center(
                child: Lottie.asset(
                  "assets/animation.json",
                  width: 250,
                  height: 250,
                  fit: BoxFit.fill,
                ),
              ),
              SizedBox(height: 20,),
              Center(
                child: SizedBox(
                  height: 200,
                  child: Card(
                    color: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: InkWell(
                      onTap: () {
                        selectedUser = adminUser;
                        // newConversation(widget.currentUserId, adminUser.sId.toString());
                        // room(widget.currentUserId, adminUser.sId);
                        socket.emit("getMessages",[widget.currentUserId]);
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatScreen(conversationId: widget.currentUserId,username: adminName,)));
                        // Navigator.push(context, MaterialPageRoute(builder: (context)=>MessageScreen()));
                      },
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text("Want to Chat with Admin?",
                                style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                fontSize: 20,
                              ),),
                              SizedBox(height: 20,),
                              ListTile(
                                leading: Container(
                                  height: 60,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                  ),
                                  child: Icon(Icons.person, color: Colors.white,),
                                  alignment: Alignment.center,
                                ),
                                title: Text(
                                  adminUser.name ?? "No Name",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                subtitle: Text(
                                  userStatusMap[adminUser.sId] ?? false ? "Online" : "Offline",
                                  style: TextStyle(
                                    color: userStatusMap[adminUser.sId] ?? false ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w500,
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
              ),
            ],
          ),
        ),
      );
    }
  }
}
