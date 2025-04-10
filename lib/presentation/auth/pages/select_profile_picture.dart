import 'dart:io';
import 'package:fit_track_app/presentation/auth/pages/select_goal.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fit_track_app/data/models/auth/create_user_req.dart';
import 'package:fit_track_app/data/core/configs/theme/assets/app_images.dart';
import 'package:fit_track_app/data/sources/cloudinary_service.dart';
import 'package:fit_track_app/presentation/auth/pages/setup_complete_page.dart';
import 'package:fit_track_app/presentation/auth/pages/select_height.dart';

class SelectProfilePicturePage extends StatefulWidget {
  final CreateUserReq createUserReq;

  const SelectProfilePicturePage({Key? key, required this.createUserReq})
    : super(key: key);

  @override
  State<SelectProfilePicturePage> createState() =>
      _SelectProfilePicturePageState();
}

class _SelectProfilePicturePageState extends State<SelectProfilePicturePage> {
  File? _imageFile;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _uploadAndContinue() async {
    final user = FirebaseAuth.instance.currentUser;

    if (_imageFile != null && user != null) {
      final imageUrl = await CloudinaryService.uploadImage(_imageFile!);
      if (imageUrl != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profilePictureUrl': imageUrl,
        }, SetOptions(merge: true));
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SetupCompletePage(createUserReq: widget.createUserReq),
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppImages.signupOrsigninBG),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Seta voltar atrás
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 12),
                child: ClipOval(
                  child: Material(
                    color: Colors.white.withOpacity(0.2),
                    child: InkWell(
                      splashColor: Colors.white30,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => SelectGoalPage(
                                  createUserReq: widget.createUserReq,
                                ),
                          ),
                        );
                      },
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Conteúdo principal
          Column(
            children: [
              const SizedBox(height: 100),

              const Center(
                child: Text(
                  'Adiciona uma foto de perfil',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Avatar + botão de câmara
              GestureDetector(
                onTap: _showPickerOptions,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.white24,
                      backgroundImage:
                          _imageFile != null ? FileImage(_imageFile!) : null,
                      child:
                          _imageFile == null
                              ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white70,
                              )
                              : null,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(blurRadius: 4, color: Colors.black26),
                        ],
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.camera_alt, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Botão "Continuar"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _uploadAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }
}
