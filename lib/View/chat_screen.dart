import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data' ;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'message.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String username;
  // final String senderId;
  // final String receiverId;
  final String conversationId;
  ChatScreen({
    Key? key,
    required this.username,
    // required this.senderId,
    // required this.receiverId,
    required this.conversationId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late IO.Socket socket;
  String? base64String;
  String? fileLink;
  String? mimeType;
  String? dataUrl;
  String? senderId;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    setUserId();
    socket = IO.io('ws://192.168.2.189:3000', IO.OptionBuilder()
        .setTransports(['websocket'])
        .build());
    socket.connect();
     socket.onConnect((_) {
       print('Socket connected of chat screen ');

       // socket.emit('getConversation', {
       //   'senderId': widget.senderId,
       //   'receiverId': widget.receiverId,
       // });
     });
    _getMessages();
    _setupSocketListeners();
    // _fetchPreviousMessages();
  }
  void _setupSocketListeners() {
    socket.on('newMessage', (data) {
        print("This is Data of new message$data");
        var newMessage = data['newMessage'];
        print("newwww message$newMessage");

          if(widget.conversationId==newMessage["conversation_id"].toString()) {
            if (mounted) {
              setState(() {
                print("is this running");
                print("Conversation id****${senderId}");
                _messages.add(newMessage);
              });
            }
          }
    });

    socket.onConnectError((data) => print("Connection Error: $data"));
    socket.onDisconnect((_) => print("Disconnected"));
  }
  Future<void>setUserId()async{
    String? userId=await loadUserId();
    setState(() {
      senderId=userId;
      print("This is User Id In Chat Screen: $senderId");
    });
  }
  Future<String?> loadUserId()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
   return prefs.getString("userId");
  }


  void _getMessages(){
    socket.emit("getMessages",[widget.conversationId]);
    socket.on("receiveMessages",(data){
      String room = (data['messages'][0]['conversation_id']).toString();
      print("This is Messages dataa $data");
      print(room);
      print(senderId);
      print(room==senderId);
      if (room==senderId) {
        print("&&&&&&&&");
        print("This is Messages dataa $data");
        List<dynamic> messageJson = data['messages'];
        List<MessageModel> messages = messageJson
            .map((json) => MessageModel.fromJson(json))
            .toList();
        List<Map<String, dynamic>> messagesAsMaps = messages.map((message) => message.toJson()).toList();
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(messagesAsMaps);
          });
        }
      }
    } );
  }

  Future<void> _fetchPreviousMessages() async {
    try {
      final response = await http.get(Uri.parse(
          'http://192.168.2.189:3000/api/message/get/${widget.conversationId}'));
      if (response.statusCode == 200) {
        List<dynamic> messageJson = jsonDecode(response.body);
        List<MessageModel> messages = messageJson
            .map((json) => MessageModel.fromJson(json))
            .toList();
        List<Map<String, dynamic>> messagesAsMaps = messages.map((message) => message.toJson()).toList();
        if (mounted) {
          setState(() {
            _messages.addAll(messagesAsMaps);
          });
        }
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (error) {
      print('Error fetching messages: $error');
    }
  }
  Future<String?> pickFileAndConvertToBase64() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: false);

    if (result != null && result.files.isNotEmpty) {
      File file = File(result.files.single.path!);
      Uint8List fileBytes = await file.readAsBytes();
      String base64String = base64Encode(fileBytes);
      mimeType = lookupMimeType(file.path);
      dataUrl = 'data:$mimeType;base64,$base64String';
      // fileLink=dataUrl;
      showDialog(context: context,
          builder: (BuildContext context){
           return AlertDialog(
             content: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Image.memory(fileBytes,),
                 SizedBox(
                   height: 10,
                 ),
                 ElevatedButton(
                     onPressed: (){
                       setState(() {
                         fileLink=dataUrl;
                         print("This is File Link:$fileLink");
                         Navigator.pop(context);
                       });
                       _sendMessage();
                     },
                     child: Text("Send"))
               ],
             ),
           );
          });
           return dataUrl;
    } else {
      print('No file selected');
      return null;
    }
  }
  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty || fileLink != null) {
      String message = _controller.text;

      if (fileLink == null) {
        MessageModel newMessage = MessageModel(
          sender_id: senderId,
          // receiverId: widget.receiverId,
          text: message,
          conversation_id: senderId,
          type: 'text',
        );
        print("Message is sent");
        socket.emit('sendMessage', newMessage.toJson());
      } else {
        try {
           print("This is Link$fileLink");
          http.Response response = await http.post(
            Uri.parse("http://192.168.2.189:3001/api/message/send-image"),
            body: {
              "file": fileLink,
            }
          );

          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            String imagePath = data['path'];
            if (mimeType != null) {
              String? typedoc = dataUrl?.split('/').first;
              MessageModel newMessage = MessageModel(
                // senderId: widget.senderId,
                // receiverId: widget.receiverId,
                text: '/$imagePath',
                conversation_id: widget.conversationId,
                type: typedoc?.split(':').last,
              );
              socket.emit('sendMessage', newMessage.toJson());
              setState(() {
                fileLink=null;
              });
            } else {
              print("Could not determine MIME type");
            }
          } else {
            print('File not uploaded: Status Code ${response.statusCode}');
            print('Response: ${response.body}');
          }
        } catch (e) {
          print("This is Error: ${e.toString()}");
        }
      }
      _controller.clear();
    }
  }

  Future<VideoPlayerController> _initializeVideoPlayer(String videoUrl) async {
    Uri uri = Uri.parse(videoUrl);
    VideoPlayerController controller = VideoPlayerController.networkUrl(uri);
    await controller.initialize();
    return controller;
  }
  String format(String formatStr){
   DateTime dateTime= DateTime.parse(formatStr);
   return DateFormat.jm().format(dateTime);
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        backgroundColor: Color(0xff72BF78),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                print("This is message...$message");
                bool isSender = message['sender_id'].toString() == senderId.toString();
                print("Is sender: $isSender, Message sender_id: ${message['sender_id']}, Logged in senderId: $senderId");
                if(message['type']=='image'){
                 // String base64String = message['text'].split(',').last;
                 // typed.Uint8List _bytesImage = Base64Decoder().convert(base64String);
                 return Align(
                   alignment: isSender
                       ? Alignment.centerRight
                       : Alignment.centerLeft,
                   child: Column(
                     children: [
                       Container(
                         padding:
                         EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                         margin:
                         EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                         decoration: BoxDecoration(
                           color: isSender ? Colors.blueAccent : Colors.grey[300],
                           borderRadius: BorderRadius.circular(15),
                         ),
                         child: Image.network('http://192.168.2.189:3001${ message['text']}')
                       ),
                     ],
                   ),

                 );
               }
               else if (message['type'] == 'video') {
                 String videoUrl = message['text'];
                 return Align(
                   alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                   child: Container(
                     padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                     margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                     decoration: BoxDecoration(
                       color: isSender ? Colors.blueAccent : Colors.grey[300],
                       borderRadius: BorderRadius.circular(15),
                     ),
                     child: FutureBuilder<VideoPlayerController>(
                       future: _initializeVideoPlayer(videoUrl),
                       builder: (context, snapshot) {
                         if (snapshot.connectionState == ConnectionState.done) {
                           final controller = snapshot.data!;
                           return AspectRatio(
                             aspectRatio: controller.value.aspectRatio,
                             child: VideoPlayer(controller),
                           );
                         } else {
                           return Center(child: CircularProgressIndicator());
                         }
                       },
                     ),
                   ),
                 );
               }
               else{
                 return Align(
                   alignment: isSender
                       ? Alignment.centerRight
                       : Alignment.centerLeft,
                   child: Container(
                     padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                     margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                     decoration: BoxDecoration(
                       color: isSender ? Color(0xff72BF78):
                       Colors.grey,
                       borderRadius: isSender? BorderRadius.only(
                           topLeft:Radius.circular(20),
                           bottomLeft: Radius.circular(20),
                           bottomRight: Radius.circular(20)
                       ):BorderRadius.only(
                           topRight:Radius.circular(20),
                           bottomLeft: Radius.circular(20),
                           bottomRight: Radius.circular(20)
                       ) ,
                     ),
                     child: Padding(
                       padding: const EdgeInsets.all(8.0),
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.start,
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                          isSender? Text("~me",style:GoogleFonts.lato(color: Color(0xff81817d),fontSize: 20),):Text(
                             "~${widget.username}",
                              style:GoogleFonts.lato(color: Color(0xff81817d),fontSize: 20)
                           ),
                           Text(
                             message['text'],
                             style: TextStyle(
                               color: isSender ? Colors.white : Colors.black87,
                             ),
                           ),
                           Text(
                             format(message['created_at']),
                             style: TextStyle(
                               color: isSender ? Colors.white : Colors.black87,
                             ),
                           ),

                         ],
                       ),
                     ),
                   ),
                 );
               }

              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
                IconButton(
                    onPressed:pickFileAndConvertToBase64 ,
                    icon: Icon(Icons.attachment)
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
