// C:\Users\PONGO\RemoteProjects\ta_client\lib\features\evaluation\view\widgets\custom_slider_single_range.dart
// For min/max
import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/enums/hatch_mark_alignment_enum.dart';
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/hatch_mark.dart';
import 'package:another_xlider/models/hatch_mark_label.dart';
import 'package:another_xlider/models/tooltip/tooltip.dart';
import 'package:another_xlider/models/tooltip/tooltip_box.dart';
import 'package:another_xlider/models/tooltip/tooltip_position_offset.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:flutter/material.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/evaluation/view/widgets/slider_limit_type.dart';

class CustomSliderSingleRange extends StatelessWidget {
  const CustomSliderSingleRange({
    required this.currentValue,
    required this.idealText,
    required this.limit,
    required this.limitType,
    this.isMonthValue = false,
    super.key,
  });

  final double currentValue;
  final String idealText;
  final double limit; // The ideal target/threshold point
  final SliderLimitType limitType;
  final bool isMonthValue;

  @override
  Widget build(BuildContext context) {
    final v = currentValue; // The actual value of the ratio

    // --- Define the VISIBLE fixed track and its labels ---
    double visibleTrackMin;
    double visibleTrackMax;
    final hatchMarkLabels = <FlutterSliderHatchMarkLabel>[];

    if (isMonthValue) {
      visibleTrackMin = 0.0;
      visibleTrackMax =
          12.0; // Example: standard visible track for months up to 1 year

      // Labels for month track
      hatchMarkLabels.add(
        FlutterSliderHatchMarkLabel(
          percent: 0,
          label: Text(
            formatMonths(visibleTrackMin),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      );
      if (limit >= visibleTrackMin &&
          limit <= visibleTrackMax &&
          limit != visibleTrackMin &&
          limit != visibleTrackMax) {
        hatchMarkLabels.add(
          FlutterSliderHatchMarkLabel(
            percent:
                (limit - visibleTrackMin) /
                (visibleTrackMax - visibleTrackMin) *
                100,
            label: Text(
              formatMonths(limit),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        );
      }
      hatchMarkLabels.add(
        FlutterSliderHatchMarkLabel(
          percent: 100,
          label: Text(
            formatMonths(visibleTrackMax),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      );
    } else {
      // Percentage based
      visibleTrackMin = 0.0;
      visibleTrackMax = 100.0;

      // Labels for percentage track
      hatchMarkLabels.add(
        FlutterSliderHatchMarkLabel(
          percent: 0,
          label: Text(
            formatPercent(visibleTrackMin),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      );
      if (limit > visibleTrackMin && limit < visibleTrackMax) {
        // Show limit if it's between 0 and 100 and not an edge
        hatchMarkLabels.add(
          FlutterSliderHatchMarkLabel(
            percent: limit,
            label: Text(
              formatPercent(limit),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        );
      }
      hatchMarkLabels.add(
        FlutterSliderHatchMarkLabel(
          percent: 100,
          label: Text(
            formatPercent(visibleTrackMax),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      );
    }

    // --- Determine the SLIDER's actual min/max to accommodate the thumb for currentValue ---
    // The slider's track will be drawn from sliderMin to sliderMax.
    // The hatchMarkLabels percent is relative to THIS sliderMin/Max.
    var internalSliderMin = visibleTrackMin;
    var internalSliderMax = visibleTrackMax;
    const tailPadding =
        5.0; // How much "tail" to show visually if value is outside visible track

    if (v < visibleTrackMin) {
      internalSliderMin = v - tailPadding;
    }
    if (v > visibleTrackMax) {
      internalSliderMax = v + tailPadding;
    }
    // Ensure there's always some range and min < max
    if (internalSliderMin >= internalSliderMax) {
      internalSliderMax = internalSliderMin + 10;
    }

    // Recalculate hatch mark label percentages based on the new internalSliderMin/Max
    final finalHatchMarkLabels = <FlutterSliderHatchMarkLabel>[];
    if (isMonthValue) {
      // 0 Months Label
      if (visibleTrackMin >= internalSliderMin &&
          visibleTrackMin <= internalSliderMax) {
        finalHatchMarkLabels.add(
          FlutterSliderHatchMarkLabel(
            percent:
                (visibleTrackMin - internalSliderMin) /
                (internalSliderMax - internalSliderMin) *
                100,
            label: Text(
              formatMonths(visibleTrackMin),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        );
      }
      // Limit Label
      if (limit >= internalSliderMin &&
          limit <= internalSliderMax &&
          limit != visibleTrackMin &&
          limit != visibleTrackMax) {
        finalHatchMarkLabels.add(
          FlutterSliderHatchMarkLabel(
            percent:
                (limit - internalSliderMin) /
                (internalSliderMax - internalSliderMin) *
                100,
            label: Text(
              formatMonths(limit),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        );
      }
      // 12 Months Label
      if (visibleTrackMax >= internalSliderMin &&
          visibleTrackMax <= internalSliderMax) {
        finalHatchMarkLabels.add(
          FlutterSliderHatchMarkLabel(
            percent:
                (visibleTrackMax - internalSliderMin) /
                (internalSliderMax - internalSliderMin) *
                100,
            label: Text(
              formatMonths(visibleTrackMax),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        );
      }
    } else {
      // Percentage
      // 0% Label
      if (visibleTrackMin >= internalSliderMin &&
          visibleTrackMin <= internalSliderMax) {
        finalHatchMarkLabels.add(
          FlutterSliderHatchMarkLabel(
            percent:
                (visibleTrackMin - internalSliderMin) /
                (internalSliderMax - internalSliderMin) *
                100,
            label: Text(
              formatPercent(visibleTrackMin),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        );
      }
      // Limit Label
      if (limit > visibleTrackMin &&
          limit < visibleTrackMax &&
          limit >= internalSliderMin &&
          limit <= internalSliderMax) {
        finalHatchMarkLabels.add(
          FlutterSliderHatchMarkLabel(
            percent:
                (limit - internalSliderMin) /
                (internalSliderMax - internalSliderMin) *
                100,
            label: Text(
              formatPercent(limit),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        );
      }
      // 100% Label
      if (visibleTrackMax >= internalSliderMin &&
          visibleTrackMax <= internalSliderMax) {
        finalHatchMarkLabels.add(
          FlutterSliderHatchMarkLabel(
            percent:
                (visibleTrackMax - internalSliderMin) /
                (internalSliderMax - internalSliderMin) *
                100,
            label: Text(
              formatPercent(visibleTrackMax),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        );
      }
    }

    // The value for the slider thumb position. Must be within internalSliderMin/Max.
    final clampedValueForThumb = v.clamp(internalSliderMin, internalSliderMax);

    final isValueIdeal = switch (limitType) {
      SliderLimitType.lessThan => v < limit,
      SliderLimitType.lessThanEqual => v <= limit,
      SliderLimitType.moreThan => v > limit,
      SliderLimitType.moreThanEqual => v >= limit,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evaluasi Rasio',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimensions.padding),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FlutterSlider(
                values: [clampedValueForThumb],
                min: internalSliderMin,
                max: internalSliderMax,
                visibleTouchArea: true,
                disabled: true,
                handlerHeight: 18, // Adjusted
                handlerWidth: 18, // Adjusted
                handler: FlutterSliderHandler(
                  decoration: const BoxDecoration(),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isValueIdeal
                          ? AppColors.ideal
                          : AppColors.notIdeal,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ), // White border for better visibility
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                trackBar: FlutterSliderTrackBar(
                  activeTrackBarHeight: 8, // Adjusted
                  inactiveTrackBarHeight: 8, // Adjusted
                  activeTrackBar: BoxDecoration(
                    borderRadius: BorderRadius.circular(4), // Adjusted
                    color: isValueIdeal
                        ? AppColors.ideal.withOpacity(0.7)
                        : AppColors.notIdeal.withOpacity(0.7),
                  ),
                  inactiveTrackBar: BoxDecoration(
                    borderRadius: BorderRadius.circular(4), // Adjusted
                    color: Colors.grey[300],
                  ),
                  // --- This is where we can try to make the "fixed" part of the track visually distinct ---
                  // We can use 'activeDisabledTrackBarColor' or 'inactiveDisabledTrackBarColor'
                  // or draw custom track. For simplicity, we'll rely on hatch marks for fixed points.
                  // The track will visually extend if internalSliderMin/Max are beyond visibleTrackMin/Max.
                ),
                tooltip: FlutterSliderTooltip(
                  alwaysShowTooltip: true,
                  format: (valstrFromSliderPosition) {
                    return isMonthValue
                        ? formatMonths(v)
                        : formatPercent(v); // Always show original 'v'
                  },
                  textStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  boxStyle: FlutterSliderTooltipBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                  ),
                  positionOffset: FlutterSliderTooltipPositionOffset(top: -30),
                ),
                hatchMark: FlutterSliderHatchMark(
                  displayLines: true,
                  density: 0.5,
                  linesDistanceFromTrackBar: 5,
                  linesAlignment: FlutterSliderHatchMarkAlignment
                      .values[0], // Use 'values' alignment
                  labelsDistanceFromTrackBar: 20,
                  labels: finalHatchMarkLabels,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.padding / 2 + 15),
            Text(
              'Nilai ideal adalah $idealText. Rasio kamu saat ini adalah ${isMonthValue ? formatMonths(v) : formatPercent(v)}.',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}
