// lib/features/evaluation/view/widgets/custom_slider_double_range.dart
import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/tooltip/tooltip.dart';
import 'package:another_xlider/models/tooltip/tooltip_box.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_bloc.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_state.dart';

class CustomSliderDoubleRange extends StatelessWidget {
  const CustomSliderDoubleRange({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rentang Bulan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimensions.padding),
        SizedBox(
          height: 80,
          child: BlocBuilder<EvaluationBloc, EvaluationState>(
            builder: (context, state) {
              final raw = state.detailItem?.yourValue ?? 0.0;
              const min = 2.0;
              const lowerIdeal = 3.0;
              const upperIdeal = 6.0;
              const max = 7.0;
              // clamp so slider thumb never goes off-track
              final displayValue = raw.clamp(min, max);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  FlutterSlider(
                    values: [displayValue],
                    min: min,
                    max: max,
                    disabled: true,
                    jump: true,
                    trackBar: FlutterSliderTrackBar(
                      inactiveTrackBarHeight: 12,
                      activeTrackBarHeight: 12,
                      inactiveTrackBar: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.redAccent, // before lowerIdeal
                            Colors.green, // between lowerIdeal and upperIdeal
                            Colors.grey, // after upperIdeal
                          ],
                          stops: [
                            (lowerIdeal - min) / (max - min),
                            (upperIdeal - min) / (max - min),
                            1.0,
                          ],
                        ),
                      ),
                    ),
                    handler: FlutterSliderHandler(
                      decoration: const BoxDecoration(),
                      child: const Icon(Icons.circle, color: Colors.grey),
                    ),
                    tooltip: FlutterSliderTooltip(
                      alwaysShowTooltip: true,
                      format: (v) {
                        // v may be int or double underneath, so toString safely
                        final dv = double.tryParse(v) ?? 0.0;
                        return '${dv.toStringAsFixed(1).split('.')[0]} bulan';
                      },
                      textStyle: const TextStyle(color: Colors.black),
                      boxStyle: FlutterSliderTooltipBox(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // ideal labels
                  Positioned(
                    top: 50,
                    left:
                        ((lowerIdeal - min) / (max - min)) *
                        (MediaQuery.of(context).size.width -
                            2 * AppDimensions.padding),
                    child: const Text(
                      '3 Bulan',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    left:
                        ((upperIdeal - min) / (max - min)) *
                        (MediaQuery.of(context).size.width -
                            2 * AppDimensions.padding),
                    child: const Text(
                      '6 Bulan',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppDimensions.padding),
        const Text(
          'Nilai ideal berada antara 3 sampai 6 bulan. '
          'Rasio kamu berada di posisi saat ini berdasarkan perhitungan.',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
