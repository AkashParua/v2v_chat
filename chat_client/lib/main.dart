// ignore_for_file: library_prefixes

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(
    const MaterialApp(
      title: 'RoadChat',
      home: ChatWidget(),
    ),
  );
}

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class ChatMessageWidget extends StatelessWidget {
  const ChatMessageWidget(
      {required this.username,
      required this.message,
      required this.timestamp,
      required this.vehicleId,
      required this.vehicleType,
      super.key});

  final String username;
  final String message;
  final String timestamp;
  final String vehicleId;
  final String vehicleType;


  @override
  Widget build(BuildContext context) {
    return Container(
      child: Card(
        child: ListTile(
          leading: Text("$timestamp  $vehicleId  $vehicleType"),
          title: Text(username),
          subtitle: Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}

class _ChatWidgetState extends State<ChatWidget> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  String username = "";
  String message = "";
  String vehicleId = "";
  String vehicleType = "";

  late IO.Socket socket;

  @override
  void initState() {
    initSocket();
    super.initState();
  }

  initSocket() {
    socket = IO.io('http://127.0.0.1:3000',
        IO.OptionBuilder().setTransports(['websocket']).build());
    socket.connect();

    socket.onConnect((_) {
      openUsernameDialog();
      //print('connection established');
    });

    socket.on("messages", (messages) {
      List<Widget> _chatMessages = [];
      for (var message in messages) {
        //print(message);

        _chatMessages.add(ChatMessageWidget(
            username: message['username'],
            message: message['message'],
            vehicleId: message['vehicleId'],
            vehicleType: message['vehicleType'],
            timestamp: convertTimeStamp(message['created'])));
      }
      setState(() {
        chatMessages = _chatMessages;
      });
    });

    socket.on("message", (message) {
      //print(message);
      setState(() {
        chatMessages = [
          ...chatMessages,
          ChatMessageWidget(
              username: message['username'],
              message: message['message'],
              vehicleId: message['vehicleId'],
              vehicleType: message['vehicleType'],
              timestamp: convertTimeStamp(message['created']))
        ];
      });
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            curve: Curves.easeOut, duration: const Duration(milliseconds: 50));
      });
    });
  }

  String convertTimeStamp(int timestamp) {
    var dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String convertedDateTime =
        "${dateTime.year.toString()}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}-${dateTime.minute.toString().padLeft(2, '0')}";
    return convertedDateTime;
  }

  List<Widget> chatMessages = [];

  Future openUsernameDialog() => showDialog(
     context: context,
  builder: (context) => AlertDialog(
    title: const Text("Enter your details to Join Chat"),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          onChanged: (value) => username = value,
          decoration: const InputDecoration(hintText: "Enter your name"),
        ),
        TextField(
          onChanged: (value) => vehicleId = value,
          decoration: const InputDecoration(hintText: "Enter your vehicle ID"),
        ),
        TextField(
          onChanged: (value) => vehicleType = value,
          decoration: const InputDecoration(hintText: "Enter your vehicle type"),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text("Join Chat"),
      ),
    ],
  ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Real-Time Chat",
                          style: TextStyle(
                              fontSize: 24,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text("RoadChat",
                            style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 12,
                                fontWeight: FontWeight.bold))
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: ListView(
                      controller: _scrollController, children: chatMessages),
                ),
              ),
              Padding(
                padding:const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                        child: Padding(
                      padding:
                         const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                              border:const OutlineInputBorder(),
                              hintText: 'Chat Message',
                              suffixIcon: IconButton(
                                icon:const Icon(Icons.clear),
                                onPressed: () {
                                  // Handle clear
                                  _textController.clear();
                                },
                              ))),
                    )),
                    GestureDetector(
                      onTap: () {
                        String message = _textController.text;
                        socket.emit("message",
                            {"username": username, "message": message , "vehicleId": vehicleId, "vehicleType": vehicleType});
                        _textController.clear();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12)),
                        padding:const EdgeInsets.all(16),
                        child:const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ));
  }
}

