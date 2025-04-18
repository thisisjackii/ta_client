import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/tooltip/tooltip.dart';
import 'package:another_xlider/models/tooltip/tooltip_box.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:flutter/material.dart';

class CustomSliderDoubleRange extends StatelessWidget {
  const CustomSliderDoubleRange({
    required this.yourRatioValue,
    required this.id,
    super.key,
  });

  final double yourRatioValue;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rentang Bulan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Bottom Slider: Visual Range
              FlutterSlider(
                values: const [3, 6],
                rangeSlider: true,
                max: 7,
                min: 2,
                disabled: true,
                handler: FlutterSliderHandler(
                  decoration: const BoxDecoration(),
                  child: const Icon(Icons.circle, color: Colors.transparent),
                ),
                rightHandler: FlutterSliderHandler(
                  decoration: const BoxDecoration(),
                  child: const Icon(Icons.circle, color: Colors.transparent),
                ),
                trackBar: FlutterSliderTrackBar(
                  activeTrackBarHeight: 12,
                  inactiveTrackBarHeight: 12,
                  inactiveTrackBar: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeTrackBar: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.green, Colors.orange],
                      stops: [0.05, 0.5, 0.95],
                    ),
                  ),
                ),
                tooltip: FlutterSliderTooltip(
                  alwaysShowTooltip: true,
                  textStyle: const TextStyle(color: Colors.black),
                  boxStyle: FlutterSliderTooltipBox(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  custom: (dynamic value) {
                    final intValue = int.parse(value.toString().split('.')[0]);
                    return Text('$intValue Bulan');
                  },
                ),
              ),

              // Top Slider: White handler with tooltip, based on yourRatioValue
              FlutterSlider(
                values: [yourRatioValue],
                max: 7,
                min: 2,
                disabled: true,
                handlerHeight: 32,
                handlerWidth: 32,
                handler: FlutterSliderHandler(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.black26),
                  ),
                  child:
                      const Icon(Icons.circle, color: Colors.white, size: 10),
                ),
                tooltip: FlutterSliderTooltip(
                  alwaysShowTooltip: true,
                  textStyle: const TextStyle(color: Colors.black),
                  boxStyle: FlutterSliderTooltipBox(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  custom: (dynamic value) {
                    final intValue = int.parse(value.toString().split('.')[0]);
                    return Text('$intValue Bulan');
                  },
                ),
                trackBar: const FlutterSliderTrackBar(
                  activeTrackBarHeight: 1,
                  inactiveTrackBarHeight: 1,
                  activeTrackBar: BoxDecoration(color: Colors.transparent),
                  inactiveTrackBar: BoxDecoration(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Nilai ideal berada antara 3 sampai 6 bulan. '
          'Rasio kamu berada di posisi saat ini berdasarkan perhitungan.',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
