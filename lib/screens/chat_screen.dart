
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:intl/intl.dart';


final _firestore = FirebaseFirestore.instance;
User loggedInUser;
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController=TextEditingController();

  final _auth = FirebaseAuth.instance;


  String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
      }
    }
    catch (e) {}
  }

  void messagesStream() async {
    await for (var snapshot in _firestore.collection('messages').snapshots()) {
      for (var message in snapshot.docs) {
        print(message.data());
      }
    }
  }

  void playSound(){
    final player=AudioCache();
    player.play('notification.mp3');
  }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: null,
          actions: <Widget>[

            IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  _auth.signOut();
                  Navigator.pop(context);
                  //Implement logout functionality
                }),
          ],
          title: Text('⚡️Chat'),
          backgroundColor: Colors.lightBlueAccent,
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.dstATop),
              image: AssetImage('images/doodle.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('messages').orderBy('timesp' ,descending :true).snapshots(),
                  builder: (context,snapshot){
                    if(!snapshot.hasData){
                      return Center(
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                      final messages=snapshot.data.docs;
                      List<MessageBubble> messageBubbles=[];
                      for(var message in messages){
                        final messageText = message.data()['text'];
                        final messageSender=message.data()['sender'];
                        final timesend=message.data()['timestamp'];
                        final currentUser = loggedInUser.email;


                        final messageBubble = MessageBubble(sender: messageSender,text: messageText,isMe: currentUser==messageSender,time: timesend);

                        messageBubbles.add(messageBubble);
                      }
                      return Expanded(
                        child: ListView(
                          reverse: true,
                          padding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 20.0),
                          children: messageBubbles,
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
                          controller: messageTextController,
                          style: TextStyle(
                            color: Colors.black,
                          ),
                          onChanged: (value) {
                            messageText = value;
                            //Do something with the user input.
                          },
                          decoration: kMessageTextFieldDecoration,
                        ),
                      ),
                      FlatButton(
                        onPressed: () {
                          if(messageText!=null) {
                            playSound();
                            messageTextController.clear();
                            _firestore.collection('messages').add({
                              'sender': loggedInUser.email,
                              'text': messageText,
                              'timestamp': DateFormat.jm().format(DateTime.now()),
                              'timesp': Timestamp.now(),
                            });
                          }

                          //Implement send functionality.
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
        ),
      );
    }
  }


  class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender,this.text,this.isMe,this.time});
  final String sender;
  final String text;
  final String time;

  bool isMe;
    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: isMe? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '$sender',
              style: TextStyle(
                fontSize: 15.0,
                color: Colors.black54,
              ),
            ),
            Material(
                borderRadius: isMe? BorderRadius.only(topLeft: Radius.circular(30.0),bottomLeft: Radius.circular(30.0),bottomRight: Radius.circular(30.0)):
                    BorderRadius.only(bottomLeft: Radius.circular(30.0),bottomRight: Radius.circular(30.0),topRight: Radius.circular(30.0)),
                elevation: 5.0,
                color: isMe? Colors.blue: Colors.white,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0,horizontal: 20.0),
                  child: Text(
                    '$text',
                    style: TextStyle(
                      fontSize: 15.0,
                      color: isMe?Colors.white:Colors.black54,
                    ),
                  ),
                )
            ),
            Text(
              '$time',
            )
          ],

        ),
      );
    }
  }
