// dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:ta_client/features/dashboard/bloc/dashboard_event.dart';
import 'package:ta_client/features/dashboard/bloc/dashboard_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  /// Creates a [DashboardPage] and wraps it in a [BlocProvider] that provides
  /// a [DashboardBloc].
  ///
  /// This is a convenience method for creating a [DashboardPage] with a
  /// [DashboardBloc] provider. It is intended to be used as a root widget in
  /// a Flutter application.
  static Widget create() {
    return BlocProvider(
      create: (context) => DashboardBloc(),
      child: const DashboardPage(),
    );
  }

  /// Builds the widget tree for the [DashboardPage].
  ///
  /// This method creates a [Scaffold] with an [AppBar] and a [BlocBuilder]
  /// that listens to the [DashboardBloc] state. Depending on the state,
  /// it displays:
  /// - A loading indicator if the state is [DashboardLoading].
  /// - A list of dashboard items if the state is [DashboardLoaded].
  /// - An error message and a retry button if the state is [DashboardError].
  /// - A fallback text if the state is unexpected.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DashboardLoaded) {
            return ListView.builder(
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return ListTile(
                  title: Text(item.title),
                  subtitle: Text(item.description),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => context
                        .read<DashboardBloc>()
                        .add(DashboardItemDeleted(item)),
                  ),
                );
              },
            );
          } else if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<DashboardBloc>()
                        .add(DashboardReloadRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('Unexpected state'));
          }
        },
      ),
    );
  }
}
