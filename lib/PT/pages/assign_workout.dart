// lib/presentation/menus/assign_workout_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignWorkoutPage extends StatefulWidget {
  final String userId;
  final String userName;

  const AssignWorkoutPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AssignWorkoutPage> createState() => _AssignWorkoutPageState();
}

class _AssignWorkoutPageState extends State<AssignWorkoutPage> {
  List<Map<String, dynamic>> allExercises = [];
  List<Map<String, dynamic>> selectedExercises = [];
  final List<String> muscleGroups = [
    'Todos',
    'Pernas',
    'Peito',
    'Bíceps',
    'Tríceps',
    'Ombros',
    'Costas',
    'Abdómen',
  ];
  String selectedGroupFilter = 'Todos';
  List<String> selectedMuscleGroups = [];
  final TextEditingController _planNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('exercises').get();
    setState(() {
      allExercises =
          snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'name': doc['name'],
              'muscleGroup': doc['muscleGroup'],
            };
          }).toList();
    });
  }

  Future<void> _assignPlanWithDialog() async {
    if (selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione ao menos um exercício ao plano'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx2, setModal) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text(
                  'Guardar Plano',
                  style: TextStyle(color: Colors.white),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _planNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Nome do Plano',
                          hintStyle: TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Grupo(s) Muscular(es)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            muscleGroups.where((g) => g != 'Todos').map((
                              group,
                            ) {
                              final sel = selectedMuscleGroups.contains(group);
                              return FilterChip(
                                label: Text(
                                  group,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                selected: sel,
                                selectedColor: Colors.green,
                                backgroundColor: Colors.grey[800],
                                checkmarkColor: Colors.white,
                                onSelected: (v) {
                                  setModal(() {
                                    if (sel) {
                                      selectedMuscleGroups.remove(group);
                                    } else {
                                      selectedMuscleGroups.add(group);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white10,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final name = _planNameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Insira o nome do plano'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (selectedMuscleGroups.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Selecione ao menos um grupo muscular',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Monta a lista de exercícios para salvar
                      final planExercises =
                          selectedExercises.map((ex) {
                            if (ex['usePyramid'] as bool) {
                              // Pirâmide
                              final pyramid =
                                  (ex['pyramid'] as List<Map<String, dynamic>>)
                                      .map(
                                        (p) => {
                                          'weight': p['weight'],
                                          'reps': p['reps'],
                                        },
                                      )
                                      .toList();
                              return {
                                'name': ex['name'],
                                'muscleGroup': ex['muscleGroup'],
                                'pyramid': pyramid,
                              };
                            } else {
                              // Séries x reps
                              return {
                                'name': ex['name'],
                                'muscleGroup': ex['muscleGroup'],
                                'sets': ex['sets'],
                                'reps': ex['reps'],
                              };
                            }
                          }).toList();

                      // Salva no Firestore
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userId)
                          .set({
                            'plans': {
                              name: {
                                'muscleGroups': selectedMuscleGroups,
                                'exercises': planExercises,
                                'assignedAt': FieldValue.serverTimestamp(),
                              },
                            },
                          }, SetOptions(merge: true));

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Plano atribuído com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _configurePyramid(
    BuildContext context,
    Map<String, dynamic> ex,
  ) async {
    // Cria uma cópia profunda para editar sem sobrescrever antes de confirmar
    final pyramid =
        ex['pyramid'] != null
            ? (ex['pyramid'] as List)
                .map((m) => Map<String, dynamic>.from(m))
                .toList()
            : <Map<String, dynamic>>[];

    await showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx2, setModal) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text(
                  'Configurar Pirâmide',
                  style: TextStyle(color: Colors.white),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pyramid.length + 1,
                    itemBuilder: (c, idx) {
                      if (idx == pyramid.length) {
                        return TextButton.icon(
                          icon: const Icon(Icons.add, color: Colors.white70),
                          label: const Text(
                            'Adicionar Série',
                            style: TextStyle(color: Colors.white70),
                          ),
                          onPressed:
                              () => setModal(() {
                                pyramid.add({'weight': 0, 'reps': 0});
                              }),
                        );
                      }
                      final row = pyramid[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            // Carga
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'Kg',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  filled: true,
                                  fillColor: Color(0xFF2C2C2C),
                                ),
                                style: const TextStyle(color: Colors.white),
                                onChanged:
                                    (v) => row['weight'] = int.tryParse(v) ?? 0,
                                controller: TextEditingController(
                                  text: row['weight']?.toString(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Reps
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'Reps',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  filled: true,
                                  fillColor: Color(0xFF2C2C2C),
                                ),
                                style: const TextStyle(color: Colors.white),
                                onChanged:
                                    (v) => row['reps'] = int.tryParse(v) ?? 0,
                                controller: TextEditingController(
                                  text: row['reps']?.toString(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed:
                                  () => setModal(() {
                                    pyramid.removeAt(idx);
                                  }),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Ao confirmar, grava a pirâmide de volta no exercício
                      setState(() {
                        ex['usePyramid'] = true;
                        ex['pyramid'] = pyramid;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available =
        allExercises
            .where((e) => !selectedExercises.any((sel) => sel['id'] == e['id']))
            .where(
              (e) =>
                  selectedGroupFilter == 'Todos' ||
                  e['muscleGroup'] == selectedGroupFilter,
            )
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Plano de ${widget.userName}'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          TextButton.icon(
            onPressed: _assignPlanWithDialog,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'Salvar Plano',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Coluna de exercícios disponíveis
          Expanded(
            child: Container(
              color: const Color(0xFF1A1A1A),
              child: Column(
                children: [
                  // Filtro de grupo
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Text(
                          'Exercícios Disponíveis',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: selectedGroupFilter,
                          dropdownColor: const Color(0xFF2C2C2C),
                          style: const TextStyle(color: Colors.white),
                          iconEnabledColor: Colors.white,
                          onChanged: (v) {
                            if (v != null)
                              setState(() => selectedGroupFilter = v);
                          },
                          items:
                              muscleGroups
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: available.length,
                      itemBuilder: (ctx, i) {
                        final ex = available[i];
                        return Draggable<Map<String, dynamic>>(
                          data: {
                            ...ex,
                            'sets': 3,
                            'reps': 10,
                            'usePyramid': false,
                            'pyramid': <Map<String, dynamic>>[],
                          },
                          feedback: Material(
                            color: Colors.transparent,
                            child: _dragPreview(ex),
                          ),
                          childWhenDragging: const SizedBox.shrink(),
                          child: _exerciseTile(ex),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Coluna do plano de treino
          Expanded(
            child: Container(
              color: const Color(0xFF2C2C2C),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Plano de Treino',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: DragTarget<Map<String, dynamic>>(
                      onAccept: (ex) {
                        setState(() => selectedExercises.add(Map.of(ex)));
                      },
                      builder: (ctx, _, __) {
                        if (selectedExercises.isEmpty) {
                          return const Center(
                            child: Text(
                              'Arraste exercícios para cá',
                              style: TextStyle(color: Colors.white54),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: selectedExercises.length,
                          itemBuilder: (ctx, i) {
                            final ex = selectedExercises[i];
                            return Card(
                              color: const Color(0xFF333333),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Cabeçalho com nome e excluir
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          ex['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            setState(
                                              () =>
                                                  selectedExercises.removeAt(i),
                                            );
                                          },
                                        ),
                                      ],
                                    ),

                                    // Opção pirâmide
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: ex['usePyramid'] as bool,
                                          onChanged: (v) {
                                            setState(
                                              () => ex['usePyramid'] = v!,
                                            );
                                          },
                                          activeColor: Colors.blueAccent,
                                        ),
                                        const Text(
                                          'Pirâmide',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const Spacer(),
                                      ],
                                    ),

                                    // Séries/Reps ou botão configurar pirâmide
                                    if (!(ex['usePyramid'] as bool)) ...[
                                      Row(
                                        children: [
                                          const Text(
                                            'Séries:',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          DropdownButton<int>(
                                            dropdownColor: const Color(
                                              0xFF2C2C2C,
                                            ),
                                            value: ex['sets'] as int,
                                            items:
                                                List.generate(10, (j) => j + 1)
                                                    .map(
                                                      (v) => DropdownMenuItem(
                                                        value: v,
                                                        child: Text(
                                                          v.toString(),
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged:
                                                (v) => setState(
                                                  () => ex['sets'] = v!,
                                                ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Text(
                                            'Reps:',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          DropdownButton<int>(
                                            dropdownColor: const Color(
                                              0xFF2C2C2C,
                                            ),
                                            value: ex['reps'] as int,
                                            items:
                                                List.generate(30, (j) => j + 1)
                                                    .map(
                                                      (v) => DropdownMenuItem(
                                                        value: v,
                                                        child: Text(
                                                          v.toString(),
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged:
                                                (v) => setState(
                                                  () => ex['reps'] = v!,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed:
                                              () => _configurePyramid(
                                                context,
                                                ex,
                                              ),
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.white70,
                                          ),
                                          label: const Text(
                                            'Configurar Pirâmide',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseTile(Map<String, dynamic> e) {
    return Card(
      color: const Color(0xFF333333),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(e['name'], style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          e['muscleGroup'],
          style: const TextStyle(color: Colors.white60),
        ),
      ),
    );
  }

  Widget _dragPreview(Map<String, dynamic> e) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(e['name'], style: const TextStyle(color: Colors.white)),
    );
  }
}
