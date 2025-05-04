import 'package:fit_track_app/PT/widgets/pt_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CalendarController _calendarController = CalendarController();
  late MeetingDataSource _events;

  final List<Color> _availableColors = [
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.orange,
    Colors.purple,
  ];

  String? selectedUserId;
  List<Map<String, String>> users = [];

  CalendarView _selectedView = CalendarView.week;

  @override
  void initState() {
    super.initState();
    _events = MeetingDataSource([]);
    _calendarController.view = _selectedView;
    _loadUsers().then((_) => _loadData());
  }

  Future<void> _loadUsers() async {
    final snapshot = await _firestore.collection('users').get();
    users =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': '${data['firstName']} ${data['lastName'] ?? ''}'.trim(),
          };
        }).toList();
  }

  Future<void> _loadData() async {
    Query query = _firestore.collection('availability');
    if (selectedUserId != null) {
      query = query.where('userId', isEqualTo: selectedUserId);
    }
    final snapshot = await query.get();
    final appointments =
        snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final subject =
              data['userName'] != null && data['userName'].toString().isNotEmpty
                  ? '${data['title']}\n${data['userName']}'
                  : data['title'] ?? 'Disponível';
          return Appointment(
            startTime: (data['start'] as Timestamp).toDate(),
            endTime: (data['end'] as Timestamp).toDate(),
            subject: subject,
            color: Color(data['color'] ?? Colors.green.value),
            id: doc.id,
          );
        }).toList();

    setState(() {
      _events.appointments!.clear();
      _events.appointments!.addAll(appointments);
      _events.notifyListeners(CalendarDataSourceAction.reset, appointments);
    });
  }

  void _goToToday() {
    _calendarController.displayDate = DateTime.now();
  }

  void _goToPrevious() {
    final current = _calendarController.displayDate ?? DateTime.now();
    _calendarController.displayDate =
        _selectedView == CalendarView.month
            ? DateTime(current.year, current.month - 1, current.day)
            : current.subtract(const Duration(days: 7));
  }

  void _goToNext() {
    final current = _calendarController.displayDate ?? DateTime.now();
    _calendarController.displayDate =
        _selectedView == CalendarView.month
            ? DateTime(current.year, current.month + 1, current.day)
            : current.add(const Duration(days: 7));
  }

  void _selectTime({
    required bool isStart,
    required BuildContext context,
    required DateTime initialTime,
    required void Function(DateTime) onSelected,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialTime),
    );
    if (picked != null) {
      final updated = DateTime(
        initialTime.year,
        initialTime.month,
        initialTime.day,
        picked.hour,
        picked.minute,
      );
      onSelected(updated);
    }
  }

  void _openEventDialog(DateTime selectedDate) async {
    final titleController = TextEditingController();
    DateTime selectedStart = selectedDate;
    DateTime selectedEnd = selectedDate.add(const Duration(hours: 1));
    Color selectedColor = Colors.green;
    String? selectedUser;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF2C2C2C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Agendar Treino',
                  style: TextStyle(color: Colors.white),
                ),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Título",
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Insere um título'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedUser,
                        decoration: const InputDecoration(
                          labelText: "Aluno (opcional)",
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white),
                        items:
                            users
                                .map(
                                  (user) => DropdownMenuItem(
                                    value: user['id'],
                                    child: Text(user['name']!),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => selectedUser = value,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Início:",
                            style: TextStyle(color: Colors.white),
                          ),
                          TextButton(
                            onPressed:
                                () => _selectTime(
                                  isStart: true,
                                  context: context,
                                  initialTime: selectedStart,
                                  onSelected:
                                      (newTime) => setModalState(
                                        () => selectedStart = newTime,
                                      ),
                                ),
                            child: Text(
                              DateFormat.Hm().format(selectedStart),
                              style: const TextStyle(color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Fim:",
                            style: TextStyle(color: Colors.white),
                          ),
                          TextButton(
                            onPressed:
                                () => _selectTime(
                                  isStart: false,
                                  context: context,
                                  initialTime: selectedEnd,
                                  onSelected:
                                      (newTime) => setModalState(
                                        () => selectedEnd = newTime,
                                      ),
                                ),
                            child: Text(
                              DateFormat.Hm().format(selectedEnd),
                              style: const TextStyle(color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        children:
                            _availableColors.map((c) {
                              return GestureDetector(
                                onTap:
                                    () =>
                                        setModalState(() => selectedColor = c),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          selectedColor == c
                                              ? Colors.white
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancelar",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final user = users.firstWhere(
                        (u) => u['id'] == selectedUser,
                        orElse: () => {},
                      );
                      await _firestore.collection('availability').add({
                        'start': Timestamp.fromDate(selectedStart),
                        'end': Timestamp.fromDate(selectedEnd),
                        'title': titleController.text.trim(),
                        'color': selectedColor.value,
                        'userId': selectedUser,
                        'userName': user['name'],
                      });
                      Navigator.pop(context);
                      _loadData();
                    },
                    child: const Text(
                      "Guardar",
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const PTSidebar(currentRoute: '/calendar'),
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Calendário'),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Hoje',
            onPressed: _goToToday,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Anterior',
            onPressed: _goToPrevious,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Seguinte',
            onPressed: _goToNext,
          ),
          DropdownButton<CalendarView>(
            dropdownColor: Colors.black,
            value: _selectedView,
            onChanged: (view) {
              if (view != null) {
                setState(() {
                  _selectedView = view;
                  _calendarController.view = view;
                });
              }
            },
            items: const [
              DropdownMenuItem(value: CalendarView.week, child: Text("Semana")),
              DropdownMenuItem(value: CalendarView.month, child: Text("Mês")),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 250,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                SfDateRangePicker(
                  backgroundColor: Colors.black12,
                  onSelectionChanged: (args) {
                    if (args.value is DateTime) {
                      _calendarController.displayDate = args.value;
                      _openEventDialog(args.value);
                    }
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedUserId,
                  decoration: const InputDecoration(
                    labelText: "Pesquisar pessoas",
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("Todos")),
                    ...users.map(
                      (user) => DropdownMenuItem(
                        value: user['id'],
                        child: Text(user['name']!),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedUserId = value;
                      _loadData();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SfCalendar(
              controller: _calendarController,
              view: _selectedView,
              dataSource: _events,
              backgroundColor: const Color(0xFF1A1A1A),
              viewHeaderStyle: const ViewHeaderStyle(
                backgroundColor: Colors.black12,
                dayTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                dateTextStyle: TextStyle(color: Colors.white70),
              ),
              todayHighlightColor: Colors.blueAccent,
              timeSlotViewSettings: const TimeSlotViewSettings(
                timeInterval: Duration(minutes: 30),
                timeTextStyle: TextStyle(color: Colors.white54),
                timeFormat: 'HH:mm',
              ),
              appointmentBuilder: (context, details) {
                final Appointment appointment = details.appointments.first;
                final parts = appointment.subject.split('\n');
                final title = parts[0];
                final name = parts.length > 1 ? parts[1] : null;
                return Container(
                  decoration: BoxDecoration(
                    color: appointment.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (name != null)
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                );
              },
              onTap: (details) async {
                if (details.targetElement == CalendarElement.calendarCell &&
                    details.date != null) {
                  _openEventDialog(details.date!);
                } else if (details.targetElement ==
                    CalendarElement.appointment) {
                  final appointment =
                      details.appointments!.first as Appointment;
                  final parts = appointment.subject.split('\n');
                  final title = parts[0];
                  final name = parts.length > 1 ? parts[1] : null;

                  final start = appointment.startTime;
                  final end = appointment.endTime;
                  final docId = appointment.id as String?;

                  final docSnapshot =
                      await _firestore
                          .collection('availability')
                          .doc(docId)
                          .get();
                  final data = docSnapshot.data();
                  final String? eventUserId = data?['userId'];
                  final String? eventUserName = data?['userName'];

                  String? selectedUserId = eventUserId;
                  String? selectedUserName = eventUserName;
                  final titleController = TextEditingController(text: title);
                  DateTime selectedStart = start;
                  DateTime selectedEnd = end;
                  Color selectedColor = appointment.color;
                  final formKey = GlobalKey<FormState>();

                  showDialog(
                    context: context,
                    builder:
                        (_) => StatefulBuilder(
                          builder:
                              (context, setModalState) => AlertDialog(
                                backgroundColor: const Color(0xFF2C2C2C),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text(
                                  'Editar Evento',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: Form(
                                  key: formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextFormField(
                                        controller: titleController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: const InputDecoration(
                                          labelText: "Título",
                                          labelStyle: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        validator:
                                            (value) =>
                                                value == null ||
                                                        value.trim().isEmpty
                                                    ? 'Insere um título'
                                                    : null,
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        value: selectedUserId,
                                        decoration: const InputDecoration(
                                          labelText: "Aluno (opcional)",
                                          labelStyle: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        dropdownColor: Colors.black,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        items:
                                            users
                                                .map(
                                                  (user) => DropdownMenuItem(
                                                    value: user['id'],
                                                    child: Text(user['name']!),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged:
                                            (value) => setModalState(() {
                                              selectedUserId = value;
                                              selectedUserName =
                                                  users.firstWhere(
                                                    (u) => u['id'] == value,
                                                  )['name'];
                                            }),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Início:",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => _selectTime(
                                                  isStart: true,
                                                  context: context,
                                                  initialTime: selectedStart,
                                                  onSelected:
                                                      (newTime) =>
                                                          setModalState(
                                                            () =>
                                                                selectedStart =
                                                                    newTime,
                                                          ),
                                                ),
                                            child: Text(
                                              DateFormat.Hm().format(
                                                selectedStart,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.blueAccent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Fim:",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => _selectTime(
                                                  isStart: false,
                                                  context: context,
                                                  initialTime: selectedEnd,
                                                  onSelected:
                                                      (newTime) =>
                                                          setModalState(
                                                            () =>
                                                                selectedEnd =
                                                                    newTime,
                                                          ),
                                                ),
                                            child: Text(
                                              DateFormat.Hm().format(
                                                selectedEnd,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.blueAccent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (_) => AlertDialog(
                                              backgroundColor: const Color(
                                                0xFF2C2C2C,
                                              ),
                                              title: const Text(
                                                'Tem a certeza?',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              content: const Text(
                                                'Deseja eliminar este evento?',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text(
                                                    'Cancelar',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text(
                                                    'Eliminar',
                                                    style: TextStyle(
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                      );
                                      if (confirm == true && docId != null) {
                                        Navigator.pop(context);
                                        await _firestore
                                            .collection('availability')
                                            .doc(docId)
                                            .delete();
                                        _loadData();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Evento eliminado com sucesso.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      "Eliminar",
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      "Cancelar",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      if (!formKey.currentState!.validate())
                                        return;
                                      final user = users.firstWhere(
                                        (u) => u['id'] == selectedUserId,
                                        orElse: () => {},
                                      );
                                      await _firestore
                                          .collection('availability')
                                          .doc(docId)
                                          .update({
                                            'start': Timestamp.fromDate(
                                              selectedStart,
                                            ),
                                            'end': Timestamp.fromDate(
                                              selectedEnd,
                                            ),
                                            'title':
                                                titleController.text.trim(),
                                            'color': selectedColor.value,
                                            'userId': selectedUserId,
                                            'userName': user['name'],
                                          });
                                      Navigator.pop(context);
                                      _loadData();
                                    },
                                    child: const Text(
                                      "Guardar",
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
