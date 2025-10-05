import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Model classes
class Sender {
  final String id;
  final String name;
  final String avatarUrl;

  Sender({required this.id, required this.name, required this.avatarUrl});
}

class Message {
  final String id;
  final String content;
  final List<String> imageUrl;
  final String senderId;
  final String conversationName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Sender sender;

  Message({
    required this.id,
    required this.content,
    required this.imageUrl,
    required this.senderId,
    required this.conversationName,
    required this.createdAt,
    required this.updatedAt,
    required this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      imageUrl: List<String>.from(json['imageUrl'] ?? []),
      senderId: json['senderId'] ?? '',
      conversationName: json['conversationName'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      sender: Sender(
        id: json['sender']?['id'] ?? '',
        name: json['sender']?['name'] ?? 'Unknown',
        avatarUrl: json['sender']?['avatarUrl'] ?? '',
      ),
    );
  }
}

class GroupWebSocketService {
  static final GroupWebSocketService _instance =
      GroupWebSocketService._internal();
  factory GroupWebSocketService() => _instance;

  GroupWebSocketService._internal();

  late WebSocketChannel _channel;

  // Stream for messages
  final RxList<Message> messagesStream = <Message>[].obs;

  void initSocket() {
    // Replace this with your WebSocket server URL
    _channel = WebSocketChannel.connect(Uri.parse('ws://192.168.11.50:5000'));

    // Listen to incoming messages
    _channel.stream.listen(
      (message) {
        handleIncomingMessage(message);
        // var controller = Get.find<GroupChatscreencontroller>();
        if (kDebugMode) {
          print("////////////hh");
        }
        // controller.scrollToBottom();
      },
      onError: (error) {
        if (kDebugMode) {
          print('WebSocket error: $error');
        }
      },
      onDone: () {
        if (kDebugMode) {
          print('WebSocket connection closed by server.');
        }
      },
    );
  }

  void handleIncomingMessage(dynamic message) {
    try {
      // Decode the incoming message
      var data = jsonDecode(message);

      // Check if the message has a 'type' field
      if (data is Map<String, dynamic> && data.containsKey('type')) {
        if (data['type'] == 'subscribed' && data['loadedMessages'] != null) {
          handleLoadedMessages(data['loadedMessages']);
        } else if (data['type'] == 'privateMessage' && data['data'] != null) {
          handleNewMessage(data['data']);
        } else if (data['type'] == 'image' && data.containsKey('message')) {
          if (kDebugMode) {
            print("Image message received: ${data['message']}");
          }
          handleImageMessage(data);
        } else {
          if (kDebugMode) {
            print("Unexpected data formatcc: $data");
          }
        }
      } else {
        // If no 'type' field, process as a standalone message (optional)
        if (data is Map<String, dynamic> && data.containsKey('id')) {
          handleNewMessage(data);
        } else {
          if (kDebugMode) {
            print("Unknown message formatmm: $data");
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error processing incoming message: $e");
      }
    }
  }

  void handleImageMessage(Map<String, dynamic> data) {
    if (kDebugMode) {
      print("Handling image message: ${data['message']}");
    }
    // var controller = Get.find<GroupChatscreencontroller>();
    if (kDebugMode) {
      print("////////////hh");
    }
    // controller.scrollToBottom();
  }

  void handleLoadedMessages(List<dynamic> loadedMessages) {
    if (loadedMessages.isNotEmpty) {
      if (kDebugMode) {
        print(loadedMessages.toString());
      }
      try {
        var messages = loadedMessages
            .map((messageJson) {
              if (messageJson != null && messageJson is Map<String, dynamic>) {
                return Message.fromJson(messageJson);
              } else {
                return Message(
                  id: '',
                  content: '',
                  imageUrl: [],
                  senderId: '',
                  conversationName: '',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  sender: Sender(id: '', name: 'Unknown', avatarUrl: ''),
                );
              }
            })
            .whereType<Message>()
            .toList();

        // Update messages stream
        messagesStream.assignAll(messages);

        // Scroll to the bottom
        // var controller = Get.find<GroupChatscreencontroller>();
        Future.delayed(Duration(milliseconds: 10), () {
          // controller.scrollToBottom();
        });

        if (kDebugMode) {
          print("Messages loaded successfully: ${messages.length} messages.");
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error parsing loaded messages: $e");
        }
      }
    } else {
      if (kDebugMode) {
        print("No messages to load.");
      }
      // var controller = Get.find<GroupChatscreencontroller>();
      // controller.isLoading.value = false;
    }
  }

  void handleNewMessage(dynamic newMessageData) {
    try {
      if (newMessageData != null && newMessageData is Map<String, dynamic>) {
        var newMessage = Message.fromJson(newMessageData);
        messagesStream.add(newMessage); // Add the new message

        // Scroll to the bottom
        // var controller = Get.find<GroupChatscreencontroller>();
        Future.delayed(Duration(milliseconds: 10), () {
          // controller.scrollToBottom();
        });

        if (kDebugMode) {
          print("New message added: ${newMessage.content}");
        }
      } else {
        if (kDebugMode) {
          print("Invalid new message data: $newMessageData");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing new message: $e");
      }
    }
  }

  // Method to join a room/channel
  void joinRoom(String channelId) {
    try {
      _channel.sink.add(jsonEncode({
        'type': 'subscribeGroup',
        'channelName': channelId,
      }));
      if (kDebugMode) {
        print("Joined room: $channelId");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error joining room: $e");
      }
    }
  }

  // Method to send a text message
  void sendTextMessage({
    required String channelId,
    required String senderId,
    required String text,
  }) {
    try {
      final data = {
        'type': 'groupMessage',
        'channelName': channelId,
        'data': {
          'content': text,
          'userId': senderId,
          'groupId': channelId,
        },
      };
      _channel.sink.add(jsonEncode(data));
      if (kDebugMode) {
        print("Text message sent: $text");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error sending text message: $e");
      }
    }
  }

  // Method to send an image message
  void sendImage({
    required String channelId,
    required String senderId,
    required String imageBase64,
  }) {
    try {
      final data = {
        'type': 'groupMessage',
        'channelName': channelId,
        'data': {
          'content': '',
          'image': imageBase64,
          'userId': senderId,
          'groupId': channelId,
        },
      };
      _channel.sink.add(jsonEncode(data));
      if (kDebugMode) {
        print("Image message sent.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error sending image message: $e");
      }
    }
  }

  // Close the WebSocket connection
  void closeConnection() {
    try {
      _channel.sink.close();
      if (kDebugMode) {
        print('WebSocket connection closed.');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error closing WebSocket connection: $e");
      }
    }
  }
}
