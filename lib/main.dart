import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:tts/tts.dart';
import 'dart:async';
//import 'package:speech_recognition/speech_recognition.dart';

// récupération des infos sur api.ai
var httpClient = new Client();
var _apiAIClientAccessToken = '944418f9ca794e43b52b56063f633121';
var contextsName = 'talks';
var sessionId = 'flutterchatrobot_v001';
var language = 'fr';
int lifeSpan = 4;

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Moi Aussi',
        debugShowCheckedModeBanner: false,
        theme: new ThemeData(
            primarySwatch: Colors.pink, brightness: Brightness.light),
        home: Container(
          /*decoration: new BoxDecoration(
            image: new DecorationImage(
              image: new AssetImage("images/backgr.jpg"),
              fit: BoxFit.cover,
            ),
          ),*/
          color: Colors.grey[50],
          child: new ChatMessages(),
        ));
  }
}

// La classe de la méthode Texte to Speech
class FlutterTts {
  static String text = "";

  static const MethodChannel _channel = const MethodChannel('speech_recognition');

  static void stop() {
    _channel.invokeMethod('stopSpeak');
  }

  static void setSpeechRate(double num) {
    _channel.invokeMethod('setSpeechRate', num.toString());
  }

  static void shutDown() {
    _channel.invokeMethod('shutDown');
  }

  static void setPitch(double num) {
    _channel.invokeMethod('setPitch', num.toString());
  }

  static Future<bool> get isplaying => _channel.invokeMethod('isplaying');
}

class ChatMessages extends StatefulWidget {
  @override
  _ChatMessagesState createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages>
    with TickerProviderStateMixin {
  List<ChatMessage> _messages = List<ChatMessage>();
  bool _isComposing = false;

  TextEditingController _controllerText = new TextEditingController();


  @override
  void initState() {
    super.initState();
    _initChatbot();
  }

  Icon renvIconVol(bool param) {
    Icon ic = new Icon(Icons.volume_off);
    if (param == true) {
      ic = new Icon(Icons.volume_up);
    } else {
      ic = new Icon(Icons.volume_off);
      Tts.speak("");
    }
    return ic;
  }

  bool statBout = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
          title: new Text("Moi Aussi"),
          actions: <Widget>[
            IconButton(
                icon: renvIconVol(statBout),
                //icon: Icon(Icons.volume_off),
                onPressed: () {
                  setState(() {
                    renvIconVol(false);
                    statBout = true;
                  });
                }),
          ],
        ),
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            _buildList(),
            Divider(height: 8.0, color: Theme.of(context).accentColor),
            _buildComposer()
          ],
        ));
  }

  _buildList() {
    return Flexible(
      child: ListView.builder(
          padding: EdgeInsets.all(8.0),
          reverse: true,
          itemCount: _messages.length,
          itemBuilder: (_, index) {
            return Container(child: ChatMessageListItem(_messages[index]));
          }),
    );
  }

  _buildComposer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          new IconButton(
              icon: Icon(Icons.mic,color:Colors.pink),
              onPressed: () {
                Tts.setLanguage("fr-FR");
                String text =
                    "Reessayez le micro plus tard, merci!";
                Tts.speak(text);
              }
//            _isComposing ? () => _handleSubmit(_controllerText.text) : null,
              ),
          Flexible(
            child: TextField(
              style: TextStyle(color: Colors.black),
              controller: _controllerText,
              onChanged: (value) {
                setState(() {
                  _isComposing = _controllerText.text.length > 0;
                });
              },
              onSubmitted: _handleSubmit,
              decoration: InputDecoration.collapsed(
                  hintText: "Parles-moi",
                  hintStyle: TextStyle(
                    color: Colors.black,
                  )),
            ),
          ),
          new IconButton(
            icon: Icon(
              Icons.send,
              color: Colors.pink,
            ),
            onPressed:
                _isComposing ? () => _handleSubmit(_controllerText.text) : null,
          ),
        ],
      ),
    );
  }

  _handleSubmit(String value) {
    _controllerText.clear();
    _addMessage(
      text: value,
      name: "Moi",
      initials: "Vous",
    );
    _requestChatBot(value);
    //speak();
  }

  _requestChatBot(String text) async {
    String url = Uri.encodeFull("https://api.api.ai/v1/query?v=20150910");
    var msg = text;
    var restBody =
        '{"query": ["$msg"], "contexts": { "name": "$contextsName", "lifespan": $lifeSpan }, "lang": "$language", "sessionId": "$sessionId" }';

    var response = await httpClient.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiAIClientAccessToken"
      },
      body: restBody,
    );

    var _response = JsonCodec().decode(response.body);
    var _responseMessage = _response['result']['fulfillment']['speech'];
    var rep = _responseMessage;

    _addMessage(name: "moi aussi", initials: "ma", bot: true, text: rep);
    Tts.setLanguage("fr-FR");
    Tts.speak(rep);
  }

  void _initChatbot() async {
    _addMessage(
        name: "moi aussi",
        initials: "ma",
        bot: true,
        text: "Coucou, je suis ici pour vous aider.\n"
            "Dites-moi votre préoccupation en utilisant le micro ou le champs de texte juste en bas."
            );

    Tts.setLanguage("fr-FR");
    Tts.speak(
        "Dites-moi votre préoccupation en utilisant le micro ou le champs de texte juste en bas.");
  }

  void _addMessage(
      {String name, String initials, bool bot = false, String text}) {
    var animationController = AnimationController(
      duration: new Duration(milliseconds: 700),
      vsync: this,
    );

    var message = ChatMessage(
        name: name,
        text: text,
        bot: bot,
        animationController: animationController);

    setState(() {
      _messages.insert(0, message);
    });

    animationController.forward();
  }
}

class ChatMessage {
  final String name;
  final String text;
  final bool bot;

  AnimationController animationController;

  ChatMessage(
      {this.name, this.text, this.bot = false, this.animationController});
}

/*class getMicro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    AssetImage imgAsset = AssetImage('images/micro.png');
    Image img = Image(
      image: imgAsset,
      height: 25.0,
      width: 25.0,
    );
    return Container(
      child: img,
    );
  }
}*/

class ChatMessageListItem extends StatelessWidget {
  final ChatMessage chatMessage;

  ChatMessageListItem(this.chatMessage);

  CircleAvatar renvIcon(bool va) {
    CircleAvatar iconAvat;

    if (va == true) {
      iconAvat = CircleAvatar(
        backgroundImage: AssetImage('images/logo.jpeg'),
        backgroundColor: Colors.transparent,
      );
    } else {
      iconAvat = CircleAvatar(
        backgroundImage: AssetImage('images/userIcon.png'),
        backgroundColor: Colors.transparent,
      );
    }
    return iconAvat;
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
          parent: chatMessage.animationController, curve: Curves.easeOut),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: renvIcon(chatMessage.bot),
            ),
            Flexible(
                child: Container(
                    margin: EdgeInsets.only(left: 16.0),
                    child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          chatMessage.name ?? "Moi Ausi",
                          style: TextStyle(
                              color: Colors.pink,
                              fontStyle: FontStyle.italic,
                              fontSize: 16.0),
                        ),
                        
                        Container(
                          margin: const EdgeInsets.only(top: 5.0),
                          color: Colors.pink[50],
                          child: Text(
                            chatMessage.text,
                            style: TextStyle(color: Colors.black,
                            fontSize: 24.0
                            //background: Paint()..color = Colors.pink[50]
                            ),
                          ),
                        )
                      ],
                    )))
          ],
        ),
      ),
    );
  }
}
