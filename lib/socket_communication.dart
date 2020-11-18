import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SocketCommunication {
  final String whoami;
  final String socketApiUrl;
  final String restApiUrl;
  Socket socket;

  SocketCommunication(this.whoami, this.restApiUrl, this.socketApiUrl) {
    final options = BaseOptions(
      baseUrl: restApiUrl,
      connectTimeout: 5000,
      receiveTimeout: 3000,
    );
    final dio = Dio(options);
    socket = io(socketApiUrl, <String, dynamic>{
      'transports': ['websocket'],
    });
    socket.on('connect', (_) async {
      final users = await dio.get('/users');
      for (final user in users.data) {
        final comunication = {'sender': user['uuid'], 'receiver': whoami};
        socket.emit('ask for message', comunication);
      }
    });
    socket.on(whoami, (messages) async {
      if (messages == null) {
        final users = await dio.get('/users');
        for (final user in users.data) {
          final comunication = {'sender': user['uuid'], 'receiver': whoami};
          socket.emit('ask for message', comunication);
        }
      } else {
        for (final message in messages) {
          final user = await dio.get('/users/${message['sender']}');
          print(
              'A new message from ${user.data['user']}: ${message['message']}');
          socket.emit('ack', message['uuid']);
        }
      }
    });
  }

  void closeClient() {
    socket.close();
  }

  void createMessage(Map<String, dynamic> message) {
    socket.emit('save', message);
  }
}
