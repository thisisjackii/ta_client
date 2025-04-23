import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/tooltip/tooltip.dart';
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
          height: 60,
          child: BlocBuilder<EvaluationBloc, EvaluationState>(
            builder: (c, s) {
              final value = s.detailItem?.yourValue ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  FlutterSlider(
                    values: const [3, 6],
                    rangeSlider: true,
                    max: 7,
                    min: 2,
                    disabled: true,
                    trackBar: FlutterSliderTrackBar(
                      activeTrackBar: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange,
                            Colors.green,
                            Colors.orange,
                          ],
                        ),
                      ),
                      inactiveTrackBar: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    tooltip: FlutterSliderTooltip(
                      alwaysShowTooltip: true,
                      custom: (v) =>
                          Text(formatMonths(double.parse(v.toString()))),
                    ),
                    handler: FlutterSliderHandler(
                      decoration: const BoxDecoration(),
                      child: Container(),
                    ),
                    rightHandler: FlutterSliderHandler(
                      decoration: const BoxDecoration(),
                      child: Container(),
                    ),
                  ),
                  FlutterSlider(
                    values: [value],
                    max: 7,
                    min: 2,
                    disabled: true,
                    handlerHeight: AppDimensions.handlerSize,
                    handlerWidth: AppDimensions.handlerSize,
                    handler: FlutterSliderHandler(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.black26),
                      ),
                      child: const Icon(
                        Icons.circle,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                    tooltip: FlutterSliderTooltip(
                      alwaysShowTooltip: true,
                      custom: (v) =>
                          Text(formatMonths(double.parse(v.toString()))),
                    ),
                    trackBar: const FlutterSliderTrackBar(
                      activeTrackBar: BoxDecoration(color: Colors.transparent),
                      inactiveTrackBar:
                          BoxDecoration(color: Colors.transparent),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppDimensions.padding),
        const Text(
          'Nilai ideal berada antara 3 sampai 6 bulan. Rasio kamu berada di posisi saat ini berdasarkan perhitungan.',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
