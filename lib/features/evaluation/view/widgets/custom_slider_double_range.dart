import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/tooltip/tooltip.dart';
import 'package:another_xlider/models/tooltip/tooltip_box.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:flutter/material.dart';

class CustomSliderDoubleRange extends StatelessWidget {

  const CustomSliderDoubleRange({
    required this.yourRatioValue, required this.id, super.key,
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
        Stack(
          alignment: Alignment.topCenter,
          children: [
            FlutterSlider(
              key: ValueKey('slider_${id}_$yourRatioValue'),
              values: [yourRatioValue],
              max: 7,
              min: 2,
              jump: true,
              handler: FlutterSliderHandler(
                decoration: const BoxDecoration(),
                child: const Icon(Icons.circle, color: Colors.grey),
              ),
              trackBar: FlutterSliderTrackBar(
                inactiveTrackBarHeight: 12,
                activeTrackBarHeight: 12,
                inactiveTrackBar: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.redAccent,
                      Colors.green,
                      Colors.grey,
                    ],
                    stops: [0.2, 0.7, 1.0],
                  ),
                ),
              ),
              tooltip: FlutterSliderTooltip(
                alwaysShowTooltip: true,
                format: (value) => '${value.split('.')[0]} bulan',
                textStyle: const TextStyle(color: Colors.black),
                boxStyle: FlutterSliderTooltipBox(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              disabled: true,
            ),
            const Positioned(
              top: 42,
              left: 48,
              child: Text('3 Bulan', style: TextStyle(fontSize: 12)),
            ),
            const Positioned(
              top: 42,
              right: 48,
              child: Text('6 Bulan', style: TextStyle(fontSize: 12)),
            ),
          ],
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
