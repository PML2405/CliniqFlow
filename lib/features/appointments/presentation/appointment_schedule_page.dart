import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cliniqflow/core/widgets/user_avatar.dart';
import '../../patients/presentation/patient_directory_controller.dart';
import '../models/appointment.dart';
import 'appointment_editor_dialog.dart';
import 'appointment_schedule_controller.dart';

class AppointmentSchedulePage extends StatefulWidget {
  const AppointmentSchedulePage({
    super.key,
    required this.clinicianName,
    this.clinicianPhotoUrl,
    this.onAvatarTap,
  });

  final String clinicianName;
  final String? clinicianPhotoUrl;
  final VoidCallback? onAvatarTap;

  @override
  State<AppointmentSchedulePage> createState() =>
      _AppointmentSchedulePageState();
}

class _CalendarSheet extends StatelessWidget {
  const _CalendarSheet({required this.controller});

  final AppointmentScheduleController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Calendar', style: theme.textTheme.titleMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MonthlyCalendar(
            controller: controller,
            onDateSelected: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _CalendarPage extends StatelessWidget {
  const _CalendarPage({required this.controller});

  final AppointmentScheduleController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _MonthlyCalendar(
            controller: controller,
            onDateSelected: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.controller});

  final AppointmentScheduleController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = controller.statusFilter;
    Widget buildChip(
      AppointmentStatus? status,
      String label,
      IconData icon,
    ) {
      return FilterChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        visualDensity: VisualDensity.compact,
        showCheckmark: false,
        selected: value == status,
        onSelected: (selected) {
          final nextValue = selected ? status : null;
          controller.setStatusFilter(nextValue);
        },
      );
    }

    final chips = [
      buildChip(null, 'All', Icons.filter_alt),
      buildChip(
        AppointmentStatus.scheduled,
        'Scheduled',
        Icons.event_available,
      ),
      buildChip(
        AppointmentStatus.completed,
        'Completed',
        Icons.check_circle,
      ),
      buildChip(AppointmentStatus.canceled, 'Canceled', Icons.cancel),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isTight = constraints.maxWidth < 520;
            final chipGroup = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips,
            );

            if (isTight) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 8),
                  DefaultTextStyle.merge(
                    style: theme.textTheme.labelSmall,
                    child: chipGroup,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Filter', style: theme.textTheme.labelSmall),
                const SizedBox(width: 16),
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: theme.textTheme.labelSmall,
                    child: chipGroup,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CalendarPromptButton extends StatelessWidget {
  const _CalendarPromptButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: const Icon(Icons.calendar_month),
        label: const Text('Open calendar'),
      ),
    );
  }
}

class _ScheduleListView extends StatelessWidget {
  const _ScheduleListView({required this.controller});

  final AppointmentScheduleController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null) {
      return _ErrorState(
        message: controller.errorMessage!,
        onRetry: controller.refresh,
      );
    }
    if (controller.filteredAppointments.isEmpty) {
      return const _EmptyState();
    }

    final appointments = _sortedAppointments(controller);

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _AppointmentCard(
          appointment: appointment,
          onTap: () {
            final state = context
                .findAncestorStateOfType<_AppointmentSchedulePageState>();
            state?._openEditor(context, appointment: appointment);
          },
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: appointments.length,
    );
  }
}

List<Appointment> _sortedAppointments(
  AppointmentScheduleController controller,
) {
  final appointments = [...controller.filteredAppointments]
    ..sort((a, b) => a.start.compareTo(b.start));
  return appointments;
}

class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.controller});

  final AppointmentScheduleController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = controller.daySummary;
    final scheduledDuration = Duration(minutes: summary.bookedMinutes);
    final durationLabel = _formatDuration(scheduledDuration);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final spacing = 12.0;
        final columns = maxWidth >= 840
            ? 4
            : maxWidth >= 480
            ? 2
            : 1;
        final tileWidth = (maxWidth - spacing * (columns - 1)) / columns;
        final children = [
          _SummaryTile(
            icon: Icons.event_available,
            label: 'Scheduled',
            value: summary.scheduledCount.toString(),
            color: theme.colorScheme.primary,
          ),
          _SummaryTile(
            icon: Icons.check_circle,
            label: 'Completed',
            value: summary.completedCount.toString(),
            color: theme.colorScheme.secondary,
          ),
          _SummaryTile(
            icon: Icons.cancel,
            label: 'Canceled',
            value: summary.canceledCount.toString(),
            color: theme.colorScheme.error,
          ),
          _SummaryTile(
            icon: Icons.access_time,
            label: 'Booked time',
            value: durationLabel,
            color: theme.colorScheme.tertiary,
          ),
        ];
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((tile) => SizedBox(width: tileWidth, child: tile))
              .toList(growable: false),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) {
        return '$hours h';
      }
      return '${hours}h ${minutes}m';
    }
    return '${duration.inMinutes}m';
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyCalendar extends StatefulWidget {
  const _MonthlyCalendar({required this.controller, this.onDateSelected});

  final AppointmentScheduleController controller;
  final VoidCallback? onDateSelected;

  @override
  State<_MonthlyCalendar> createState() => _MonthlyCalendarState();
}

class _MonthlyCalendarState extends State<_MonthlyCalendar> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _visibleMonth = _monthFor(widget.controller.selectedDate);
  }

  @override
  void didUpdateWidget(covariant _MonthlyCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedMonth = _monthFor(widget.controller.selectedDate);
    if (!_isSameMonth(selectedMonth, _visibleMonth)) {
      _visibleMonth = selectedMonth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDayOfMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final leadingEmptyDays =
        (firstDayOfMonth.weekday + 6) % 7; // Monday as first weekday

    final totalCells = leadingEmptyDays + daysInMonth;
    final trailingEmptyDays = (totalCells % 7) == 0 ? 0 : 7 - (totalCells % 7);

    final cells = <DateTime?>[];
    for (var i = 0; i < leadingEmptyDays; i++) {
      cells.add(null);
    }
    for (var day = 1; day <= daysInMonth; day++) {
      cells.add(DateTime(_visibleMonth.year, _visibleMonth.month, day));
    }
    for (var i = 0; i < trailingEmptyDays; i++) {
      cells.add(null);
    }

    final monthLabel = _monthName(_visibleMonth.month);

    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final isLandscape = media.orientation == Orientation.landscape;
        final maxWidth = constraints.maxWidth;
        final horizontalPadding = isLandscape ? 12.0 : 16.0;
        final titlePadding = isLandscape
            ? const EdgeInsets.symmetric(horizontal: 8)
            : EdgeInsets.zero;
        final gridPadding = EdgeInsets.symmetric(
          horizontal: isLandscape ? 4 : 0,
        );
        final daySpacing = isLandscape ? 4.0 : 8.0;
        final dayPadding = isLandscape
            ? const EdgeInsets.symmetric(vertical: 6)
            : const EdgeInsets.symmetric(vertical: 8);
        final fontScale = isLandscape ? 0.9 : 1.0;

        return Card(
          child: Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: titlePadding,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(() {
                          _visibleMonth = DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month - 1,
                          );
                        }),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '$monthLabel ${_visibleMonth.year}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setState(() {
                          _visibleMonth = DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month + 1,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isLandscape ? 8 : 12),
                Padding(
                  padding: gridPadding,
                  child: GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: daySpacing,
                    crossAxisSpacing: daySpacing,
                    childAspectRatio: maxWidth > 700 ? 1.4 : 1.1,
                    children: [
                      for (final label in const [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ])
                        Center(
                          child: Text(
                            label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12 * fontScale,
                            ),
                          ),
                        ),
                      for (final date in cells)
                        _DayCell(
                          date: date,
                          controller: widget.controller,
                          isInCurrentMonth:
                              date != null && date.month == _visibleMonth.month,
                          padding: dayPadding,
                          fontScale: fontScale,
                          onSelected: widget.onDateSelected,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  DateTime _monthFor(DateTime date) => DateTime(date.year, date.month, 1);

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[(month - 1) % names.length];
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.controller,
    required this.isInCurrentMonth,
    required this.padding,
    required this.fontScale,
    this.onSelected,
  });

  final DateTime? date;
  final AppointmentScheduleController controller;
  final bool isInCurrentMonth;
  final EdgeInsets padding;
  final double fontScale;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isSelected = DateUtils.isSameDay(date, controller.selectedDate);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final foregroundColor = isSelected
        ? theme.colorScheme.onPrimary
        : isInCurrentMonth
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;
    final backgroundColor = isSelected ? theme.colorScheme.primary : null;
    final borderColor = isToday && !isSelected
        ? theme.colorScheme.primary
        : null;

    return GestureDetector(
      onTap: () {
        controller.setSelectedDate(date!);
        onSelected?.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        alignment: Alignment.center,
        padding: padding,
        child: Text(
          '${date!.day}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: foregroundColor,
            fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * fontScale,
          ),
        ),
      ),
    );
  }
}

class _NextAppointmentSection extends StatelessWidget {
  const _NextAppointmentSection({required this.controller});

  final AppointmentScheduleController controller;

  @override
  Widget build(BuildContext context) {
    final next = controller.nextAppointment;
    if (next == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final timeLabel = TimeOfDay.fromDateTime(next.start).format(context);
    final durationLabel = '${next.durationMinutes} min';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.schedule, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Next appointment', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(next.patientName, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '$timeLabel · $durationLabel',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(next.purpose, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () {
                final state = context
                    .findAncestorStateOfType<_AppointmentSchedulePageState>();
                state?._openEditor(context, appointment: next);
              },
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentSchedulePageState extends State<AppointmentSchedulePage> {
  @override
  void initState() {
    super.initState();
    final scheduleController = Provider.of<AppointmentScheduleController>(
      context,
      listen: false,
    );
    final patientController = Provider.of<PatientDirectoryController>(
      context,
      listen: false,
    );
    scheduleController.initialize();
    patientController.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleController = context.watch<AppointmentScheduleController>();
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.clinicianName}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: UserAvatar(
              displayName: widget.clinicianName,
              photoUrl: widget.clinicianPhotoUrl,
              onTap: widget.onAvatarTap,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Calendar',
            onPressed: () => _openCalendarView(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: scheduleController.refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Add appointment'),
      ),
      body: SafeArea(
        child: isLandscape
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CalendarPromptButton(
                              onPressed: () => _openCalendarView(context),
                            ),
                            const SizedBox(height: 16),
                            _DailySummary(controller: scheduleController),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StatusFilter(controller: scheduleController),
                          const SizedBox(height: 16),
                          _NextAppointmentSection(
                            controller: scheduleController,
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _ScheduleListView(
                              controller: scheduleController,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _CalendarPromptButton(
                          onPressed: () => _openCalendarView(context),
                        ),
                        const SizedBox(height: 16),
                        _StatusFilter(controller: scheduleController),
                        const SizedBox(height: 16),
                        _DailySummary(controller: scheduleController),
                        const SizedBox(height: 16),
                        _NextAppointmentSection(controller: scheduleController),
                      ]),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    sliver: _ScheduleSliver(controller: scheduleController),
                  ),
                ],
              ),
      ),
    );
  }

  void _openCalendarView(BuildContext context) {
    final controller = context.read<AppointmentScheduleController>();
    final media = MediaQuery.of(context);
    final isLarge = media.size.shortestSide >= 600;

    if (isLarge) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => _CalendarPage(controller: controller),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          final inset = MediaQuery.of(sheetContext).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: inset),
            child: _CalendarSheet(controller: controller),
          );
        },
      );
    }
  }

  Future<void> _openEditor(
    BuildContext context, {
    Appointment? appointment,
  }) async {
    final scheduleController = Provider.of<AppointmentScheduleController>(
      context,
      listen: false,
    );
    final patientController = Provider.of<PatientDirectoryController>(
      context,
      listen: false,
    );

    if (patientController.patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least one patient before booking appointments.',
          ),
        ),
      );
      return;
    }

    final result = await AppointmentEditorDialog.show(
      context,
      delegate: AppointmentEditorDelegate(existingAppointment: appointment),
      patientController: patientController,
    );

    if (result == null) {
      return;
    }

    try {
      if (appointment == null) {
        await scheduleController.createAppointment(
          patient: result.patient,
          date: result.date,
          time: result.time,
          durationMinutes: result.durationMinutes,
          purpose: result.purpose,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Appointment booked')));
        }
      } else {
        final action = result.action;
        if (action == AppointmentEditorAction.cancel) {
          await scheduleController.cancelAppointment(appointment);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Appointment canceled')),
            );
          }
        } else if (action == AppointmentEditorAction.complete) {
          await scheduleController.markAppointmentCompleted(appointment);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Marked as completed')),
            );
          }
        } else {
          await scheduleController.updateAppointment(
            appointment: appointment,
            patient: result.patient,
            date: result.date,
            time: result.time,
            durationMinutes: result.durationMinutes,
            purpose: result.purpose,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Appointment updated')),
            );
          }
        }
      }
    } on StateError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Operation failed: $error')));
    }
  }
}

class _ScheduleSliver extends StatelessWidget {
  const _ScheduleSliver({required this.controller});

  final AppointmentScheduleController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorState(
          message: controller.errorMessage!,
          onRetry: controller.refresh,
        ),
      );
    }
    if (controller.filteredAppointments.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(),
      );
    }

    final appointments = _sortedAppointments(controller);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final appointment = appointments[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == appointments.length - 1 ? 0 : 12,
          ),
          child: _AppointmentCard(
            appointment: appointment,
            onTap: () {
              final state = context
                  .findAncestorStateOfType<_AppointmentSchedulePageState>();
              state?._openEditor(context, appointment: appointment);
            },
          ),
        );
      }, childCount: appointments.length),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, required this.onTap});

  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startTime = TimeOfDay.fromDateTime(appointment.start).format(context);
    final endTime = TimeOfDay.fromDateTime(appointment.end).format(context);
    final statusLabel = appointment.status.value;
    final statusColor = _statusColor(theme.colorScheme, appointment.status);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      appointment.patientName,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('$startTime - $endTime', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(appointment.purpose, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ColorScheme colorScheme, AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return colorScheme.primary;
      case AppointmentStatus.completed:
        return colorScheme.secondary;
      case AppointmentStatus.canceled:
        return colorScheme.error;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy, size: 48),
          const SizedBox(height: 12),
          Text('No appointments scheduled', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to book your first appointment for the day.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text('Something went wrong', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
