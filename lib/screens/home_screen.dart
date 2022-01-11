import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_time_chatapp/model/chat_model.dart';
import 'package:real_time_chatapp/model/user_data.dart';
import 'package:real_time_chatapp/screens/chat_screen.dart';
import 'package:real_time_chatapp/screens/search_user_screen.dart';
import 'package:real_time_chatapp/services/auth_service.dart';
import 'package:real_time_chatapp/utilities/constant.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _buildChat(Chat chat, String currentUserId) {
    final bool isRead = chat.readStatus[currentUserId];
    final TextStyle readStyle = TextStyle(
      fontWeight: isRead ? FontWeight.w400 : FontWeight.bold,
    );
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.white,
        radius: 28.0,
        backgroundImage: CachedNetworkImageProvider(chat.imageUrl),
      ),
      title: Text(
        chat.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: chat.recentSender.isEmpty
          ? Text(
              'Chat Created',
              overflow: TextOverflow.ellipsis,
              style: readStyle,
            )
          : chat.recentMessage != null
              ? Text(
                  '${chat.memberInfo[chat.recentSender]['name']} : ${chat.recentMessage}',
                  overflow: TextOverflow.ellipsis,
                  style: readStyle,
                )
              : Text(
                  '${chat.memberInfo[chat.recentSender]['name']} : sent an image',
                  overflow: TextOverflow.ellipsis,
                  style: readStyle,
                ),
      trailing: Text(
        timeFormat.format(
          chat.recentTimestamp.toDate(),
        ),
        style: readStyle,
      ),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ChatScreen(
                    chat: chat,
                  ))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId =
        Provider.of<UserData>(context, listen: false).currentUserId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        leading: IconButton(
          onPressed: Provider.of<AuthService>(context, listen: false).logout,
          icon: const Icon(Icons.exit_to_app),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SearchUserScreen(),
              ),
            ),
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('memberIds', arrayContains: currentUserId)
            .orderBy('recentTimestamp', descending: true)
            .snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<dynamic, dynamic>>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView.separated(
              itemBuilder: (BuildContext context, int index) {
                Chat chat = Chat.fromDoc(snapshot.data.docs[index]);
                return _buildChat(chat, currentUserId);
              },
              separatorBuilder: (BuildContext context, int index) {
                return const Divider(
                  thickness: 1.0,
                );
              },
              itemCount: snapshot.data.docs.length);
        },
      ),
    );
  }
}
