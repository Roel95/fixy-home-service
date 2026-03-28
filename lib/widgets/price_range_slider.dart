import 'package:flutter/material.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class PriceRangeSlider extends StatelessWidget {
  final double minValue;
  final double maxValue;
  final RangeValues currentRange;
  final Function(RangeValues) onChanged;
  final String currency;

  const PriceRangeSlider({
    Key? key,
    required this.minValue,
    required this.maxValue,
    required this.currentRange,
    required this.onChanged,
    this.currency = 'S/',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rango de Precio',
              style: AppTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$currency${currentRange.start.toInt()} - $currency${currentRange.end.toInt()}/${_getTimeUnit()}',
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 8,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 16,
            ),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
            trackHeight: 4,
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: Colors.grey[300],
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.2),
          ),
          child: RangeSlider(
            values: currentRange,
            min: minValue,
            max: maxValue,
            divisions: (maxValue - minValue).toInt(),
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$currency${minValue.toInt()}',
              style: AppTheme.textTheme.bodySmall,
            ),
            Text(
              '$currency${maxValue.toInt()}',
              style: AppTheme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  String _getTimeUnit() {
    return 'hr'; // Default time unit
  }
}
