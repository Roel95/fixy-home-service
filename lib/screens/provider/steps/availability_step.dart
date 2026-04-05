import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/provider_onboarding_provider.dart';
import 'package:fixy_home_service/models/provider_model.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class AvailabilityStep extends StatelessWidget {
  const AvailabilityStep({Key? key}) : super(key: key);

  static const Map<String, String> dayNames = {
    'monday': 'Lunes',
    'tuesday': 'Martes',
    'wednesday': 'Miércoles',
    'thursday': 'Jueves',
    'friday': 'Viernes',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderOnboardingProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Disponibilidad', style: AppTheme.textTheme.displayLarge),
          const SizedBox(height: 8),
          Text(
            'Configura tu horario de trabajo semanal',
            style: AppTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayNames.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final dayKey = dayNames.keys.elementAt(index);
              final dayName = dayNames[dayKey]!;
              final dayAvailability =
                  provider.availability.weekSchedule[dayKey] ??
                      DayAvailability(
                          isAvailable: false,
                          timeFrom: '09:00',
                          timeTo: '18:00');

              return _DayAvailabilityCard(
                dayKey: dayKey,
                dayName: dayName,
                availability: dayAvailability,
                onChanged: (newAvailability) {
                  provider.updateDayAvailability(dayKey, newAvailability);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayAvailabilityCard extends StatelessWidget {
  final String dayKey;
  final String dayName;
  final DayAvailability availability;
  final Function(DayAvailability) onChanged;

  const _DayAvailabilityCard({
    Key? key,
    required this.dayKey,
    required this.dayName,
    required this.availability,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: availability.isAvailable
                ? AppTheme.primaryColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dayName, style: AppTheme.textTheme.titleMedium),
              Switch(
                value: availability.isAvailable,
                onChanged: (value) {
                  onChanged(availability.copyWith(isAvailable: value));
                },
                activeThumbColor: AppTheme.primaryColor,
              ),
            ],
          ),
          if (availability.isAvailable) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Desde',
                    time: availability.timeFrom,
                    onTimeSelected: (time) {
                      onChanged(availability.copyWith(timeFrom: time));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePicker(
                    label: 'Hasta',
                    time: availability.timeTo,
                    onTimeSelected: (time) {
                      onChanged(availability.copyWith(timeTo: time));
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final String time;
  final Function(String) onTimeSelected;

  const _TimePicker({
    Key? key,
    required this.label,
    required this.time,
    required this.onTimeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectTime(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.textTheme.bodySmall
                  ?.copyWith(color: AppTheme.textLight),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(time, style: AppTheme.textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final parts = time.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onTimeSelected(formattedTime);
    }
  }
}
