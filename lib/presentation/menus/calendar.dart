// lib/presentation/menus/calendar_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'package:fit_track_app/presentation/widgets/sidebar.dart';

class CalendarUserPage extends StatefulWidget {
  const CalendarUserPage({super.key});

  @override
  State<CalendarUserPage> createState() => _CalendarUserPageState();
}

class _CalendarUserPageState extends State<CalendarUserPage> {
  static const Color themeBlue = Color(0xFF6EC1E4);

  final CalendarController _controller = CalendarController();
  CalendarView _view = CalendarView.week;

  // Sidebar (mesma UX da dashboard)
  double _sidebarXOffset = -250;
  bool _isDragging = false;

  // ---- Pinch zoom ----
  // escala atual para altura dos "time slots"
  double _scale = 1.0;
  double _startScale = 1.0;
  static const double _baseSlotHeight = 54; // altura confortável por slot
  double get _slotHeight =>
      (_baseSlotHeight * _scale).clamp(36.0, 160.0); // limites

  User? get _user => FirebaseAuth.instance.currentUser;

  void _goToday() => _controller.displayDate = DateTime.now();

  void _goPrev() {
    final current = _controller.displayDate ?? DateTime.now();
    _controller.displayDate =
        _view == CalendarView.month
            ? DateTime(current.year, current.month - 1, current.day)
            : current.subtract(const Duration(days: 7));
    setState(() {});
  }

  void _goNext() {
    final current = _controller.displayDate ?? DateTime.now();
    _controller.displayDate =
        _view == CalendarView.month
            ? DateTime(current.year, current.month + 1, current.day)
            : current.add(const Duration(days: 7));
    setState(() {});
  }

  // Eventos do próprio user
  Stream<List<Appointment>> _userAppointments() {
    final uid = _user?.uid;
    if (uid == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('availability')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = doc.data();
            final start = (data['start'] as Timestamp).toDate();
            final end = (data['end'] as Timestamp).toDate();
            final title =
                (data['title'] as String?)?.trim().isNotEmpty == true
                    ? data['title'] as String
                    : 'Treino';
            final color = Color((data['color'] ?? themeBlue.value) as int);

            return Appointment(
              startTime: start,
              endTime: end,
              subject: title,
              color: color,
              id: doc.id,
            );
          }).toList();
        });
  }

  @override
  void initState() {
    super.initState();
    _controller.view = _view;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragStart: (_) => _isDragging = true,
        onHorizontalDragUpdate: (details) {
          if (_isDragging) {
            setState(() {
              _sidebarXOffset += details.delta.dx;
              _sidebarXOffset = _sidebarXOffset.clamp(-250, 0);
            });
          }
        },
        onHorizontalDragEnd: (_) {
          _isDragging = false;
          setState(() => _sidebarXOffset = _sidebarXOffset > -125 ? 0 : -250);
        },
        child: Stack(
          children: [
            // Fundo
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1E1E), Color(0xFF111111)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _topBar(),
                    const SizedBox(height: 12),
                    _calendarToolbar(),
                    const SizedBox(height: 8),

                    // -------- Calendário com Pinch Zoom ----------
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: StreamBuilder<List<Appointment>>(
                          stream: _userAppointments(),
                          builder: (context, snap) {
                            final appointments =
                                snap.data ?? const <Appointment>[];

                            // Apenas a zona do calendário responde ao gesto de pinça
                            return GestureDetector(
                              onScaleStart: (details) {
                                _startScale = _scale;
                              },
                              onScaleUpdate: (details) {
                                // só aplicamos zoom significativo quando em Week/WorkWeek/Day
                                if (_view == CalendarView.week ||
                                    _view == CalendarView.workWeek ||
                                    _view == CalendarView.day) {
                                  setState(() {
                                    _scale = (_startScale * details.scale)
                                        .clamp(0.7, 2.0);
                                  });
                                }
                              },
                              child: Localizations.override(
                                context: context,
                                locale: const Locale('pt', 'PT'),
                                child: SfCalendar(
                                  controller: _controller,
                                  view: _view,
                                  dataSource: _UserCalendarDataSource(
                                    appointments,
                                  ),
                                  backgroundColor: Colors.transparent,
                                  todayHighlightColor: themeBlue,

                                  // Seleção com borda azul (sem roxo)
                                  selectionDecoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: themeBlue,
                                      width: 2,
                                    ),
                                  ),

                                  headerStyle: const CalendarHeaderStyle(
                                    textStyle: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),

                                  // Dias da semana com letra mais pequena
                                  viewHeaderHeight: 34,
                                  viewHeaderStyle: const ViewHeaderStyle(
                                    dayTextStyle: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 7,
                                    ),
                                    dateTextStyle: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),

                                  monthViewSettings: const MonthViewSettings(
                                    dayFormat: 'EEE',
                                    showAgenda: true,
                                    agendaStyle: AgendaStyle(
                                      backgroundColor: Colors.transparent,
                                      appointmentTextStyle: TextStyle(
                                        color: Colors.white,
                                      ),
                                      dayTextStyle: TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),

                                  // Altura dos "time slots" controlada pela escala do gesto
                                  timeSlotViewSettings: TimeSlotViewSettings(
                                    timeInterval: const Duration(minutes: 30),
                                    timeTextStyle: const TextStyle(
                                      color: Colors.white60,
                                    ),
                                    timeFormat: 'HH:mm',
                                    timeIntervalHeight: _slotHeight,
                                  ),

                                  appointmentBuilder: _appointmentBuilder,

                                  onTap: (details) {
                                    if (details.targetElement ==
                                            CalendarElement.appointment &&
                                        details.appointments?.isNotEmpty ==
                                            true) {
                                      final Appointment a =
                                          details.appointments!.first
                                              as Appointment;
                                      _showEventSheet(a);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Overlay para fechar sidebar
            if (_sidebarXOffset == 0)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _sidebarXOffset = -250),
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),

            // Sidebar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: _sidebarXOffset,
              top: 0,
              bottom: 0,
              child: Sidebar(
                width: 250,
                onClose: () => setState(() => _sidebarXOffset = -250),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI blocks ----------------

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => setState(() => _sidebarXOffset = 0),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Calendário',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: _goToday,
            icon: const Icon(Icons.today, color: Colors.white),
            tooltip: 'Hoje',
          ),
        ],
      ),
    );
  }

  Widget _calendarToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: _goPrev,
              tooltip: 'Anterior',
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: _goNext,
              tooltip: 'Seguinte',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _segmentedButton(
                        selected: _view == CalendarView.week,
                        label: 'Semana',
                        onTap: () {
                          setState(() {
                            _view = CalendarView.week;
                            _controller.view = _view;
                          });
                        },
                      ),
                      _segmentedButton(
                        selected: _view == CalendarView.month,
                        label: 'Mês',
                        onTap: () {
                          setState(() {
                            _view = CalendarView.month;
                            _controller.view = _view;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentedButton({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? themeBlue.withOpacity(0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _appointmentBuilder(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final Appointment a = details.appointments.first;
    return Container(
      decoration: BoxDecoration(
        color: a.color,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            a.subject,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${DateFormat.Hm().format(a.startTime)} — ${DateFormat.Hm().format(a.endTime)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showEventSheet(Appointment a) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                a.subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${DateFormat('EEE, dd MMM HH:mm', 'pt_PT').format(a.startTime)}'
                ' — ${DateFormat('HH:mm', 'pt_PT').format(a.endTime)}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.white70, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Treino agendado pelo teu PT. Mantém consistência 💪',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeBlue,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserCalendarDataSource extends CalendarDataSource {
  _UserCalendarDataSource(List<Appointment> source) {
    appointments = source;
  }
}
