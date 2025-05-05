// lib/features/filter/view/filter_page.dart
import 'package:flutter/material.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/features/filter/view/widgets/filter_form_page.dart';

class FilterPage extends StatelessWidget {
  const FilterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
        {};
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.greyBackground,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Text(
              'Filter',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: FilterFormPage(
        initialCriteria: args['filterCriteria'] as Map<String, dynamic>?,
        initialMonth: args['month'] as DateTime?,
      ),
    );
  }
}
