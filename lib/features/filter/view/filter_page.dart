import 'package:flutter/material.dart';
import 'package:ta_client/features/filter/view/widgets/filter_form_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          ],
        ),
        actions: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.info), onPressed: () {}),
              IconButton(
                icon: const Icon(Icons.bookmark_add), onPressed: () {},),
            ],
          ),
        ],
      ),
      body: FilterFormPage()
    );
  }
}
