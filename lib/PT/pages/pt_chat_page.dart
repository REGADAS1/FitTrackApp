import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:fit_track_app/data/sources/cloudinary_service.dart';

class PTChatPage extends StatefulWidget {
  const PTChatPage({super.key});

  @override
  State<PTChatPage> createState() => _PTChatPageState();
}

class _PTChatPageState extends State<PTChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> groups = [];
  Map<String, dynamic>? selectedChat;
  bool isGroup = false;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchGroups();
  }

  Future<void> _fetchUsers() async {
    final snapshot = await _firestore.collection('users').get();
    setState(() {
      users =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': '${data['firstName']} ${data['lastName'] ?? ''}',
              'photo': data['profilePictureUrl'] as String? ?? '',
            };
          }).toList();
    });
  }

  Future<void> _fetchGroups() async {
    final snapshot = await _firestore.collection('groups').get();
    setState(() {
      groups =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] as String,
              'photo': data['photo'] as String? ?? '',
              'members': List<String>.from(data['members'] as List),
            };
          }).toList();
    });
  }

  Future<void> _createOrEditGroup({bool edit = false}) async {
    final nameController = TextEditingController(
      text: edit ? selectedChat!['name'] as String : '',
    );
    List<String> selectedUserIds =
        edit ? List<String>.from(selectedChat!['members']) : [];
    Uint8List? groupImageData;
    String? initialPhoto = edit ? selectedChat!['photo'] as String? : null;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => AlertDialog(
                  backgroundColor: const Color(0xFF2C2C2C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    edit ? 'Editar Grupo' : 'Criar Grupo',
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nome + botão de selecionar foto
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Nome do grupo',
                                  labelStyle: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final picker = ImagePicker();
                                final file = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (file != null) {
                                  final bytes = await file.readAsBytes();
                                  setModalState(() {
                                    groupImageData = bytes;
                                    initialPhoto = null;
                                  });
                                }
                              },
                              icon: const Icon(Icons.image),
                              label: const Text('Foto'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Preview da imagem
                        if (groupImageData != null ||
                            (initialPhoto != null &&
                                initialPhoto!.isNotEmpty)) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child:
                                groupImageData != null
                                    ? Image.memory(
                                      groupImageData!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                    : Image.network(
                                      initialPhoto!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Seleciona os alunos:',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Chips de seleção
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              users.map((user) {
                                final isSelected = selectedUserIds.contains(
                                  user['id'],
                                );
                                return FilterChip(
                                  selected: isSelected,
                                  label: Text(
                                    user['name'],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  selectedColor: Colors.blueAccent,
                                  checkmarkColor: Colors.white,
                                  backgroundColor: Colors.grey[800],
                                  onSelected: (value) {
                                    setModalState(() {
                                      if (value) {
                                        selectedUserIds.add(user['id']);
                                      } else {
                                        selectedUserIds.remove(user['id']);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty ||
                            selectedUserIds.isEmpty)
                          return;

                        String photoUrl = initialPhoto ?? '';
                        if (groupImageData != null) {
                          final uploaded = await CloudinaryService.uploadBytes(
                            groupImageData!,
                            folder: 'group_photos',
                          );
                          if (uploaded != null) photoUrl = uploaded;
                        }

                        final groupId =
                            edit
                                ? selectedChat!['id'] as String
                                : const Uuid().v4();
                        final data = {
                          'name': nameController.text.trim(),
                          'photo': photoUrl,
                          'members': selectedUserIds,
                        };
                        if (edit) {
                          await _firestore
                              .collection('groups')
                              .doc(groupId)
                              .update(data);
                        } else {
                          await _firestore
                              .collection('groups')
                              .doc(groupId)
                              .set(data);
                        }
                        Navigator.pop(context);
                        _fetchGroups();
                        if (edit)
                          setState(() {
                            selectedChat = {
                              'id': groupId,
                              'name': data['name'],
                              'photo': data['photo'],
                              'members': data['members'],
                            };
                          });
                      },
                      child: Text(
                        edit ? 'Guardar' : 'Criar',
                        style: const TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _sendMessage(String message) async {
    if (selectedChat == null) return;
    final currentUser = _auth.currentUser!;
    final chatId =
        isGroup
            ? selectedChat!['id'] as String
            : _getChatId(currentUser.uid, selectedChat!['id'] as String);
    final collection = isGroup ? 'group_chats' : 'chats';

    await _firestore
        .collection(collection)
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': currentUser.uid,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
        });
    _messageController.clear();
  }

  String _getChatId(String a, String b) {
    final sorted = [a, b]..sort();
    return sorted.join('_');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title:
            selectedChat != null
                ? Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          (selectedChat!['photo'] as String?)?.isNotEmpty ==
                                  true
                              ? NetworkImage(selectedChat!['photo'] as String)
                              : null,
                    ),
                    const SizedBox(width: 10),
                    Text(selectedChat!['name'] as String),
                    const Spacer(),
                    if (isGroup)
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () => _createOrEditGroup(edit: true),
                      ),
                  ],
                )
                : const Text('Chat'),
      ),
      body: Row(
        children: [
          Container(
            width: 280,
            color: Colors.grey[900],
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.group_add, color: Colors.white),
                  title: const Text(
                    'Criar Grupo',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => _createOrEditGroup(edit: false),
                ),
                const Divider(color: Colors.white24),
                Expanded(
                  child: ListView(
                    children: [
                      ...users.map(
                        (user) => ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                (user['photo'] as String?)?.isNotEmpty == true
                                    ? NetworkImage(user['photo'] as String)
                                    : null,
                          ),
                          title: Text(
                            user['name'] as String,
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap:
                              () => setState(() {
                                selectedChat = user;
                                isGroup = false;
                              }),
                        ),
                      ),
                      const Divider(color: Colors.white24),
                      ...groups.map(
                        (group) => ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                (group['photo'] as String?)?.isNotEmpty == true
                                    ? NetworkImage(group['photo'] as String)
                                    : null,
                          ),
                          title: Text(
                            group['name'] as String,
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap:
                              () => setState(() {
                                selectedChat = group;
                                isGroup = true;
                              }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.white24),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child:
                      selectedChat == null
                          ? const Center(child: Text('Seleciona um chat'))
                          : StreamBuilder<QuerySnapshot>(
                            stream:
                                _firestore
                                    .collection(
                                      isGroup ? 'group_chats' : 'chats',
                                    )
                                    .doc(
                                      isGroup
                                          ? selectedChat!['id'] as String
                                          : _getChatId(
                                            currentUser.uid,
                                            selectedChat!['id'] as String,
                                          ),
                                    )
                                    .collection('messages')
                                    .orderBy('timestamp')
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final messages = snapshot.data!.docs;
                              return ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final data =
                                      messages[index].data()
                                          as Map<String, dynamic>;
                                  final isMe =
                                      data['senderId'] == currentUser.uid;
                                  return Align(
                                    alignment:
                                        isMe
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isMe
                                                ? Colors.blue
                                                : Colors.grey[800],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        data['message'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                ),
                if (selectedChat != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Mensagem...',
                              hintStyle: TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.blueAccent,
                          ),
                          onPressed:
                              () => _sendMessage(_messageController.text),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatUser {
  final String id;
  final String name;
  final String photo;

  ChatUser({required this.id, required this.name, required this.photo});
}

class ChatGroup {
  final String id;
  final String name;
  final String photo;
  final List<String> members;

  ChatGroup({
    required this.id,
    required this.name,
    required this.photo,
    required this.members,
  });
}
