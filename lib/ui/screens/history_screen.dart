import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<List<String>> _fetchSolvedHistory(List<String> localSolved) async {
    await Future.delayed(const Duration(seconds: 1));
    return localSolved;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: FutureBuilder<List<String>>(
        future: _fetchSolvedHistory(gameState.solvedNumbers),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SpinKitFadingCircle(
                color: Theme.of(context).colorScheme.primary,
                size: 60.0,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text(l10n.historyError));
          }

          final solved = snapshot.data ?? [];
          if (solved.isEmpty) {
            return Center(child: Text(l10n.historyEmpty));
          }

          return ListView.builder(
            itemCount: solved.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text('${l10n.resolvedNumber}: ${solved[index]}'),
                subtitle: Text('${l10n.recordLabel} #${index + 1}'),
              );
            },
          );
        },
      ),
    );
  }
}