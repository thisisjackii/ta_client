//lib/features/evaluation/view/widgets/evaluation_detail_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_bloc.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_state.dart';

class StatExpandableCard extends StatelessWidget {
  const StatExpandableCard({
    required this.title,
    required this.icon,
    required this.valuesAboveDivider,
    required this.valuesBelowDivider,
    super.key,
  });
  final String title;
  final IconData icon;
  final List<Map<String, String>> valuesAboveDivider;
  final List<Map<String, String>> valuesBelowDivider;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EvaluationBloc, EvaluationState>(
      builder: (c, s) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          ),
          child: ExpansionTile(
            leading: Icon(icon),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            children: [
              ...valuesAboveDivider.map(
                (e) => ListTile(
                  title: Text(e['label']!),
                  trailing: Text(e['value']!),
                ),
              ),
              const Divider(),
              ...valuesBelowDivider.map(
                (e) => ListTile(
                  title: Text(e['label']!),
                  trailing: Text(e['value']!),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
