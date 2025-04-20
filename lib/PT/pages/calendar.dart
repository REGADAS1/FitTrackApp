import 'package:fit_track_app/PT/widgets/pt_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
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

  @override
  void initState() {
    super.initState();
    _events = MeetingDataSource([]);
    _loadData();
  }

  Future<void> _loadData() async {
    final snapshot = await _firestore.collection('availability').get();
    final appointments =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return Appointment(
            startTime: (data['start'] as Timestamp).toDate(),
            endTime: (data['end'] as Timestamp).toDate(),
            subject: data['title'] ?? 'Disponível',
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

  Future<void> _openEventDialog({
    DateTime? start,
    DateTime? end,
    String? title,
    Color? color,
    String? docId,
  }) async {
    final titleController = TextEditingController(text: title ?? '');
    DateTime selectedStart = start ?? DateTime.now();
    DateTime selectedEnd = end ?? selectedStart.add(const Duration(hours: 1));
    Color selectedColor = color ?? Colors.green;
    final formKey = GlobalKey<FormState>();
    final isEditing = docId != null;

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
                title: Text(
                  isEditing ? 'Alterar Evento' : 'Agendar Disponibilidade',
                  style: const TextStyle(color: Colors.white),
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
                                (value == null || value.trim().isEmpty)
                                    ? 'Insere um título'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            "Início:",
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  selectedStart,
                                ),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  selectedStart = DateTime(
                                    selectedStart.year,
                                    selectedStart.month,
                                    selectedStart.day,
                                    picked.hour,
                                    picked.minute,
                                  );
                                });
                              }
                            },
                            child: Text(
                              DateFormat.Hm().format(selectedStart),
                              style: const TextStyle(color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            "Fim:",
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  selectedEnd,
                                ),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  selectedEnd = DateTime(
                                    selectedEnd.year,
                                    selectedEnd.month,
                                    selectedEnd.day,
                                    picked.hour,
                                    picked.minute,
                                  );
                                });
                              }
                            },
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
                  if (isEditing)
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _firestore
                            .collection('availability')
                            .doc(docId)
                            .delete();
                        _loadData();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.redAccent,
                            content: Text("Evento eliminado com sucesso."),
                          ),
                        );
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
                      if (!formKey.currentState!.validate()) return;

                      final doc = {
                        'start': Timestamp.fromDate(selectedStart),
                        'end': Timestamp.fromDate(selectedEnd),
                        'title': titleController.text.trim(),
                        'color': selectedColor.value,
                      };

                      if (docId != null) {
                        await _firestore
                            .collection('availability')
                            .doc(docId)
                            .update(doc);
                      } else {
                        await _firestore.collection('availability').add(doc);
                      }

                      final formattedDay = DateFormat.EEEE(
                        'pt_PT',
                      ).format(selectedStart);
                      final formattedMonth = DateFormat.MMMM(
                        'pt_PT',
                      ).format(selectedStart);
                      final dayNumber = selectedStart.day;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color.fromARGB(
                            221,
                            19,
                            89,
                            125,
                          ),
                          content: Text(
                            '${isEditing ? 'Evento atualizado' : 'Evento criado'} para $formattedDay, dia $dayNumber de $formattedMonth.',
                          ),
                        ),
                      );

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
      ),
      body: SfCalendar(
        view: CalendarView.week,
        controller: _calendarController,
        dataSource: _events,
        backgroundColor: const Color(0xFF1A1A1A),
        appointmentBuilder: (context, details) {
          final Appointment appointment = details.appointments.first;
          return Container(
            decoration: BoxDecoration(
              color: appointment.color,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(6),
            child: Text(
              appointment.subject,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
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
        onTap: (details) {
          if (details.targetElement == CalendarElement.appointment) {
            final appointment = details.appointments!.first as Appointment;
            _openEventDialog(
              start: appointment.startTime,
              end: appointment.endTime,
              title: appointment.subject,
              color: appointment.color,
              docId: appointment.id as String?,
            );
          } else if (details.targetElement == CalendarElement.calendarCell) {
            _openEventDialog(start: details.date);
          }
        },
      ),
    );
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
