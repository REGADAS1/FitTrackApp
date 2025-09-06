import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PTAssessmentsPage extends StatefulWidget {
  final String userId;
  final String userName;

  const PTAssessmentsPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<PTAssessmentsPage> createState() => _PTAssessmentsPageState();
}

class _PTAssessmentsPageState extends State<PTAssessmentsPage> {
  static const Color themeBlue = Color(0xFF6EC1E4);

  bool _showForm = false;

  final _scrollCtrl = ScrollController();

  final _formKey = GlobalKey<FormState>();
  final _pesoCtrl = TextEditingController();
  final _visceralCtrl = TextEditingController();
  final _leanCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _cinturaCtrl = TextEditingController();
  final _ancaCtrl = TextEditingController();
  final _peitoCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _pickedDateTime = DateTime.now();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _pesoCtrl.dispose();
    _visceralCtrl.dispose();
    _leanCtrl.dispose();
    _fatCtrl.dispose();
    _cinturaCtrl.dispose();
    _ancaCtrl.dispose();
    _peitoCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDateTime,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      helpText: 'Seleciona a data',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
    );
    if (picked != null) {
      setState(() {
        _pickedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _pickedDateTime.hour,
          _pickedDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_pickedDateTime),
      helpText: 'Seleciona a hora',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
    );
    if (picked != null) {
      setState(() {
        _pickedDateTime = DateTime(
          _pickedDateTime.year,
          _pickedDateTime.month,
          _pickedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // 1) Guardar avaliação
    final assessmentsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('assessments');

    final newWeight = _parseNum(_pesoCtrl.text);
    await assessmentsRef.add({
      'date': Timestamp.fromDate(_pickedDateTime),
      'createdAt': FieldValue.serverTimestamp(),
      'peso': newWeight,
      'gorduraVisceral': _parseNum(_visceralCtrl.text),
      'massaMagraPct': _parseNum(_leanCtrl.text),
      'massaGordaPct': _parseNum(_fatCtrl.text),
      'cinturaCm': _parseNum(_cinturaCtrl.text),
      'ancaCm': _parseNum(_ancaCtrl.text),
      'peitoCm': _parseNum(_peitoCtrl.text),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    });

    // 2) Atualizar perfil do aluno com o novo peso (se fornecido)
    if (newWeight != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'weight': newWeight});
    }

    // 3) Limpar e fechar formulário
    _formKey.currentState!.reset();
    _pesoCtrl.clear();
    _visceralCtrl.clear();
    _leanCtrl.clear();
    _fatCtrl.clear();
    _cinturaCtrl.clear();
    _ancaCtrl.clear();
    _peitoCtrl.clear();
    _notesCtrl.clear();
    setState(() {
      _pickedDateTime = DateTime.now();
      _showForm = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação guardada com sucesso.')),
      );
    }
  }

  num? _parseNum(String v) {
    final t = v.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return num.tryParse(t);
  }

  String _fmtDateTime(DateTime dt) =>
      DateFormat('dd/MM/yyyy • HH:mm', 'pt_PT').format(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Avaliações — ${widget.userName}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          setState(() => _showForm = !_showForm);
          await Future.delayed(const Duration(milliseconds: 50));
          if (_showForm && _scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        },
        backgroundColor: themeBlue,
        icon: Icon(_showForm ? Icons.close : Icons.add),
        label: Text(_showForm ? 'Cancelar' : 'Nova avaliação'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAssessmentsList(),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder:
                    (child, anim) =>
                        SizeTransition(sizeFactor: anim, child: child),
                child: _showForm ? _buildFormCard() : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentsList() {
    final colRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('assessments')
        .orderBy('date', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: colRef.snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Ainda não existem avaliações para este aluno.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return Column(
          children:
              docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final date = (data['date'] as Timestamp?)?.toDate();

                final chips = <Widget>[];
                void addChip(String label, dynamic value, {String sufix = ''}) {
                  if (value == null || (value is String && value.isEmpty))
                    return;
                  chips.add(
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: Chip(
                        backgroundColor: Colors.white10,
                        label: Text(
                          '$label ${value is num ? value.toStringAsFixed(value % 1 == 0 ? 0 : 1) : value}$sufix',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }

                addChip('Peso:', data['peso'], sufix: ' kg');
                addChip('Gord. visceral:', data['gorduraVisceral']);
                addChip('% Magra:', data['massaMagraPct'], sufix: ' %');
                addChip('% Gorda:', data['massaGordaPct'], sufix: ' %');
                addChip('Cintura:', data['cinturaCm'], sufix: ' cm');
                addChip('Anca:', data['ancaCm'], sufix: ' cm');
                addChip('Peito:', data['peitoCm'], sufix: ' cm');

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.event,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            date != null ? _fmtDateTime(date) : 'Sem data',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          PopupMenuButton(
                            color: const Color(0xFF2A2A2A),
                            iconColor: Colors.white70,
                            onSelected: (value) async {
                              if (value == 'delete') {
                                await d.reference.delete();
                              }
                            },
                            itemBuilder:
                                (_) => const [
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Eliminar'),
                                      ],
                                    ),
                                  ),
                                ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(children: chips),
                      if ((data['notes'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          data['notes'],
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildFormCard() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Container(
          key: const ValueKey('assessment-form'),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(color: Colors.white24, thickness: 2),
                const SizedBox(height: 8),
                const Text(
                  'Nova Avaliação Corporal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _PickTile(
                        label: 'Data',
                        value: DateFormat(
                          'dd/MM/yyyy',
                          'pt_PT',
                        ).format(_pickedDateTime),
                        icon: Icons.calendar_today,
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickTile(
                        label: 'Hora',
                        value: DateFormat(
                          'HH:mm',
                          'pt_PT',
                        ).format(_pickedDateTime),
                        icon: Icons.schedule,
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _numField(_pesoCtrl, 'Peso (kg)')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numField(_visceralCtrl, 'Gordura visceral'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _numField(_leanCtrl, '% Massa magra')),
                    const SizedBox(width: 12),
                    Expanded(child: _numField(_fatCtrl, '% Massa gorda')),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _numField(_cinturaCtrl, 'Cintura (cm)')),
                    const SizedBox(width: 12),
                    Expanded(child: _numField(_ancaCtrl, 'Anca (cm)')),
                  ],
                ),
                const SizedBox(height: 12),

                _numField(_peitoCtrl, 'Peito (cm)'),
                const SizedBox(height: 12),

                _notesField(_notesCtrl, 'Notas (opcional)'),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeBlue,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, String hint) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: false,
      ),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF262626),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: (v) => null,
    );
  }

  Widget _notesField(TextEditingController c, String hint) {
    return TextFormField(
      controller: c,
      maxLines: 4,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF262626),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }
}
