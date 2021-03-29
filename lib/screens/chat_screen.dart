import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {

  static String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String messageText;

  @override
  void initState() {

    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    }
    catch(e){
      print(e);
    }
  }

  // void getMessages() async {
  //    final messages = await _firestore.collection('messages').getDocuments();
  //    for(var messages in messages.documents) {
  //      print(messages.data);
  //    }
  // }

  void messagesStream() async {
    await for(var snapshot in _firestore.collection('messages').snapshots()){
      for(var messages in snapshot.documents) {
            print(messages.data);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('messages').snapshots(),
              builder: (context, snapshot){
                if(!snapshot.hasData){
                  return Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.lightBlueAccent,
                    ),
                  );
                }
                  final messages = snapshot.data.documents.reversed;
                  List<MessageBubble> messageWidgets = [];
                  for(var message in messages){
                    final messageText =  message.data['text'];
                    final messageSender = message.data['sender'];

                    final currentUser = loggedInUser.email;

                    final messageWidget = MessageBubble(
                        sender: messageSender,
                        text: messageText,
                        isMe: currentUser == messageSender);
                    messageWidgets.add(messageWidget);
                  }
                  return Expanded(
                    child: ListView(
                      reverse: true,
                      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),  
                      children: messageWidgets,
                    ),
                  );

              },
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                       messageController.clear();
                       if(messageText != null) {  //*tonu* used if to prevent null entry..
                         _firestore.collection('messages').add({
                           'text': messageText,
                           'sender': loggedInUser.email
                         });
                       }
                       messageText = null; // *tonu* to prevent same message over and over
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {

  MessageBubble({this.sender, this.text, this.isMe});

  final String sender ;
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(sender, style: TextStyle(fontSize: 12, color: Colors.black54)),
          Material(
          borderRadius: BorderRadius.circular(30.0),
          elevation: 5,
          color: isMe ? Colors.lightBlueAccent : Colors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Text(text,
              style: TextStyle(fontSize: 15, color: isMe ? Colors.white : Colors.black54),),
          ),
        ),
        ]
      ),
    );
  }
}
