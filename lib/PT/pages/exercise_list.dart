import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fit_track_app/PT/widgets/pt_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';

import 'pt_dashboard.dart';
import 'package:fit_track_app/data/sources/cloudinary_service.dart';
import 'package:fit_track_app/data/core/configs/theme/assets/app_images.dart';

class ExerciseListPage extends StatefulWidget {
  const ExerciseListPage({super.key});

  @override
  State<ExerciseListPage> createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPage> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedGroup;
  Uint8List? _imageData;
  String? _selectedGroupFilter;
  bool _showForm = false;

  final List<String> muscleGroups = [
    'Pernas',
    'Peito',
    'Bíceps',
    'Tríceps',
    'Ombros',
    'Costas',
    'Abdómen',
  ];

  Future<void> _pickImage() async {
    final picked = await ImagePickerWeb.getImageAsBytes();
    if (picked != null) {
      setState(() => _imageData = picked);
    }
  }

  Future<void> _saveExercise() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _imageData == null || _selectedGroup == null) return;

    try {
      final imageUrl = await CloudinaryService.uploadBytes(_imageData!);
      if (imageUrl == null) throw 'Erro ao fazer upload da imagem.';

      await FirebaseFirestore.instance.collection('exercises').add({
        'name': name,
        'muscleGroup': _selectedGroup,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _nameController.clear();
      _selectedGroup = null;
      setState(() {
        _imageData = null;
        _showForm = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercício adicionado com sucesso!'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('exercises')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Lista de Exercícios'),
        actions: [
          DropdownButton<String>(
            value: _selectedGroupFilter,
            dropdownColor: const Color(0xFF2C2C2C),
            hint: const Text('Filtrar', style: TextStyle(color: Colors.white)),
            underline: const SizedBox(),
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onChanged: (value) {
              setState(() => _selectedGroupFilter = value);
            },
            items:
                [null, ...muscleGroups].map((group) {
                  return DropdownMenuItem(
                    value: group,
                    child: Text(group ?? 'Todos'),
                  );
                }).toList(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: const PTSidebar(currentRoute: '/exercicios'),
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final exercises =
                    snapshot.data!.docs.where((doc) {
                      if (_selectedGroupFilter == null) return true;
                      return doc['muscleGroup'] == _selectedGroupFilter;
                    }).toList();

                return ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final data = exercises[index].data();
                    return Card(
                      color: const Color(0xFF2C2C2C),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['imageUrl'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          data['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          data['muscleGroup'] ?? '',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_showForm)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showForm = false;
                    _nameController.clear();
                    _imageData = null;
                    _selectedGroup = null;
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      width: 400,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Adicionar Exercício',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Nome do Exercício',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedGroup,
                            dropdownColor: const Color(0xFF2C2C2C),
                            hint: const Text('Selecionar Grupo Muscular'),
                            onChanged:
                                (value) =>
                                    setState(() => _selectedGroup = value),
                            items:
                                muscleGroups.map((group) {
                                  return DropdownMenuItem(
                                    value: group,
                                    child: Text(
                                      group,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            iconEnabledColor: Colors.white,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Selecionar Imagem'),
                          ),
                          if (_imageData != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Image.memory(
                                _imageData!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _saveExercise,
                            child: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () => setState(() => _showForm = true),
        child: const Icon(Icons.add),
      ),
    );
  }
}
