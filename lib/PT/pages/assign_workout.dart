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
          snapshot.docs
              .map(
                (doc) => {
                  'id': doc.id,
                  'name': doc['name'],
                  'muscleGroup': doc['muscleGroup'],
                },
              )
              .toList();
    });
  }

  void _assignPlan() async {
    try {
      final exerciseNames = selectedExercises.map((e) => e['name']).toList();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({'plan': exerciseNames}, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plano atribuído com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Atribuir Plano a ${widget.userName}'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _assignPlan),
        ],
      ),
      body: Row(
        children: [
          // Lista de exercícios disponíveis
          Expanded(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Exercícios Disponíveis',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: allExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = allExercises[index];
                      return Draggable<Map<String, dynamic>>(
                        data: exercise,
                        feedback: Material(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.blueGrey,
                            child: Text(
                              exercise['name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: ListTile(title: Text(exercise['name'])),
                        ),
                        child: ListTile(
                          title: Text(exercise['name']),
                          subtitle: Text(exercise['muscleGroup']),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Área de drop
          Expanded(
            child: DragTarget<Map<String, dynamic>>(
              onAccept: (exercise) {
                if (!selectedExercises.contains(exercise)) {
                  setState(() {
                    selectedExercises.add(exercise);
                  });
                }
              },
              builder:
                  (context, candidateData, rejectedData) => Container(
                    color: Colors.grey[900],
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Plano de Treino',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: selectedExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = selectedExercises[index];
                              return ListTile(
                                title: Text(
                                  exercise['name'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  exercise['muscleGroup'],
                                  style: const TextStyle(color: Colors.white70),
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
}
