// lib/PT/pages/pt_feed_page.dart

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_track_app/data/sources/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:fit_track_app/PT/widgets/pt_sidebar.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 👉 Usa a PTSidebar como Drawer
      drawer: const PTSidebar(currentRoute: '/feed'),
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('Feed'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        // garante contraste no tema escuro
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
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
                // --- Frase do Dia ---
                StreamBuilder<DocumentSnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('feedPhrase')
                          .doc('singleton')
                          .snapshots(),
                  builder: (ctx, snap) {
                    final doc = snap.data;
                    final data = doc?.data() as Map<String, dynamic>? ?? {};
                    final text = data['text'] as String? ?? '';
                    final ts = (data['updatedAt'] as Timestamp?)?.toDate();
                    final now = DateTime.now();
                    final todayMidnight = DateTime(
                      now.year,
                      now.month,
                      now.day,
                    );
                    final expired = ts == null || ts.isBefore(todayMidnight);
                    final editing = _editingPhrase || expired;

                    if (!editing) {
                      // exibe frase existente
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          title: Text(
                            text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white70),
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
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _phraseCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Nova frase do dia',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => _savePhrase('singleton'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6EC1E4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
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

                // --- Form de Novo Post ---
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _postCtrl,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'O que deseja postar?',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                        ),
                        if (_postImage != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _postImage!,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6EC1E4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
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
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;
                    return Column(
                      children:
                          docs.map((d) {
                            final data = d.data()! as Map<String, dynamic>;
                            final txt = data['text'] as String? ?? '';
                            final img = data['imageUrl'] as String?;
                            final ts =
                                (data['createdAt'] as Timestamp?)?.toDate();

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      txt,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (img != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            img,
                                            height: 160,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    Row(
                                      children: [
                                        if (ts != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
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
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () => _deletePost(d.id),
                                        ),
                                      ],
                                    ),
                                  ],
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
    );
  }
}
