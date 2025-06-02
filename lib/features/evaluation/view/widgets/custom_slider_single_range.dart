// C:\Users\PONGO\RemoteProjects\ta_client\lib\features\evaluation\view\widgets\custom_slider_single_range.dart
import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/hatch_mark.dart';
import 'package:another_xlider/models/tooltip/tooltip.dart';
import 'package:another_xlider/models/tooltip/tooltip_box.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:flutter/material.dart';
// No longer needs BlocBuilder here, it gets data via props
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/utils/calculations.dart'; // For formatPercent, formatMonths
import 'package:ta_client/features/evaluation/view/widgets/slider_limit_type.dart';

class CustomSliderSingleRange extends StatelessWidget {
  const CustomSliderSingleRange({
    required this.currentValue, // Current value of the ratio
    required this.idealText, // Pre-formatted ideal text (e.g., "≥ 10%", "15% - 100%")
    required this.limit, // The significant limit for single-bound sliders (e.g., 3 for Liquidity, 10 for Savings)
    required this.limitType, // e.g., moreThanEqual
    this.isMonthValue =
        false, // True if the value is in months (Liquidity Ratio)
    super.key,
  });

  final double currentValue;
  final String idealText;
  final double limit;
  final SliderLimitType limitType;
  final bool isMonthValue;

  @override
  Widget build(BuildContext context) {
    final v = currentValue; // Use the passed currentValue

    // Determine min/max for the slider track based on the limit and current value
    // Ensure the current value is always visible on the track.
    double sliderMin;
    double sliderMax;
    const padding = 30.0; // How much space to give around the limit/value

    if (isMonthValue) {
      // Special handling for Liquidity Ratio (months)
      sliderMin = 0.0; // Start from 0 months
      sliderMax =
          (v > (limit + padding / 2) ? v : (limit + padding / 2)) +
          padding / 2; // Ensure current value and limit are visible
      sliderMax = sliderMax < 7.0
          ? 7.0
          : sliderMax / 3; // Minimum max of 7 months
    } else {
      // Percentage based
      sliderMin = 0.0; // Percentages usually start from 0
      sliderMax = 100.0 + padding; // Go a bit beyond 100% if value can exceed
      if (v > 100) sliderMax = v + padding; // Adjust if value is very high
      sliderMax = sliderMax > (limit + padding)
          ? sliderMax
          : (limit + padding); // Ensure limit is visible
    }
    // Ensure sliderMin is less than sliderMax, and current value is within these.
    if (sliderMin >= sliderMax) sliderMax = sliderMin + padding;
    final clampedDisplayValue = v.clamp(sliderMin, sliderMax);

    // Determine if current value is ideal based on limit and type
    final bool isValueIdeal = switch (limitType) {
      SliderLimitType.lessThan => v < limit,
      SliderLimitType.lessThanEqual => v <= limit,
      SliderLimitType.moreThan => v > limit,
      SliderLimitType.moreThanEqual => v >= limit,
    };
    // For ranges like "15% - 100%", the 'limit' passed might be 15 and type moreThanEqual.
    // A more complex isIdeal check would be needed if the slider had to represent both ends of a range.
    // For now, assuming single limit comparison.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evaluasi Rasio', // This title is generic for the slider section
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimensions.padding),
        Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                FlutterSlider(
                  // Background track for min/max labels
                  values: [sliderMin, sliderMax],
                  rangeSlider: true,
                  min: sliderMin,
                  max: sliderMax,
                  disabled: true,
                  handler: FlutterSliderHandler(
                    decoration: const BoxDecoration(),
                    child: const Icon(
                      Icons.circle,
                      color: Colors.transparent,
                      size: 0.1,
                    ),
                  ), // Invisible
                  rightHandler: FlutterSliderHandler(
                    decoration: const BoxDecoration(),
                    child: const Icon(
                      Icons.circle,
                      color: Colors.transparent,
                      size: 0.1,
                    ),
                  ), // Invisible
                  trackBar: FlutterSliderTrackBar(
                    activeTrackBarHeight: 12,
                    inactiveTrackBarHeight: 12,
                  ), // Standard track
                ),
                FlutterSlider(
                  // Actual value slider
                  values: [clampedDisplayValue],
                  min: sliderMin,
                  max: sliderMax,
                  disabled: true,
                  handler: FlutterSliderHandler(
                    decoration: const BoxDecoration(),
                    child: Icon(
                      Icons.circle,
                      color: isValueIdeal
                          ? AppColors.ideal
                          : AppColors.notIdeal,
                    ),
                  ),
                  trackBar: FlutterSliderTrackBar(
                    activeTrackBarHeight: 12,
                    inactiveTrackBarHeight: 12,
                    activeTrackBar: BoxDecoration(
                      color: isValueIdeal
                          ? AppColors.ideal
                          : AppColors.notIdeal,
                    ),
                    inactiveTrackBar: BoxDecoration(color: Colors.grey[300]),
                  ),
                  tooltip: FlutterSliderTooltip(
                    alwaysShowTooltip: true,
                    format: (valStr) {
                      final valNum = double.tryParse(valStr) ?? 0.0;
                      return isMonthValue
                          ? formatMonths(valNum)
                          : formatPercent(valNum);
                    },
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                    boxStyle: FlutterSliderTooltipBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                  ),
                  hatchMark: FlutterSliderHatchMark(
                    displayLines: true,
                    density: 0.4,
                    linesDistanceFromTrackBar: 5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isMonthValue
                      ? formatMonths(sliderMin)
                      : formatPercent(sliderMin),
                  style: const TextStyle(fontSize: 10),
                ),
                // Ideal limit text in the middle (if applicable)
                if (!isMonthValue ||
                    limit !=
                        3) // Avoid redundant "3 Bulan" if min is also 3 for liquidity
                  Text(
                    isMonthValue ? formatMonths(limit) : formatPercent(limit),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                Text(
                  isMonthValue
                      ? formatMonths(sliderMax)
                      : formatPercent(sliderMax),
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.padding / 2),
            Text(
              'Nilai ideal adalah $idealText. Rasio kamu saat ini adalah ${isMonthValue ? formatMonths(v) : formatPercent(v)}.',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}
