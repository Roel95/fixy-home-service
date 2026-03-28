import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/profile_models.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:intl/intl.dart';

class RescheduleServiceDialog extends StatefulWidget {
  final ServiceHistory service;
  final Function(DateTime, String) onReschedule;

  const RescheduleServiceDialog({
    Key? key,
    required this.service,
    required this.onReschedule,
  }) : super(key: key);

  @override
  State<RescheduleServiceDialog> createState() =>
      _RescheduleServiceDialogState();
}

class _RescheduleServiceDialogState extends State<RescheduleServiceDialog> {
  late DateTime _selectedDate;
  String _selectedTime = '';
  final List<String> _availableTimes = [
    '08:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '12:00 PM - 02:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.service.date;
    _selectedTime = widget.service.time;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reprogramar Servicio',
              style: AppTheme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.service.serviceName,
              style: AppTheme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),

            // Date selection
            Text(
              'Selecciona una nueva fecha',
              style: AppTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: AppTheme.textTheme.bodyLarge,
                    ),
                    const Icon(Icons.calendar_today,
                        color: AppTheme.primaryColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Time selection
            Text(
              'Selecciona un nuevo horario',
              style: AppTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _availableTimes.length,
                itemBuilder: (context, index) {
                  final time = _availableTimes[index];
                  final isSelected = time == _selectedTime;

                  return RadioListTile<String>(
                    title: Text(time),
                    value: time,
                    groupValue: _selectedTime,
                    onChanged: (value) {
                      setState(() {
                        _selectedTime = value!;
                      });
                    },
                    activeColor: AppTheme.primaryColor,
                    dense: true,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onReschedule(_selectedDate, _selectedTime);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = now.add(const Duration(days: 1));
    final lastDate = now.add(const Duration(days: 30));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate.isBefore(firstDate) ? firstDate : _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}
