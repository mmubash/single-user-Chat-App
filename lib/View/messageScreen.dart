import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {

  final List<Map<String, String>> messages = [
    {"text": "Hello, this is me!", "time": "7:10 AM","sender":"me"},
    {"text": "How are you?", "time": "7:11 AM","sender":"other"},
    {"text": "I'm doing well, thanks!", "time": "7:12 AM","sender":"me"},
    {"text": "What about you?", "time": "7:13 AM","sender":"other"},
    {"text": "I'm good too!", "time": "7:14 AM","sender":"me"},
    {"text": "Let's meet later.", "time": "7:15 AM","sender":"other"},
    {"text": "Sure! What time?", "time": "7:16 AM","sender":"me"},
    {"text": "How about 5 PM?", "time": "7:17 AM","sender":"other"},
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Admin"),
        backgroundColor: Color(0xff72BF78),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: messages[index]["sender"]=="me"?MainAxisAlignment.end:MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                            borderRadius: messages[index]["sender"]=="me"? BorderRadius.only(
                                topLeft:Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20)
                            ):BorderRadius.only(
                                topRight:Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20)
                            ) ,

                          color:messages[index]["sender"]=="me"? Color(0xff72BF78):Colors.grey,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "~User Name",
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                            Text(
                              messages[index]["text"]!,
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              messages[index]["time"]!,
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
            
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.grey),
                  onPressed: (){},
                ),
                IconButton(
                    onPressed:(){} ,
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
