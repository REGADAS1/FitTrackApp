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
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Guardar Plano',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
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
                  ...muscleGroups.where((g) => g != 'Todos').map((group) {
                    final isSelected = selectedMuscleGroups.contains(group);
                    return GestureDetector(
                      onTap: () {
                        setStateModal(() {
                          setState(() {
                            if (isSelected) {
                              selectedMuscleGroups.remove(group);
                            } else {
                              selectedMuscleGroups.add(group);
                            }
                          });
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(
                              right: 10,
                              top: 6,
                              bottom: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white),
                              color:
                                  isSelected
                                      ? Colors.green
                                      : Colors.transparent,
                            ),
                            child:
                                isSelected
                                    ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),
                          Text(
                            group,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
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
                          content: Text('Selecione o(s) grupo(s) muscular(es)'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final exerciseNames =
                        selectedExercises.map((e) => e['name']).toList();

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .set({
                          'plan': {
                            name: {
                              'muscleGroups': selectedMuscleGroups,
                              'exercises': exerciseNames,
                            },
                          },
                        }, SetOptions(merge: true));

                    Navigator.pop(context);

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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableExercises =
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _assignPlanWithDialog,
              icon: const Icon(Icons.save),
              label: const Text('Guardar Plano'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Exercícios disponíveis
          Expanded(
            child: Container(
              color: const Color(0xFF1A1A1A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Text(
                          'Exercícios Disponíveis',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: selectedGroupFilter,
                          dropdownColor: const Color(0xFF2C2C2C),
                          style: const TextStyle(color: Colors.white),
                          iconEnabledColor: Colors.white,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedGroupFilter = value);
                            }
                          },
                          items:
                              muscleGroups
                                  .map(
                                    (group) => DropdownMenuItem(
                                      value: group,
                                      child: Text(group),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = availableExercises[index];
                        return Draggable<Map<String, dynamic>>(
                          data: exercise,
                          feedback: Material(
                            color: Colors.transparent,
                            child: _dragPreview(exercise),
                          ),
                          childWhenDragging: const SizedBox.shrink(),
                          child: _exerciseTile(exercise),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Plano de treino
          Expanded(
            child: DragTarget<Map<String, dynamic>>(
              onAccept: (exercise) {
                if (!selectedExercises.any((e) => e['id'] == exercise['id'])) {
                  setState(() {
                    selectedExercises.add(exercise);
                  });
                }
              },
              builder:
                  (context, candidateData, rejectedData) => Container(
                    color: const Color(0xFF2C2C2C),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Plano de Treino',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Expanded(
                          child:
                              selectedExercises.isEmpty
                                  ? const Center(
                                    child: Text(
                                      'Arraste exercícios para aqui',
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: selectedExercises.length,
                                    itemBuilder: (context, index) {
                                      final exercise = selectedExercises[index];
                                      return ListTile(
                                        title: Text(
                                          exercise['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        subtitle: Text(
                                          exercise['muscleGroup'],
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              selectedExercises.removeAt(index);
                                            });
                                          },
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
        ],
      ),
    );
  }

  Widget _exerciseTile(Map<String, dynamic> exercise) {
    return Card(
      color: const Color(0xFF333333),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
          exercise['name'],
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          exercise['muscleGroup'],
          style: const TextStyle(color: Colors.white60),
        ),
      ),
    );
  }

  Widget _dragPreview(Map<String, dynamic> exercise) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        exercise['name'],
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
