import 'dart:convert';
import 'package:chat_app/View/roomListScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
class LoginPage extends StatefulWidget {
  LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> validateEmpty = GlobalKey<FormState>();
  bool _isHidden = true;
  late IO.Socket socket;
  bool isLoading=false;
  void login(String email, String password) async {
    try {
      var body = jsonEncode({'email': email, 'password': password});
      http.Response response = await http.post(
        Uri.parse("http://192.168.2.189:3000/api/users/login"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        print(response.body);
        var data = jsonDecode(response.body);
        print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        print(data);
        print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        String userName = data['user']['name'] ?? 'Unknown User';
        print(userName);
        String userId = (data['user']['id']?? "").toString();
        print("*******This is USERID  $userId");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', userName);
        await prefs.setString('userId', userId);
        socket = IO.io('ws://192.168.2.189:3000', IO.OptionBuilder()
            .setTransports(['websocket'])
            .build());
        socket.connect();
        socket.onConnect((_) {
          print('Connected to the server');
        });
        if(userId.isNotEmpty){
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RoomListScreen(currentUserId: userId, currentUserName: userName,))
          );
          setState(() {
            isLoading=false;
          });
        }else{
          print("User Id is empty******");
        }

      } else {
        setState(() {
          isLoading=false;
        });
        print('Failed to log in: ${response.body}');
      }
    } catch (e) {
      setState(() {
        isLoading=false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      print("Error: ${e.toString()}");
    }
  }

  void _togglePasswordView() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth =MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children:[
          Container(
            height: screenHeight*.20,
            width: screenWidth,
            decoration: BoxDecoration(
              color: Color(0xff72BF78)
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 80,left: 40),
              child: Text("Sign In",style: GoogleFonts.akatab(fontWeight: FontWeight.bold,color: Colors.white,fontSize: 40.0),),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 150),
            child: Container(
              width: screenWidth,
              height: screenHeight-150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft:Radius.circular(20),topRight: Radius.circular(20))
              ),
              child: SingleChildScrollView(
               child: Form(
                key: validateEmpty,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 70),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Welcome Back! ",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 30.0),),
                      Text("Happy to have you back. ",),
                      SizedBox(height: 40),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 30),
                      TextFormField(
                        controller: passwordController,
                        obscureText: _isHidden,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.password),
                          suffixIcon: IconButton(
                            icon: Icon(
                                _isHidden ? Icons.visibility_off : Icons.visibility),
                            onPressed: _togglePasswordView,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 60),
                      SizedBox(
                        height: 50,
                        width: 350,
                        child: ElevatedButton(
                          onPressed: () {
                            if (validateEmpty.currentState!.validate()) {
                              setState(() {
                                isLoading=true;
                              });
                              login(emailController.text, passwordController.text);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Please fill out all fields')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)
                            ),
                            backgroundColor: Color(0xff72BF78),
                            foregroundColor: Colors.white,
                          ),
                          child: Center(child:isLoading?CircularProgressIndicator(color: Colors.white,):Text('Login')),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
                      ),
            ),
          ),
    ]
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
