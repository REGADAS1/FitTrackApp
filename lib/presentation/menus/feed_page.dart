// lib/presentation/menus/feed_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  final _newPostCtrl = TextEditingController();

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
    _posts =
        snap.docs.map((d) {
          final data = d.data();
          return {
            'authorName': data['authorName'] as String? ?? 'PT',
            'content': data['content'] as String? ?? '',
            'timestamp':
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }).toList();
    setState(() {});
  }

  Future<void> _submitPost() async {
    final text = _newPostCtrl.text.trim();
    if (text.isEmpty) return;
    final user = _auth.currentUser!;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final name = "${userDoc['firstName']} ${userDoc['lastName'] ?? ''}".trim();
    await _firestore.collection('posts').add({
      'authorName': name,
      'content': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _newPostCtrl.clear();
    _loadPosts();
  }

  String get _todayPhrase {
    final now = DateTime.now();
    final idx =
        now.difference(DateTime(now.year, 1, 1)).inDays % _phrases.length;
    return _phrases[idx];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            // --- Conteúdo principal ---
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
                  padding: const EdgeInsets.only(
                    bottom: 80,
                    left: 16,
                    right: 16,
                    top: 16,
                  ),
                  child: Column(
                    children: [
                      // Top Bar
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

                      // Frase do Dia
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
                              // Aqui você poderia adicionar botões de reação, ex:
                              // IconButton(icon: Icon(Icons.thumb_up, color: Colors.white70), onPressed: () {}),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Lista de Posts
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
                                            const SizedBox(height: 8),
                                            // Exemplo de reação:
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.thumb_up,
                                                    color: Colors.white70,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    /*TODO: curtir*/
                                                  },
                                                ),
                                                Text(
                                                  '0',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
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

            // Animated Sidebar
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

            // Input Fixo para Novo Post
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: const Color(0xFF6EC1E4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newPostCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Escreva um post...",
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white24,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                        ),
                        onSubmitted: (_) => _submitPost(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _submitPost,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
