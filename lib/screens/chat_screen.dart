import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _getChatRoomId() {
    List<String> ids = [_auth.currentUser!.uid, widget.receiverId];
    ids.sort(); 
    return ids.join("_");
  }
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String message = _messageController.text.trim();
    _messageController.clear();

    String chatRoomId = _getChatRoomId();
    final timestamp = FieldValue.serverTimestamp();
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'users': [_auth.currentUser!.uid, widget.receiverId], // IDs de ambos
      'lastMessage': message,
      'lastTimestamp': timestamp,
      'lastSenderEmail': _auth.currentUser!.email,
    }, SetOptions(merge: true));


    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': _auth.currentUser!.uid,
      'senderEmail': _auth.currentUser!.email ?? '',
      'receiverId': widget.receiverId,
      'message': message,
      'timestamp': timestamp,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.receiverName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFFAF0303),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chat_rooms')
                  .doc(_getChatRoomId())
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFAF0303)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Envía un mensaje para comenzar a negociar", style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == _auth.currentUser!.uid;
                    return _buildMessageBubble(data, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }


  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    String formattedTime = "";
    if (data['timestamp'] != null) {
      DateTime time = (data['timestamp'] as Timestamp).toDate();
      formattedTime = "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4, top: 10, left: 15, right: 15),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFAF0303) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: Text(
              data['message'] ?? '',
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
            ),
          ),
          // HORA Y TICK
          Padding(
            padding: EdgeInsets.only(left: isMe ? 0 : 20, right: isMe ? 20 : 0, bottom: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formattedTime, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 14, color: Colors.blue),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DISEÑO DE LA BARRA PARA ESCRIBIR ---
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Escribe un mensaje...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(color: Color(0xFFAF0303), shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}