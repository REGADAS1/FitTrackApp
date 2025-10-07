// lib/PT/pages/pt_profile_page.dart
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_track_app/PT/widgets/pt_sidebar.dart';
import 'package:fit_track_app/data/sources/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';

class PTProfilePage extends StatefulWidget {
  const PTProfilePage({super.key});

  @override
  State<PTProfilePage> createState() => _PTProfilePageState();
}

class _PTProfilePageState extends State<PTProfilePage> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _imageUrl; // URL atual no Firestore
  Uint8List? _newImage; // Imagem escolhida para upload

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      setState(() => _loading = false);
      return;
    }
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
    final data = doc.data() ?? {};

    _firstNameCtrl.text = (data['firstName'] ?? '').toString();
    _lastNameCtrl.text = (data['lastName'] ?? '').toString();
    _phoneCtrl.text = (data['phone'] ?? '').toString();
    _bioCtrl.text = (data['bio'] ?? '').toString();
    _imageUrl = (data['profilePictureUrl'] as String?);

    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final bytes = await ImagePickerWeb.getImageAsBytes();
    if (bytes != null) {
      setState(() => _newImage = bytes);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();

    if (first.isEmpty || last.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preenche nome e apelido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      String? uploadedUrl = _imageUrl;
      if (_newImage != null) {
        final url = await CloudinaryService.uploadBytes(
          _newImage!,
          folder: 'pt_profile',
        );
        if (url != null) uploadedUrl = url;
      }

      await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
        'firstName': first,
        'lastName': last,
        'phone': _phoneCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'profilePictureUrl': uploadedUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _imageUrl = uploadedUrl;
        _newImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil guardado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const PTSidebar(currentRoute: '/pt-perfil'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Perfil do PT'),
      ),
      backgroundColor: const Color(0xFF121212),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _card(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.white12,
                                    child:
                                        _newImage != null
                                            ? Image.memory(
                                              _newImage!,
                                              fit: BoxFit.cover,
                                            )
                                            : (_imageUrl != null
                                                ? Image.network(
                                                  _imageUrl!,
                                                  fit: BoxFit.cover,
                                                )
                                                : const Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Colors.white54,
                                                )),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(
                                    Icons.image,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Escolher foto',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.white70,
                                    ),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            // Form
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _textField(
                                          'Nome',
                                          _firstNameCtrl,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _textField(
                                          'Apelido',
                                          _lastNameCtrl,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _textField(
                                          'Telefone',
                                          _phoneCtrl,
                                          keyboard: TextInputType.phone,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _textField('Bio', _bioCtrl, maxLines: 4),
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: _saving ? null : _save,
                                      icon: const Icon(Icons.save),
                                      label: Text(
                                        _saving ? 'A guardar...' : 'Guardar',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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

  Widget _textField(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
