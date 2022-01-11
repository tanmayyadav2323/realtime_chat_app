import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_time_chatapp/model/user_data.dart';
import 'package:real_time_chatapp/model/user_model.dart';
import 'package:real_time_chatapp/screens/create_chat_screen.dart';
import 'package:real_time_chatapp/services/database_service.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({Key key}) : super(key: key);

  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  List<User> _selectedUsers = [];

  _clearSearch() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _searchController.clear());
    setState(() => _users = []);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Provider.of<UserData>(context, listen: false).currentUserId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search User'),
        actions: [
          IconButton(
            onPressed: () {
              if (_selectedUsers.length > 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateChatScreen(
                      selectedUser: _selectedUsers,
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
              border: InputBorder.none,
              hintText: 'Search',
              prefixIcon: const Icon(
                Icons.search,
                size: 30.0,
              ),
              suffixIcon: IconButton(
                onPressed: _clearSearch,
                icon: const Icon(Icons.clear),
              ),
            ),
            onSubmitted: (input) async {
              if (input.trim().isNotEmpty) {
                List<User> users =
                    await Provider.of<DatabaseService>(context, listen: false)
                        .searchUser(currentUserId, input);
                _selectedUsers.forEach((user) => users.remove(user));
                setState(() => _users = users);
              }
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedUsers.length + _users.length,
              itemBuilder: (BuildContext context, index) {
                if (index < _selectedUsers.length) {
                  User selectedUser = _selectedUsers[index];
                  return ListTile(
                    title: Text(selectedUser.name),
                    trailing: const Icon(Icons.check_circle),
                    onTap: () {
                      _selectedUsers.remove(selectedUser);
                      _users.insert(0, selectedUser);
                      setState(() {});
                    },
                  );
                } else {
                  int userIndex = index - _selectedUsers.length;
                  User user = _users[userIndex];
                  return ListTile(
                    title: Text(user.name),
                    trailing: const Icon(Icons.check_circle_outlined),
                    onTap: () {
                      _selectedUsers.add(user);
                      _users.remove(user);
                      setState(() {});
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
