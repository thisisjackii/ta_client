import 'package:flutter/material.dart';
import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/slider_step.dart';
import 'package:another_xlider/models/tooltip/tooltip.dart';
import 'package:another_xlider/models/tooltip/tooltip_box.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:ta_client/features/evaluation/view/widgets/slider_limit_type.dart';

class CustomSliderSingleRange extends StatelessWidget {
  final double yourRatio;
  final double limit;
  final SliderLimitType limitType;

  const CustomSliderSingleRange({
    super.key,
    required this.yourRatio,
    required this.limit,
    required this.limitType,
  });

  @override
  Widget build(BuildContext context) {
    // Determine min and max to center the ideal limit
    double range = 30; // Half the range to extend left and right
    double min = (limit - range).clamp(0, double.infinity);
    double max = limit + range;

    double clampedRatio = yourRatio.clamp(min, max);

    // Determine if user's ratio is ideal
    bool isIdeal = switch (limitType) {
      SliderLimitType.lessThan => yourRatio < limit,
      SliderLimitType.lessThanEqual => yourRatio <= limit,
      SliderLimitType.moreThan => yourRatio > limit,
      SliderLimitType.moreThanEqual => yourRatio >= limit,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evaluasi Rasio',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Slider
        FlutterSlider(
          key: ValueKey('single_slider_$yourRatio'),
          values: [clampedRatio],
          min: min,
          max: max,
          step: FlutterSliderStep(step: 1),
          jump: true,
          disabled: true,
          handler: FlutterSliderHandler(
            decoration: const BoxDecoration(),
            child: Icon(
              Icons.circle,
              color: isIdeal ? Colors.green : Colors.red,
            ),
          ),
          trackBar: FlutterSliderTrackBar(
            inactiveTrackBarHeight: 12,
            activeTrackBarHeight: 12,
            inactiveTrackBar: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[300],
            ),
            activeTrackBar: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isIdeal ? Colors.green : Colors.redAccent,
            ),
          ),
          tooltip: FlutterSliderTooltip(
            alwaysShowTooltip: true,
            format: (_) => '${yourRatio.toStringAsFixed(0)}%',
            textStyle: const TextStyle(color: Colors.black),
            boxStyle: FlutterSliderTooltipBox(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${min.toInt()}%', style: const TextStyle(fontSize: 12)),
            Text('${limit.toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text('${max.toInt()}%', style: const TextStyle(fontSize: 12)),
          ],
        ),

        const SizedBox(height: 16),
        Text(
          'Nilai ideal adalah ${_limitTypeLabel(limitType)} $limit%. Rasio kamu saat ini adalah $yourRatio%.',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  String _limitTypeLabel(SliderLimitType type) {
    switch (type) {
      case SliderLimitType.lessThan:
        return 'kurang dari';
      case SliderLimitType.lessThanEqual:
        return 'kurang dari atau sama dengan';
      case SliderLimitType.moreThan:
        return 'lebih dari';
      case SliderLimitType.moreThanEqual:
        return 'lebih dari atau sama dengan';
    }
  }
}


