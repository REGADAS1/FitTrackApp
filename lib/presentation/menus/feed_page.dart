// lib/presentation/menus/feed_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_track_app/presentation/menus/chat_page.dart';
import 'package:fit_track_app/presentation/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _posts = [];
  double _sidebarXOffset = -250;
  bool _dragging = false;

  static const _phrases = [
    "O sucesso é a soma de pequenos esforços repetidos dia após dia.",
    "Não pare quando estiver cansado; pare quando tiver terminado.",
    "A dor que você sente hoje será sua força amanhã.",
    "Sem luta, não há progresso.",
    "Seu único limite é você mesmo.",
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final snap =
        await _firestore
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .get();
    setState(() {
      _posts =
          snap.docs.map((d) {
            final data = d.data();
            return {
              'authorName': data['authorName'] as String,
              'authorPhoto': data['authorPhoto'] as String? ?? '',
              'content': data['content'] as String,
              'timestamp': (data['timestamp'] as Timestamp).toDate(),
            };
          }).toList();
    });
  }

  Future<void> _createPost() async {
    final ctrl = TextEditingController();
    final me = _auth.currentUser!;
    final userDoc = await _firestore.collection('users').doc(me.uid).get();
    final userData = userDoc.data()!;
    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            title: const Text(
              "Novo Post",
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: ctrl,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Escreva algo...",
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Cancelar",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (ctrl.text.trim().isEmpty) return;
                  await _firestore.collection('posts').add({
                    'authorName':
                        "${userData['firstName']} ${userData['lastName'] ?? ''}",
                    'authorPhoto': userData['profilePictureUrl'] ?? '',
                    'content': ctrl.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(ctx);
                  _loadPosts();
                },
                child: const Text(
                  "Publicar",
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
    );
  }

  String get _todayPhrase {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final idx = dayOfYear % _phrases.length;
    return _phrases[idx];
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // botão flutuante de chat
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6EC1E4),
        child: const Icon(Icons.chat_bubble, color: Colors.white),
        onPressed: _openChat,
      ),
      // botão flutuante de criar post
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.blueAccent,
                child: const Icon(Icons.create, color: Colors.white),
                onPressed: _createPost,
              ),
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragStart: (_) => _dragging = true,
        onHorizontalDragUpdate: (d) {
          if (_dragging) {
            setState(() {
              _sidebarXOffset = (_sidebarXOffset + d.delta.dx).clamp(-250, 0);
            });
          }
        },
        onHorizontalDragEnd: (_) {
          _dragging = false;
          setState(() {
            _sidebarXOffset = _sidebarXOffset > -125 ? 0 : -250;
          });
        },
        child: Stack(
          children: [
            // Fundo gradiente
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1E1E), Color(0xFF111111)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // TopBar
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed:
                                () => setState(() => _sidebarXOffset = 0),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "Feed do PT",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Frase do dia
                      Card(
                        color: const Color(0xFF2C2C2C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb, color: Colors.amber),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _todayPhrase,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Lista de posts
                      Expanded(
                        child:
                            _posts.isEmpty
                                ? const Center(
                                  child: Text(
                                    "Nenhum post ainda.",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: _posts.length,
                                  itemBuilder: (ctx, i) {
                                    final p = _posts[i];
                                    return Card(
                                      color: const Color(0xFF2C2C2C),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor:
                                                      Colors.white24,
                                                  backgroundImage:
                                                      p['authorPhoto']
                                                              .isNotEmpty
                                                          ? NetworkImage(
                                                            p['authorPhoto'],
                                                          )
                                                          : null,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    p['authorName'],
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  DateFormat(
                                                    'dd/MM HH:mm',
                                                  ).format(p['timestamp']),
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              p['content'],
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Overlay para fechar sidebar
            if (_sidebarXOffset == 0)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _sidebarXOffset = -250),
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),

            // Sidebar animada
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
    );
  }
}
