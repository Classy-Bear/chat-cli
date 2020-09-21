import 'dart:io';

import '../podos/api_users.dart';
import 'socket_communication.dart';

void main(List<String> args) async {
  final userApi = UsersAPI();
  var whoami;
  var user;
  stdout.writeln('''
    ____             __     ________          __ 
   / __ \\____ ______/ /_   / ____/ /_  ____ _/ /_
  / / / / __ `/ ___/ __/  / /   / __ \\/ __ `/ __/
 / /_/ / /_/ / /  / /_   / /___/ / / / /_/ / /_  
/_____/\\__,_/_/   \\__/   \\____/_/ /_/\\__,_/\\__/                                                 
  ''');

  while (true) {
    stdout.writeln('Do you have an user? (yes or no to proceed)');
    final input = stdin.readLineSync();
    if (input.toUpperCase() == 'YES') {
      stdout.write('Enter your id then: ');
      final uuid = stdin.readLineSync();
      stdout.writeln('---------------');
      stdout.writeln('Looking for it in the database...');
      stdout.writeln('---------------');
      if (uuid.trim().isEmpty) {
        stdout.writeln('!!!!!!!!!!!!!!!');
        stdout.writeln('Please provide a proper id.');
        stdout.writeln('!!!!!!!!!!!!!!!');
        continue;
      }
      final response = await userApi.getUserbyID(uuid);
      if (response.statusCode == HttpStatus.ok) {
        final userData = response.data;
        whoami = userData['uuid'];
        user = userData['user'];
        break;
      } else {
        final userData = response.data;
        stdout.writeln('!!!!!!!!!!!!!!!');
        stdout.writeln(userData['msg']);
        stdout.writeln('!!!!!!!!!!!!!!!');
      }
    } else if (input.toUpperCase() == 'NO') {
      stdout.writeln('Let\'s create an account then');
      stdout.write('What\'s your full name (usernames are allowed)? ');
      final name = stdin.readLineSync();
      stdout.writeln('---------------');
      stdout.writeln('Inserting you in the database...');
      stdout.writeln('---------------');
      if (name.trim().isEmpty || name == null) {
        stdout.writeln('!!!!!!!!!!!!!!!');
        stdout.writeln('Please provide a proper name.');
        stdout.writeln('!!!!!!!!!!!!!!!');
        continue;
      }
      final response = await userApi.createUser(name);
      if (response.statusCode == HttpStatus.created) {
        final userCreated = response.data;
        stdout.writeln(' =========================================================');
        stdout.writeln('| User created!                                           |');
        stdout.writeln('| Here is your id: ${userCreated['uuid']}   |');
        stdout.writeln(' =========================================================');
        whoami = userCreated['uuid'];
        user = userCreated['user'];
        break;
      } else {
        final userData = response.data;
        stdout.writeln(userData['msg']);
      }
    } else {
      stdout.writeln('!!!!!!!!!!!!!!!');
      stdout.writeln('Type yes or no');
      stdout.writeln('!!!!!!!!!!!!!!!');
    }
  }

  stdout.writeln('''
    \n
    Welcome, ${user}!
    How to use this chat?
    1. Type `users` to see who\'s online.
    2. Type `msgto [ ID ] -m MESSAGE` to send a message to an user.
    3. Type `exit` to logout.
    \n
  ''');

  final socket = SocketCommunication(whoami);

  stdin.listen((ascii_list) async {
    final inputArr = [];
    // Plataform explanation here : https://en.wikipedia.org/wiki/Newline
    if (Platform.isWindows) {
      for (var i = 0; i < ascii_list.length - 2; i++) {
        inputArr.add(String.fromCharCode(ascii_list[i]));
      }
    } else {
      for (var i = 0; i < ascii_list.length - 1; i++) {
        inputArr.add(String.fromCharCode(ascii_list[i]));
      }
    }
    final input = inputArr.join();
    switch (input.split(' ')[0]) {
      case 'users':
        stdout.writeln('\nFetching users... \n');
        final response = await userApi.getAllUsers();
        if (response.statusCode == HttpStatus.ok) {
          final users = response.data;
          var user_id = 0;
          for (final user in users) {
            stdout.writeln("$user_id. ${user['user']} - ${user['uuid']}");
            user_id++;
          }
        } else {
          final userData = response.data;
          stdout.writeln(userData['msg']);
        }
        stdout.writeln();
        break;
      case 'exit':
        socket.closeClient();
        stdout.writeln('\nBye, Bye...');
        exit(0);
        break;
      case 'msgto':
        final inputSplitted = input.split(' ');
        final ids = [];
        if (inputSplitted.length < 4) {
          print('\nWrong command\n');
          return;
        }
        var arg = 'id';
        for (var i = 1; i < inputSplitted.length; i++) {
          if (inputSplitted.elementAt(i) == '-m') {
            arg = 'message';
            continue;
          }
          if (arg == 'id' && inputSplitted.elementAt(i).trim().isNotEmpty) {
            ids.add(inputSplitted.elementAt(i));
          }
          if (arg == 'message' &&
              inputSplitted.elementAt(i).trim().isNotEmpty) {
            for (final receiver in ids) {
              final messageFormatted = {
                'message': inputSplitted
                    .getRange(i, inputSplitted.length)
                    .toList()
                    .join(' '),
                'sender': whoami,
                'receiver': receiver,
              };
              socket.createMessage(messageFormatted);
            }
            break;
          }
        }
        print('\nMessage sended!\n');
        break;
      default:
        stdout.writeln('\nCommand not found\n');
        break;
    }
  });

  ProcessSignal.sigint.watch().listen((_) {
    socket.closeClient();
    stdout.writeln('\nBye, Bye...');
    exit(0);
  });
}
