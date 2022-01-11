import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:real_time_chatapp/model/chat_model.dart';
import 'package:real_time_chatapp/model/message_model.dart';
import 'package:real_time_chatapp/model/user_data.dart';

import 'package:real_time_chatapp/model/user_model.dart';
import 'package:real_time_chatapp/services/storage_service.dart';
import 'package:real_time_chatapp/utilities/constant.dart';

class DatabaseService {
  Future<User> getUser(String userId) async {
    DocumentSnapshot userDoc = await usersRef.doc(userId).get();
    return User.fromDoc(userDoc);
  }

  Future<List<User>> searchUser(String currrentUserId, String name) async {
    QuerySnapshot usersSnap =
        await usersRef.where('name', isGreaterThanOrEqualTo: name).get();
    List<User> users = [];
    usersSnap.docs.forEach(
      (doc) {
        User user = User.fromDoc(doc);
        if (user.id != currrentUserId) users.add(user);
      },
    );
    return users;
  }

  Future<bool> createChat(
      BuildContext context, String name, File file, List<String> users) async {
    String imageUrl = await Provider.of<StorageService>(context, listen: false)
        .uploadChatImage(null, file);

    List<String> memberIds = [];
    Map<String, dynamic> memberInfo = {};
    Map<String, dynamic> readStatus = {};

    for (String userId in users) {
      User user = await getUser(userId);
      memberIds.add(userId);
      Map<String, dynamic> userMap = {
        'name': user.name,
        'email': user.email,
        'token': user.token,
      };
      memberInfo[userId] = userMap;
      readStatus[userId] = false;
    }

    await chatsRef.add(
      {
        'name': name,
        'imageUrl': imageUrl,
        'recentMessage': 'Chat created',
        'recentSender': '',
        'recentTimestamp': Timestamp.now(),
        'memberIds': memberIds,
        'memberInfo': memberInfo,
        'readStatus': readStatus,
      },
    );
    return true;
  }

  void sendChatMessage(Chat chat, Message message) {
    chatsRef.doc(chat.id).collection('messages').add({
      'senderId': message.senderId,
      'text': message.text,
      'imageUrl': message.imageUrl,
      'timestamp': message.timestamp,
    });
  }

  void setChatRead(BuildContext context, Chat chat, bool read) async {
    String currentUserId =
        Provider.of<UserData>(context, listen: false).currentUserId;
    chatsRef.doc(chat.id).update({
      'readStatus.$currentUserId': read,
    });
  }
}
