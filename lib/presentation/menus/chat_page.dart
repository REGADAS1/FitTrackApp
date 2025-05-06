// lib/presentation/chat/chat_page.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:fit_track_app/data/sources/cloudinary_service.dart';
import 'package:fit_track_app/presentation/widgets/sidebar.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _msgCtrl = TextEditingController();

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> groups = [];
  Map<String, dynamic>? selectedChat;
  bool isGroup = false;

  // estado da sidebar principal
  double _sidebarXOffset = -250;
  bool _isDraggingSidebar = false;

  // lookup para nome/foto
  final Map<String, Map<String, String>> _userLookup = {};

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final uSnap = await _firestore.collection('users').get();
    final gSnap = await _firestore.collection('groups').get();

    users =
        uSnap.docs.map((d) {
          final data = d.data();
          final id = d.id;
          final name = '${data['firstName']} ${data['lastName'] ?? ''}';
          final photo = data['profilePictureUrl'] ?? '';
          _userLookup[id] = {'name': name, 'photo': photo};
          return {'id': id, 'name': name, 'photo': photo};
        }).toList();

    groups =
        gSnap.docs.map((d) {
          final data = d.data();
          return {
            'id': d.id,
            'name': data['name'] as String,
            'photo': data['photo'] as String? ?? '',
            'members': List<String>.from(data['members'] as List),
          };
        }).toList();

    setState(() {});
  }

  Future<void> _createGroup() async {
    final nameCtrl = TextEditingController();
    List<String> selIds = [];
    Uint8List? imgData;

    await showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setM) {
              return AlertDialog(
                backgroundColor: const Color(0xFF2C2C2C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Novo Grupo',
                  style: TextStyle(color: Colors.white),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameCtrl,
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
                              final p = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                              );
                              if (p != null) {
                                final b = await p.readAsBytes();
                                setM(() => imgData = b);
                              }
                            },
                            icon: const Icon(Icons.image),
                            label: const Text('Foto'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (imgData != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.memory(
                            imgData!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Seleciona membros:',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            users.map((u) {
                              final sel = selIds.contains(u['id']);
                              return FilterChip(
                                selected: sel,
                                label: Text(
                                  u['name'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.grey[800],
                                selectedColor: Colors.blueAccent,
                                checkmarkColor: Colors.white,
                                onSelected:
                                    (v) => setM(() {
                                      v
                                          ? selIds.add(u['id'])
                                          : selIds.remove(u['id']);
                                    }),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty || selIds.isEmpty)
                        return;
                      String photoUrl = '';
                      if (imgData != null) {
                        final up = await CloudinaryService.uploadBytes(
                          imgData!,
                          folder: 'group_photos',
                        );
                        if (up != null) photoUrl = up;
                      }
                      final id = const Uuid().v4();
                      await _firestore.collection('groups').doc(id).set({
                        'name': nameCtrl.text.trim(),
                        'photo': photoUrl,
                        'members': selIds,
                      });
                      Navigator.pop(ctx);
                      _loadContacts();
                    },
                    child: const Text(
                      'Criar',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (selectedChat == null || text.trim().isEmpty) return;
    final me = _auth.currentUser!;
    final chatId =
        isGroup
            ? selectedChat!['id'] as String
            : _oneToOneId(me.uid, selectedChat!['id'] as String);
    final col = isGroup ? 'group_chats' : 'chats';
    await _firestore.collection(col).doc(chatId).collection('messages').add({
      'senderId': me.uid,
      'message': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'delivered': FieldValue.serverTimestamp(),
      'seenBy': <String>[],
    });
    _msgCtrl.clear();
  }

  String _oneToOneId(String a, String b) {
    final l = [a, b]..sort();
    return l.join('_');
  }

  @override
  Widget build(BuildContext context) {
    final me = _auth.currentUser!;
    final otherId =
        (selectedChat == null || isGroup) ? '' : selectedChat!['id'] as String;

    return Scaffold(
      key: _scaffoldKey, // <— Adicionado para permitir openEndDrawer()
      // nenhum drawer: sidebar é manual!
      body: GestureDetector(
        onHorizontalDragStart: (_) => _isDraggingSidebar = true,
        onHorizontalDragUpdate: (details) {
          if (_isDraggingSidebar) {
            setState(() {
              _sidebarXOffset += details.delta.dx;
              _sidebarXOffset = _sidebarXOffset.clamp(-250, 0);
            });
          }
        },
        onHorizontalDragEnd: (_) {
          _isDraggingSidebar = false;
          setState(() {
            _sidebarXOffset = _sidebarXOffset > -125 ? 0 : -250;
          });
        },
        child: Stack(
          children: [
            // --- MAIN CHAT UI ---
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2C2C2C),
                      border: Border(bottom: BorderSide(color: Colors.white12)),
                    ),
                    child: Row(
                      children: [
                        // abre sidebar manual
                        GestureDetector(
                          onTap: () => setState(() => _sidebarXOffset = 0),
                          child: const Icon(Icons.menu, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        // este botão agora abre o endDrawer
                        IconButton(
                          icon: const Icon(Icons.chat, color: Colors.white),
                          onPressed:
                              () => _scaffoldKey.currentState?.openEndDrawer(),
                        ),
                        const SizedBox(width: 12),
                        if (selectedChat != null) ...[
                          CircleAvatar(
                            backgroundImage:
                                (selectedChat!['photo'] as String).isNotEmpty
                                    ? NetworkImage(selectedChat!['photo'])
                                    : null,
                            backgroundColor: Colors.white24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedChat!['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else
                          const Text(
                            'Selecione uma conversa',
                            style: TextStyle(color: Colors.white70),
                          ),
                      ],
                    ),
                  ),

                  // Messages
                  Expanded(
                    child:
                        selectedChat == null
                            ? const Center(
                              child: Text(
                                'Nenhuma conversa aberta',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                            : StreamBuilder<QuerySnapshot>(
                              stream:
                                  _firestore
                                      .collection(
                                        isGroup ? 'group_chats' : 'chats',
                                      )
                                      .doc(
                                        isGroup
                                            ? selectedChat!['id']
                                            : _oneToOneId(me.uid, otherId),
                                      )
                                      .collection('messages')
                                      .orderBy('timestamp')
                                      .snapshots(),
                              builder: (ctx, snap) {
                                if (!snap.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final docs = snap.data!.docs;
                                // marca visto...
                                for (var d in docs) {
                                  final dat = d.data()! as Map<String, dynamic>;
                                  final seen = List<String>.from(
                                    dat['seenBy'] ?? [],
                                  );
                                  if (!seen.contains(me.uid) &&
                                      dat['senderId'] != me.uid) {
                                    _firestore
                                        .collection(
                                          isGroup ? 'group_chats' : 'chats',
                                        )
                                        .doc(
                                          isGroup
                                              ? selectedChat!['id']
                                              : _oneToOneId(me.uid, otherId),
                                        )
                                        .collection('messages')
                                        .doc(d.id)
                                        .update({
                                          'seenBy': FieldValue.arrayUnion([
                                            me.uid,
                                          ]),
                                        });
                                  }
                                }
                                return ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: docs.length,
                                  itemBuilder: (ctx, i) {
                                    final dat =
                                        docs[i].data()! as Map<String, dynamic>;
                                    final isMe = dat['senderId'] == me.uid;
                                    final seenBy = List<String>.from(
                                      dat['seenBy'] ?? [],
                                    );
                                    final other = otherId;
                                    Widget statusIcon = const SizedBox();
                                    if (isMe) {
                                      final seen = seenBy.contains(
                                        isGroup ? me.uid : other,
                                      );
                                      statusIcon = Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(
                                          seen
                                              ? Icons.done_all_rounded
                                              : Icons.done_rounded,
                                          size: 16,
                                          color:
                                              seen
                                                  ? Colors.blueAccent
                                                  : Colors.white54,
                                        ),
                                      );
                                    }
                                    final sender = _userLookup[dat['senderId']];
                                    final senderName = sender?['name'] ?? '';
                                    final senderPhoto = sender?['photo'] ?? '';

                                    return Column(
                                      crossAxisAlignment:
                                          isMe
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                      children: [
                                        Align(
                                          alignment:
                                              isMe
                                                  ? Alignment.centerRight
                                                  : Alignment.centerLeft,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            constraints: BoxConstraints(
                                              maxWidth:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.75,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isMe
                                                      ? const Color(0xFF6EC1E4)
                                                      : const Color(0xFF2A2A2A),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    dat['message'],
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                if (isMe) statusIcon,
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (!isMe) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircleAvatar(
                                                radius: 10,
                                                backgroundImage:
                                                    senderPhoto.isNotEmpty
                                                        ? NetworkImage(
                                                          senderPhoto,
                                                        )
                                                        : null,
                                                backgroundColor: Colors.white24,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                senderName,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                  ),

                  // Input
                  if (selectedChat != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: const Color(0xFF1A1A1A),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _msgCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Mensagem...',
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                ),
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.blueAccent,
                            ),
                            onPressed: () => _sendMessage(_msgCtrl.text),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // overlay para fechar sidebar principal
            if (_sidebarXOffset == 0)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _sidebarXOffset = -250),
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),

            // Sidebar principal manual
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: _sidebarXOffset,
              top: 0,
              bottom: 0,
              child: Sidebar(
                width: 250,
                onClose: () => setState(() => _sidebarXOffset = -250),
              ),
            ),
          ],
        ),
      ),

      // endDrawer para lista de conversas nativa
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Conversas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.group_add, color: Colors.white),
                title: const Text(
                  'Novo Grupo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _createGroup();
                },
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView(
                  children: [
                    ...users.map(
                      (u) => ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              u['photo'].isNotEmpty
                                  ? NetworkImage(u['photo'])
                                  : null,
                          backgroundColor: Colors.white24,
                        ),
                        title: Text(
                          u['name'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          setState(() {
                            selectedChat = u;
                            isGroup = false;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const Divider(color: Colors.white24),
                    ...groups.map(
                      (g) => ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              g['photo'].isNotEmpty
                                  ? NetworkImage(g['photo'])
                                  : null,
                          backgroundColor: Colors.white24,
                        ),
                        title: Text(
                          g['name'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          setState(() {
                            selectedChat = g;
                            isGroup = true;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
