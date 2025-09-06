// lib/presentation/menus/edit_profile_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fit_track_app/data/sources/cloudinary_service.dart';
import 'package:fit_track_app/presentation/menus/dashboard_page.dart';
import 'package:fit_track_app/presentation/menus/user_profile_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Color themeBlue = Color(0xFF6EC1E4);

  final _nameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String? _email;
  String? _profileImageUrl;
  File? _newImageFile;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = doc.data();

    setState(() {
      _nameController.text = data?['firstName'] ?? '';
      _lastnameController.text = data?['lastName'] ?? '';
      _weightController.text = (data?['weight']?.toString() ?? '');
      _heightController.text = (data?['height']?.toString() ?? '');
      _profileImageUrl = data?['profilePictureUrl'];
      _email = user.email;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() => _newImageFile = File(picked.path));
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text(
                    'Escolher da galeria',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text(
                    'Tirar foto',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      String? newImageUrl = _profileImageUrl;

      // upload para Cloudinary se foi escolhida nova imagem
      if (_newImageFile != null) {
        final bytes = await _newImageFile!.readAsBytes();
        final url = await CloudinaryService.uploadBytes(bytes);
        if (url != null) newImageUrl = url;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': _nameController.text.trim(),
        'lastName': _lastnameController.text.trim(),
        'weight': double.tryParse(_weightController.text.replaceAll(',', '.')),
        'height': double.tryParse(_heightController.text.replaceAll(',', '.')),
        'profilePictureUrl': newImageUrl,
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao guardar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo em gradiente a ocupar todo o ecrã
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF111111)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Conteúdo
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topBar(),
                    const SizedBox(height: 8),
                    _avatarCard(),
                    const SizedBox(height: 16),

                    // ----- Dados pessoais -----
                    _sectionTitle('Dados pessoais'),
                    const SizedBox(height: 8),
                    _glassCard(
                      child: Column(
                        children: [
                          _textField('Nome', _nameController),
                          const SizedBox(height: 10),
                          _textField('Apelido', _lastnameController),
                          const SizedBox(height: 10),
                          // Email (read-only) passa para "Dados pessoais"
                          _readOnlyTile(
                            icon: Icons.email_outlined,
                            text: _email ?? '',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ----- Métricas -----
                    _sectionTitle('Métricas'),
                    const SizedBox(height: 8),
                    _glassCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _textField(
                                  'Peso (kg)',
                                  _weightController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _textField(
                                  'Altura (m)',
                                  _heightController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    _saveButton(),
                  ],
                ),
              ),

              // Loader ao gravar
              if (_saving)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.35),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Blocos de UI ----------

  Widget _topBar() {
    return Row(
      children: [
        // Botão voltar
        ClipOval(
          child: Material(
            color: Colors.white.withOpacity(0.12),
            child: InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UserProfilePage()),
                );
              },
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Editar Perfil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarCard() {
    final imageProvider =
        _newImageFile != null
            ? FileImage(_newImageFile!)
            : (_profileImageUrl != null
                ? NetworkImage(_profileImageUrl!)
                : const AssetImage('assets/images/default_avatar.png')
                    as ImageProvider);

    return _glassCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: imageProvider,
                backgroundColor: Colors.white24,
              ),
              InkWell(
                onTap: _showPickerOptions,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.black,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Atualiza a tua foto e os teus dados para manter tudo em dia.',
              style: TextStyle(color: Colors.white.withOpacity(0.85)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
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

  Widget _textField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        floatingLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: themeBlue, width: 1.6),
        ),
      ),
    );
  }

  Widget _readOnlyTile({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.isEmpty ? '—' : text,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saving ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Guardar alterações',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
