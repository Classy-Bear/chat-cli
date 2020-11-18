import 'dart:io';

import 'package:dart_consume_chat/socket_communication.dart';
import 'package:dart_consume_chat/user_api.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Error: Specify the REST API URL and the Socket API URL');
    stdout.writeln('Example: dart main.dart <RST API URL> <Socket API URL>');
    exit(2);
  }
  if (args.length != 2) {
    stderr.writeln('Error: Specify the REST API URL and the Socket API URL');
    stdout.writeln('Example: dart main.dart <RST API URL> <Socket API URL>');
    stdout.writeln('Note: Don\'t specify more or less parameters');
    exit(2);
  }
  final userApi = UserAPI(args[0]);
  var whoami;
  var user;

  stdout.writeln('''
 __             _  _  _
/  |_  _ _|_   |_||_)|_)
\\__| |(_| |_   | ||  |
  ''');

  while (true) {
    stdout.writeln('Do you have an user? (yes or no to proceed)');
    final input = stdin.readLineSync();
    if (input.toUpperCase() == 'YES') {
      stdout.write('Enter your id then: ');
      final id = stdin.readLineSync();
      stdout.writeln('---------------');
      stdout.writeln('Looking for it in the database...');
      stdout.writeln('---------------');
      if (id.trim().isEmpty) {
        stdout.writeln('!!!!!!!!!!!!!!!');
        stdout.writeln('Please provide a proper id.');
        stdout.writeln('!!!!!!!!!!!!!!!');
        continue;
      }
      final response = await userApi.getUserbyID(id);
      if (response.statusCode == HttpStatus.ok) {
        final userData = response.data;
        whoami = userData['id'];
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
        stdout.writeln(
            ' =========================================================');
        stdout.writeln(
            '| User created!                                           |');
        stdout.writeln('| Here is your id: ${userCreated['id']}   |');
        stdout.writeln(
            ' =========================================================');
        whoami = userCreated['id'];
        user = userCreated['user'];
        break;
      } else {
        final userData = response.data;
        stdout.writeln(userData);
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

  final socket = SocketCommunication(whoami, args[0], args[1]);
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
          stdout.writeln('ERROR !!!!!!!!!! = ${userData['msg']}');
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
          stdout.writeln('\nWrong command\n');
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
                    .join(),
                'sender': whoami,
                'receiver': receiver,
              };
              socket.createMessage(messageFormatted);
            }
            break;
          }
        }
        stdout.writeln('\nMessage sended!\n');
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
