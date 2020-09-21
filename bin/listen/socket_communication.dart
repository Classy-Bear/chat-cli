import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io_client;

class SocketCommunication {
  final whoami;

  final socket = socket_io_client.io('http://localhost:4000', <String, dynamic>{
    'transports': ['websocket'],
  });

  SocketCommunication(this.whoami) {
    final options = BaseOptions(
      baseUrl: 'http://localhost:5000',
      connectTimeout: 5000,
      receiveTimeout: 3000,
    );

    final dio = Dio(options);

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
          print('A new message from ${user.data['user']}: ${message['message']}');
          socket.emit('ack', message['uuid']);
        }
      }
    });
  }

  void createMessage(Map<String, dynamic> message) {
    socket.emit('save', message);
  }

  void closeClient() {
    socket.close();
  }
}
