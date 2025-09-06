// lib/presentation/menus/exercise_list.dart
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

  final List<String> muscleGroups = const [
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercício adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteExercise({
    required String id,
    required String? imageUrl,
    required String name,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            title: const Text(
              'Eliminar exercício',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Queres mesmo eliminar “$name”? Esta ação é irreversível.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      // Se tiveres public_id do Cloudinary, aqui poderias apagá-la também.
      await FirebaseFirestore.instance.collection('exercises').doc(id).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercício eliminado.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao eliminar: $e'),
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
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs =
                    snapshot.data!.docs.where((doc) {
                      if (_selectedGroupFilter == null) return true;
                      return (doc.data()['muscleGroup'] as String?) ==
                          _selectedGroupFilter;
                    }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Sem exercícios.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final imageUrl = data['imageUrl'] as String?;
                    final name = (data['name'] as String?) ?? '';
                    final group = (data['muscleGroup'] as String?) ?? '';

                    return Card(
                      color: const Color(0xFF2C2C2C),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              imageUrl != null && imageUrl.isNotEmpty
                                  ? Image.network(
                                    imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.black26,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white38,
                                    ),
                                  ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          group,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: IconButton(
                          tooltip: 'Eliminar',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed:
                              () => _deleteExercise(
                                id: doc.id,
                                imageUrl: imageUrl,
                                name: name.isEmpty ? 'exercício' : name,
                              ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ---------- Modal de criação ----------
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
