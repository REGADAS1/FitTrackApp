import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise_list.dart';
import 'assign_workout.dart';
import 'view_workouts.dart';

class PTDashboardPage extends StatefulWidget {
  const PTDashboardPage({super.key});

  @override
  State<PTDashboardPage> createState() => _PTDashboardPageState();
}

class _PTDashboardPageState extends State<PTDashboardPage> {
  Map<String, dynamic>? _selectedUser;
  bool _showDetailsPanel = false;

  void _openUserPanel(QueryDocumentSnapshot userDoc) {
    setState(() {
      _selectedUser = {
        ...userDoc.data() as Map<String, dynamic>,
        'id': userDoc.id,
      };
      _showDetailsPanel = true;
    });
  }

  void _closePanel() {
    setState(() => _showDetailsPanel = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A1A1A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Text(
                'Menu Principal',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text(
                'Dashboard',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center, color: Colors.white),
              title: const Text(
                'Lista de Exercícios',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExerciseListPage()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: Builder(
          builder:
              (context) => Padding(
                padding: const EdgeInsets.only(left: 12),
                child: GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.menu, color: Colors.white),
                  ),
                ),
              ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: StreamBuilder(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    if (data['role'] == 'pt') return const SizedBox();

                    final fullName =
                        '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}';
                    final profileUrl = data['profilePictureUrl'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openUserPanel(docs[index]),
                          borderRadius: BorderRadius.circular(12),
                          child: Card(
                            color: const Color(0xFF2C2C2C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    profileUrl != null
                                        ? NetworkImage(profileUrl)
                                        : const AssetImage(
                                              'assets/images/default_avatar.png',
                                            )
                                            as ImageProvider,
                                radius: 25,
                              ),
                              title: Text(
                                fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Peso: ${data['weight'] ?? '--'} kg',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Altura: ${data['height'] ?? '--'} m',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Objetivo: ${data['goal'] ?? '--'}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_showDetailsPanel)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closePanel,
                child: Container(color: Colors.black.withOpacity(0.4)),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            right:
                _showDetailsPanel
                    ? 0
                    : -MediaQuery.of(context).size.width * 0.3,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.3,
            child: Material(
              elevation: 10,
              color: const Color(0xFF1A1A1A),
              child:
                  _selectedUser == null
                      ? const Center(
                        child: Text(
                          'Nenhum aluno selecionado',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: _closePanel,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: CircleAvatar(
                                radius: 45,
                                backgroundImage:
                                    _selectedUser!['profilePictureUrl'] != null
                                        ? NetworkImage(
                                          _selectedUser!['profilePictureUrl'],
                                        )
                                        : const AssetImage(
                                              'assets/images/default_avatar.png',
                                            )
                                            as ImageProvider,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                '${_selectedUser!['firstName']} ${_selectedUser!['lastName']}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Peso: ${_selectedUser!['weight']} kg',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Altura: ${_selectedUser!['height']} m',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Objetivo: ${_selectedUser!['goal']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Plano de Treino:',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if ((_selectedUser!['plan'] as Map?)?.isNotEmpty ??
                                false)
                              ...(_selectedUser!['plan']
                                      as Map<String, dynamic>)
                                  .entries
                                  .map((entry) {
                                    final planName = entry.key;
                                    final exercises =
                                        (entry.value['exercises'] as List?)
                                            ?.cast<String>() ??
                                        [];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          planName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        ...exercises.map(
                                          (e) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2,
                                            ),
                                            child: Text(
                                              '- $e',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    );
                                  })
                                  .toList()
                            else
                              const Text(
                                'Nenhum plano atribuído.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    final id = _selectedUser!['id'];
                                    final name =
                                        '${_selectedUser!['firstName']} ${_selectedUser!['lastName']}';
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => AssignWorkoutPage(
                                              userId: id,
                                              userName: name,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.fitness_center),
                                  label: const Text('Criar Plano de Treino'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ViewWorkoutsPage(
                                              userEmail:
                                                  _selectedUser!['email'],
                                              userName:
                                                  '${_selectedUser!['firstName']} ${_selectedUser!['lastName']}',
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.view_list),
                                  label: const Text('Planos de Treino'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.grey[800],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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
