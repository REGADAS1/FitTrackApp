// lib/PT/pages/periodization_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PeriodizationPage extends StatefulWidget {
  final String userId;
  final String userName;
  const PeriodizationPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<PeriodizationPage> createState() => _PeriodizationPageState();
}

class _PeriodizationPageState extends State<PeriodizationPage> {
  static const Color themeBlue = Color(0xFF6EC1E4);
  final _dateFmt = DateFormat('dd/MM/yyyy');

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(widget.userId)
      .collection('periodization_phases');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Periodização • ${widget.userName}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: themeBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova fase'),
        onPressed: () => _openPhaseSheet(),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _col.orderBy('startDate').snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data?.docs ?? [];

            if (docs.isEmpty) {
              return _emptyState();
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final d = docs[i];
                final data = d.data();
                final title =
                    (data['title'] as String?)?.trim().isNotEmpty == true
                        ? data['title'] as String
                        : 'Fase';
                final notes = (data['notes'] as String?) ?? '';
                final color = Color((data['color'] as int?) ?? 0xFFFF9800);
                final start = (data['startDate'] as Timestamp).toDate();
                final end = (data['endDate'] as Timestamp).toDate();

                final status = _phaseStatus(start, end);
                final weeks = _weeksBetween(start, end);
                final progress = _phaseProgress(start, end); // 0..1

                return _phaseCard(
                  id: d.id,
                  title: title,
                  notes: notes,
                  color: color,
                  start: start,
                  end: end,
                  weeks: weeks,
                  status: status,
                  progress: progress,
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ---------- Widgets ----------

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timeline, color: Colors.white54, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Ainda não há fases de periodização.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: _openPhaseSheet,
              icon: const Icon(Icons.add),
              label: const Text('Criar primeira fase'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phaseCard({
    required String id,
    required String title,
    required String notes,
    required Color color,
    required DateTime start,
    required DateTime end,
    required int weeks,
    required _PhaseStatus status,
    required double progress,
  }) {
    final statusText = switch (status) {
      _PhaseStatus.planned => 'Planeada',
      _PhaseStatus.active => 'Ativa',
      _PhaseStatus.done => 'Concluída',
    };
    final statusColor = switch (status) {
      _PhaseStatus.planned => Colors.white70,
      _PhaseStatus.active => themeBlue,
      _PhaseStatus.done => Colors.greenAccent,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.6), width: 1.2),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + dot + ações
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Editar',
                onPressed:
                    () => _openPhaseSheet(
                      id: id,
                      initial: _PhaseFormData(
                        title: title,
                        notes: notes,
                        color: color,
                        start: start,
                        end: end,
                      ),
                    ),
                icon: const Icon(Icons.edit, color: Colors.white70),
              ),
              IconButton(
                tooltip: 'Eliminar',
                onPressed: () => _confirmDelete(id),
                icon: const Icon(Icons.delete, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Datas + semanas + status chip
          Row(
            children: [
              Text(
                '${_dateFmt.format(start)} — ${_dateFmt.format(end)}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 10),
              Text(
                '• $weeks ${weeks == 1 ? 'semana' : 'semanas'}',
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.6)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value:
                  status == _PhaseStatus.active
                      ? progress.clamp(0.0, 1.0)
                      : (status == _PhaseStatus.done ? 1 : 0),
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          if (notes.trim().isNotEmpty)
            Text(notes, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // ---------- Actions ----------

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            title: const Text(
              'Eliminar fase',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Tens a certeza que queres eliminar esta fase?',
              style: TextStyle(color: Colors.white70),
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
    if (ok == true) {
      await _col.doc(id).delete();
    }
  }

  Future<void> _openPhaseSheet({String? id, _PhaseFormData? initial}) async {
    final form = _PhaseFormData.from(initial);
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;

        // <<< TUDO DENTRO DE UM StatefulBuilder PARA NÃO RECRIAR O FORM >>>
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      Text(
                        id == null
                            ? 'Nova fase de periodização'
                            : 'Editar fase',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Título
                      TextFormField(
                        initialValue: form.title,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Título (ex.: Força / Hipertrofia)',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Indica um título'
                                    : null,
                        onChanged: (v) => form.title = v.trim(),
                      ),
                      const SizedBox(height: 12),

                      // Notas
                      TextFormField(
                        initialValue: form.notes,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Notas (opcional)',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        onChanged: (v) => form.notes = v.trim(),
                      ),
                      const SizedBox(height: 12),

                      // Datas (usam setModalState)
                      Row(
                        children: [
                          Expanded(
                            child: _dateField(
                              label: 'Início',
                              value: form.start,
                              onPick:
                                  (d) => setModalState(() => form.start = d),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _dateField(
                              label: 'Fim',
                              value: form.end,
                              onPick: (d) => setModalState(() => form.end = d),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Paleta de cores (seleção com setModalState)
                      const Text(
                        'Cor da fase',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            _palette.map((c) {
                              final selected = form.color.value == c.value;
                              return GestureDetector(
                                onTap:
                                    () => setModalState(() => form.color = c),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          selected
                                              ? Colors.white
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeBlue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false))
                              return;
                            if (form.start.isAfter(form.end)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'A data de início não pode ser após o fim.',
                                  ),
                                ),
                              );
                              return;
                            }

                            final payload = {
                              'title': form.title,
                              'notes': form.notes,
                              'color': form.color.value,
                              'startDate': Timestamp.fromDate(
                                _atMidnight(form.start),
                              ),
                              'endDate': Timestamp.fromDate(
                                _endOfDay(form.end),
                              ),
                              'updatedAt': FieldValue.serverTimestamp(),
                            };

                            if (id == null) {
                              await _col.add({
                                ...payload,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                            } else {
                              await _col
                                  .doc(id)
                                  .set(payload, SetOptions(merge: true));
                            }
                            if (mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.save),
                          label: Text(
                            id == null ? 'Criar fase' : 'Guardar alterações',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------- Helpers ----------

  Widget _dateField({
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onPick,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          initialDate: value,
          builder:
              (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF6EC1E4),
                    onPrimary: Colors.white,
                    surface: Color(0xFF2C2C2C),
                    onSurface: Colors.white,
                  ),
                  dialogBackgroundColor: const Color(0xFF1E1E1E),
                ),
                child: child!,
              ),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.event, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label: ${_dateFmt.format(value)}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const Icon(Icons.edit_calendar, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

  _PhaseStatus _phaseStatus(DateTime start, DateTime end) {
    final now = DateTime.now();
    if (now.isBefore(_atMidnight(start))) return _PhaseStatus.planned;
    if (now.isAfter(_endOfDay(end))) return _PhaseStatus.done;
    return _PhaseStatus.active;
  }

  int _weeksBetween(DateTime start, DateTime end) {
    final s = _atMidnight(start);
    final e = _endOfDay(end);
    final days = e.difference(s).inDays + 1;
    return (days / 7).ceil();
  }

  double _phaseProgress(DateTime start, DateTime end) {
    final s = _atMidnight(start);
    final e = _endOfDay(end);
    final now = DateTime.now();
    if (now.isBefore(s)) return 0;
    if (now.isAfter(e)) return 1;
    final total = e.difference(s).inSeconds;
    final done = now.difference(s).inSeconds;
    if (total <= 0) return 1;
    return done / total;
  }

  DateTime _atMidnight(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);

  static const List<Color> _palette = [
    Color(0xFFFF9800), // laranja
    Color(0xFFE91E63), // rosa
    Color(0xFF6EC1E4), // azul NVRTAP
    Color(0xFF8BC34A), // verde
    Color(0xFF9C27B0), // roxo
    Color(0xFFFF7043), // laranja escuro
    Color(0xFF00BCD4), // ciano
  ];
}

enum _PhaseStatus { planned, active, done }

class _PhaseFormData {
  String title;
  String notes;
  Color color;
  DateTime start;
  DateTime end;

  _PhaseFormData({
    required this.title,
    required this.notes,
    required this.color,
    required this.start,
    required this.end,
  });

  factory _PhaseFormData.from(_PhaseFormData? other) {
    if (other != null) {
      return _PhaseFormData(
        title: other.title,
        notes: other.notes,
        color: other.color,
        start: other.start,
        end: other.end,
      );
    }
    final now = DateTime.now();
    final after2w = now.add(const Duration(days: 13));
    return _PhaseFormData(
      title: '',
      notes: '',
      color: const Color(0xFFFF9800),
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(after2w.year, after2w.month, after2w.day),
    );
  }
}
