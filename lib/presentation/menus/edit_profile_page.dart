import 'dart:io';
import 'dart:typed_data';
import 'package:fit_track_app/presentation/menus/user_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fit_track_app/data/core/configs/theme/assets/app_images.dart';
import 'package:fit_track_app/data/sources/cloudinary_service.dart';
import 'package:fit_track_app/presentation/menus/dashboard_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String? _email;
  String? _profileImageUrl;
  File? _newImageFile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();

      setState(() {
        _nameController.text = data?['firstName'] ?? '';
        _lastnameController.text = data?['lastName'] ?? '';
        _weightController.text = data?['weight']?.toString() ?? '';
        _heightController.text = data?['height']?.toString() ?? '';
        _profileImageUrl = data?['profilePictureUrl'];
        _email = user.email;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _newImageFile = File(picked.path);
      });
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text(
                    'Escolher da Galeria',
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
                    'Tirar Foto',
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
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? newImageUrl = _profileImageUrl;

      if (_newImageFile != null) {
        final bytes =
            await _newImageFile!.readAsBytes(); // Convert File to Uint8List
        final url = await CloudinaryService.uploadBytes(bytes);
        if (url != null) {
          newImageUrl = url;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': _nameController.text,
        'lastName': _lastnameController.text,
        'weight': double.tryParse(_weightController.text),
        'height': double.tryParse(_heightController.text),
        'profilePictureUrl': newImageUrl,
      }, SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showPickerOptions,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white24,
                            backgroundImage:
                                _newImageFile != null
                                    ? FileImage(_newImageFile!)
                                    : (_profileImageUrl != null
                                        ? NetworkImage(_profileImageUrl!)
                                        : const AssetImage(
                                              'assets/images/default_avatar.png',
                                            )
                                            as ImageProvider),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildInput("Nome", _nameController),
                    _buildInput("Apelido", _lastnameController),
                    _buildInput(
                      "Peso (kg)",
                      _weightController,
                      keyboardType: TextInputType.number,
                    ),
                    _buildInput(
                      "Altura (m)",
                      _heightController,
                      keyboardType: TextInputType.number,
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      width: double.infinity,
                      child: Text(
                        _email ?? 'email@email.com',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        "Guardar Alterações",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 12),
              child: ClipOval(
                child: Material(
                  color: Colors.white.withOpacity(0.2),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserProfilePage(),
                        ),
                      );
                    },
                    splashColor: Colors.white30,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
