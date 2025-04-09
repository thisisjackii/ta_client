import 'package:flutter/material.dart';
import 'package:ta_client/features/filter/view/widgets/filter_form_page.dart';

class FilterPage extends StatelessWidget {
  const FilterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffFBFDFF),
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
      body: const FilterFormPage(),
    );
  }
}
