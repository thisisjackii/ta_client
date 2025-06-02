// lib/features/evaluation/view/widgets/custom_slider_single_range.dart
import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/hatch_mark.dart';
import 'package:another_xlider/models/tooltip/tooltip.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_bloc.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_state.dart';
import 'package:ta_client/features/evaluation/view/widgets/slider_limit_type.dart';

class CustomSliderSingleRange extends StatelessWidget {
  const CustomSliderSingleRange({
    required this.limit,
    required this.limitType,
    super.key,
  });
  final double limit;
  final SliderLimitType limitType;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evaluasi Rasio',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimensions.padding),
        BlocBuilder<EvaluationBloc, EvaluationState>(
          builder: (c, s) {
            final v = s.detailItem?.yourValue ?? 0;
            final min = (limit - 30).clamp(0, double.infinity);
            final max = limit + 30;
            final clamped = v.clamp(min, max);
            final isIdeal = switch (limitType) {
              SliderLimitType.lessThan => v < limit,
              SliderLimitType.lessThanEqual => v <= limit,
              SliderLimitType.moreThan => v > limit,
              SliderLimitType.moreThanEqual => v >= limit,
            };
            return Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    FlutterSlider(
                      values: [min.toDouble(), max],
                      rangeSlider: true,
                      min: min.toDouble(),
                      max: max,
                      disabled: true,
                      handler: FlutterSliderHandler(
                        decoration: const BoxDecoration(),
                        child: const Icon(Icons.circle, color: Colors.grey),
                      ),
                      rightHandler: FlutterSliderHandler(
                        decoration: const BoxDecoration(),
                        child: Icon(Icons.circle, color: Colors.grey[400]),
                      ),
                    ),
                    FlutterSlider(
                      values: [clamped.toDouble()],
                      min: min.toDouble(),
                      max: max,
                      disabled: true,
                      handler: FlutterSliderHandler(
                        decoration: const BoxDecoration(),
                        child: Icon(
                          Icons.circle,
                          color: isIdeal ? AppColors.ideal : AppColors.notIdeal,
                        ),
                      ),
                      trackBar: FlutterSliderTrackBar(
                        activeTrackBar: BoxDecoration(
                          color: isIdeal ? AppColors.ideal : AppColors.notIdeal,
                        ),
                        inactiveTrackBar: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                      ),
                      tooltip: FlutterSliderTooltip(
                        alwaysShowTooltip: true,
                        format: (x) => formatPercent(v),
                      ),
                      hatchMark: FlutterSliderHatchMark(
                        displayLines: true,
                        density: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.smallPadding),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${min.toInt()}%'),
                    Text(
                      '${limit.toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${max.toInt()}%'),
                  ],
                ),
                const SizedBox(height: AppDimensions.padding),
                // Text(
                //   'Nilai ideal adalah ${_label(limitType)} $limit%. Rasio kamu saat ini adalah $v%.',
                //   style: const TextStyle(fontSize: 14),
                // ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _label(SliderLimitType t) {
    switch (t) {
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
