import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:real_time_chatapp/model/chat_model.dart';
import 'package:real_time_chatapp/model/message_model.dart';
import 'package:real_time_chatapp/model/user_data.dart';
import 'package:real_time_chatapp/services/database_service.dart';
import 'package:real_time_chatapp/services/storage_service.dart';
import 'package:real_time_chatapp/utilities/constant.dart';
import 'package:real_time_chatapp/widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  ChatScreen({
    this.chat,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isComposingMessage = false;
  DatabaseService _databaseService;

  @override
  void initState() {
    super.initState();
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _databaseService.setChatRead(context, widget.chat, true);
  }

  _buildMessageTF() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: IconButton(
              onPressed: () async {
                final pickedImage =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                File imageFile = File(pickedImage.path);

                if (imageFile != null) {
                  String imageUrl =
                      await Provider.of<StorageService>(context, listen: false)
                          .uploadMessageImage(imageFile);
                  _sentMessage(null, imageUrl);
                }
              },
              icon: Icon(
                Icons.photo,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (messageText) {
                setState(() => _isComposingMessage = messageText.isNotEmpty);
              },
              decoration:
                  const InputDecoration.collapsed(hintText: 'Send a message'),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: IconButton(
                onPressed: _isComposingMessage
                    ? () => _sentMessage(_messageController.text, null)
                    : null,
                icon: Icon(Icons.send, color: Theme.of(context).primaryColor)),
          )
        ],
      ),
    );
  }

  _sentMessage(String text, String imageUrl) async {
    if ((text != null && text.trim().isNotEmpty) || imageUrl != null) {
      if (imageUrl == null) {
        //Text Message
        _messageController.clear();
        setState(() => _isComposingMessage = false);
      }
      Message message = Message(
        senderId: Provider.of<UserData>(context, listen: false).currentUserId,
        text: text,
        imageUrl: imageUrl,
        timestamp: Timestamp.now(),
      );
      _databaseService.sendChatMessage(widget.chat, message);
    }
  }

  _buildMessageStream() {
    return StreamBuilder(
      stream: chatsRef
          .doc(widget.chat.id)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        return Expanded(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              physics: const AlwaysScrollableScrollPhysics(),
              reverse: true,
              children: _buildMessageBubbles(snapshot),
            ),
          ),
        );
      },
    );
  }

  List<MessageBubble> _buildMessageBubbles(
      AsyncSnapshot<QuerySnapshot> messages) {
    List<MessageBubble> messageBubbles = [];
    messages.data.docs.forEach((doc) {
      Message message = Message.fromDoc(doc);
      MessageBubble messageBubble =
          MessageBubble(chat: widget.chat, message: message);
      messageBubbles.add(messageBubble);
    });
    return messageBubbles;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        _databaseService.setChatRead(context, widget.chat, true);
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.chat.name),
        ),
        body: SafeArea(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMessageStream(),
            const Divider(
              height: 1.0,
            ),
            _buildMessageTF(),
          ],
        )),
      ),
    );
  }
}
