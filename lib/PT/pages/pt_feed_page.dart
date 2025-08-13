// lib/presentation/menus/feed_page.dart

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_track_app/data/sources/cloudinary_service.dart';
import 'package:fit_track_app/presentation/menus/chat_page.dart';
import 'package:fit_track_app/presentation/menus/dashboard_page.dart';
import 'package:fit_track_app/presentation/menus/user_profile_page.dart';
import 'package:fit_track_app/presentation/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  // --- Sidebar ---
  double _sidebarXOffset = -250;
  bool _isDragging = false;

  // --- Frase do Dia ---
  final _phraseCtrl = TextEditingController();
  bool _editingPhrase = false;

  // --- Novo Post ---
  final _postCtrl = TextEditingController();
  Uint8List? _postImage;
  List<Map<String, String>> _students = [];
  List<String> _selectedStudents = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final snap = await FirebaseFirestore.instance.collection('users').get();
    _students =
        snap.docs.map((d) {
          final data = d.data();
          return {
            'id': d.id,
            'name':
                '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
          };
        }).toList();
    setState(() {});
  }

  Future<void> _pickPostImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      _postImage = await picked.readAsBytes();
      setState(() {});
    }
  }

  Future<void> _submitPost() async {
    final text = _postCtrl.text.trim();
    if (text.isEmpty && _postImage == null) return;

    String? imageUrl;
    if (_postImage != null) {
      imageUrl = await CloudinaryService.uploadBytes(
        _postImage!,
        folder: 'feed_posts',
      );
    }

    await FirebaseFirestore.instance.collection('posts').add({
      'authorId': FirebaseAuth.instance.currentUser!.uid,
      'text': text,
      'imageUrl': imageUrl,
      'tags': _selectedStudents,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _postCtrl.clear();
    _postImage = null;
    _selectedStudents.clear();
    setState(() {});
  }

  Future<void> _savePhrase(String id) async {
    final text = _phraseCtrl.text.trim();
    if (text.isEmpty) return;
    final ref = FirebaseFirestore.instance.collection('feedPhrase').doc(id);
    await ref.set({'text': text, 'updatedAt': FieldValue.serverTimestamp()});
    _editingPhrase = false;
    setState(() {});
  }

  Future<void> _deletePost(String id) async {
    await FirebaseFirestore.instance.collection('posts').doc(id).delete();
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6EC1E4),
        child: const Icon(Icons.chat_bubble, color: Colors.white),
        onPressed: _openChat,
      ),
      body: GestureDetector(
        // Abrir/fechar sidebar por drag
        onHorizontalDragStart: (_) => _isDragging = true,
        onHorizontalDragUpdate: (d) {
          if (_isDragging) {
            _sidebarXOffset = (_sidebarXOffset + d.delta.dx).clamp(-250, 0);
            setState(() {});
          }
        },
        onHorizontalDragEnd: (_) {
          _isDragging = false;
          _sidebarXOffset = _sidebarXOffset > -125 ? 0 : -250;
          setState(() {});
        },
        child: Stack(
          children: [
            // ====== CONTEÚDO ======
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
                  child: ListView(
                    children: [
                      // --- TopBar ---
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
                              'Feed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DashboardPage(),
                                  ),
                                ),
                            child: const CircleAvatar(
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.home, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap:
                                () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const UserProfilePage(),
                                  ),
                                ),
                            child: const CircleAvatar(
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // --- Frase do Dia ---
                      StreamBuilder<DocumentSnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('feedPhrase')
                                .doc('singleton')
                                .snapshots(),
                        builder: (ctx, snap) {
                          final doc = snap.data;
                          final data =
                              doc?.data() as Map<String, dynamic>? ?? {};
                          final text = data['text'] as String? ?? '';
                          final ts =
                              (data['updatedAt'] as Timestamp?)?.toDate();
                          final now = DateTime.now();
                          final todayMidnight = DateTime(
                            now.year,
                            now.month,
                            now.day,
                          );
                          final expired =
                              ts == null || ts.isBefore(todayMidnight);
                          final editing = _editingPhrase || expired;

                          if (!editing) {
                            // exibe frase existente
                            return Card(
                              color: Colors.blueGrey[800],
                              child: ListTile(
                                title: Text(
                                  text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    _phraseCtrl.text = text;
                                    _editingPhrase = true;
                                    setState(() {});
                                  },
                                ),
                              ),
                            );
                          } else {
                            // modo de edição
                            return Card(
                              color: Colors.blueGrey[800],
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _phraseCtrl,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Nova frase do dia',
                                        hintStyle: TextStyle(
                                          color: Colors.white54,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => _savePhrase('singleton'),
                                      child: const Text('Salvar'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // --- Form de Novo Post (com @autocomplete somente após “@x”) ---
                      Card(
                        color: Colors.blueGrey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              RawAutocomplete<String>(
                                textEditingController: _postCtrl,
                                focusNode: FocusNode(),
                                optionsBuilder: (TextEditingValue textEditing) {
                                  final text = textEditing.text;
                                  final sel = textEditing.selection.baseOffset;
                                  final prefix = text.substring(0, sel);
                                  final atIndex = prefix.lastIndexOf('@');
                                  if (atIndex == -1) return const [];
                                  final query = prefix.substring(atIndex + 1);
                                  if (query.isEmpty) return const [];
                                  return _students
                                      .map((s) => s['name']!)
                                      .where(
                                        (name) => name.toLowerCase().contains(
                                          query.toLowerCase(),
                                        ),
                                      );
                                },
                                displayStringForOption: (opt) => opt,
                                fieldViewBuilder:
                                    (
                                      context,
                                      controller,
                                      focusNode,
                                      onFieldSubmitted,
                                    ) => TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      maxLines: 3,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'O que deseja postar?',
                                        hintStyle: TextStyle(
                                          color: Colors.white54,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                optionsViewBuilder: (
                                  context,
                                  onSelected,
                                  options,
                                ) {
                                  return Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey[700],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListView(
                                        shrinkWrap: true,
                                        children:
                                            options.map((option) {
                                              return ListTile(
                                                title: Text(
                                                  option,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                onTap: () {
                                                  onSelected(option);
                                                  // substitui "@query" por "@Option "
                                                  final t = _postCtrl.text;
                                                  final sel =
                                                      _postCtrl
                                                          .selection
                                                          .baseOffset;
                                                  final pre = t.substring(
                                                    0,
                                                    sel,
                                                  );
                                                  final atIdx = pre.lastIndexOf(
                                                    '@',
                                                  );
                                                  final newText =
                                                      t.substring(
                                                        0,
                                                        atIdx + 1,
                                                      ) +
                                                      option +
                                                      ' ';
                                                  _postCtrl.text = newText;
                                                  _postCtrl.selection =
                                                      TextSelection.collapsed(
                                                        offset: newText.length,
                                                      );
                                                },
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              if (_postImage != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Image.memory(
                                    _postImage!,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),

                              Wrap(
                                spacing: 8,
                                children:
                                    _students.map((s) {
                                      final sel = _selectedStudents.contains(
                                        s['id'],
                                      );
                                      return FilterChip(
                                        label: Text(
                                          s['name']!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        selected: sel,
                                        selectedColor: Colors.teal,
                                        checkmarkColor: Colors.white,
                                        onSelected: (v) {
                                          setState(() {
                                            if (v) {
                                              _selectedStudents.add(s['id']!);
                                            } else {
                                              _selectedStudents.remove(s['id']);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),

                              ButtonBar(
                                alignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.image,
                                      color: Colors.white70,
                                    ),
                                    onPressed: _pickPostImage,
                                  ),
                                  ElevatedButton(
                                    onPressed: _submitPost,
                                    child: const Text('Postar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- Lista de Posts ---
                      StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('posts')
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                        builder: (ctx, snap) {
                          if (!snap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final docs = snap.data!.docs;
                          return Column(
                            children:
                                docs.map((d) {
                                  final data =
                                      d.data()! as Map<String, dynamic>;
                                  final txt = data['text'] as String? ?? '';
                                  final img = data['imageUrl'] as String?;
                                  final tags = List<String>.from(
                                    data['tags'] ?? [],
                                  );
                                  final ts =
                                      (data['createdAt'] as Timestamp?)
                                          ?.toDate();
                                  return Card(
                                    color: Colors.blueGrey[800],
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(8),
                                      title: Text(
                                        txt,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (img != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Image.network(
                                                img,
                                                height: 120,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          Wrap(
                                            spacing: 6,
                                            children:
                                                tags.map((id) {
                                                  final name =
                                                      _students.firstWhere(
                                                        (s) => s['id'] == id,
                                                        orElse: () => {},
                                                      )['name'] ??
                                                      '';
                                                  return Chip(
                                                    label: Text(
                                                      name,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        Colors.teal[700],
                                                  );
                                                }).toList(),
                                          ),
                                          if (ts != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                DateFormat(
                                                  'dd/MM/yyyy HH:mm',
                                                ).format(ts),
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () => _deletePost(d.id),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // overlay para fechar sidebar
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
