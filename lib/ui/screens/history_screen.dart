import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../services/firestore_service.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService = ref.read(firestoreServiceProvider);
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: user == null
          ? const SizedBox.shrink()
          : FutureBuilder<UserGameProfile>(
              future: firestoreService.getUserProfile(user),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SpinKitFadingCircle(
                      color: colorScheme.primary,
                      size: 60.0,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text(l10n.historyError));
                }

                final profile = snapshot.data ?? const UserGameProfile(score: 0, solvedNumbers: []);
                final solved = profile.solvedNumbers;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        color: colorScheme.primaryContainer,
                        child: ListTile(
                          leading: const Icon(Icons.emoji_events, color: Colors.amber, size: 36),
                          title: Text(
                            user.displayName?.isNotEmpty == true
                                ? user.displayName!
                                : (user.email ?? 'Jogador'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${l10n.scoreLabel}: ${profile.score} pts'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: solved.isEmpty
                          ? Center(child: Text(l10n.historyEmpty))
                          : ListView.builder(
                              itemCount: solved.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                                  title: Text('${l10n.resolvedNumber}: ${solved[index]}'),
                                  subtitle: Text('${l10n.recordLabel} #${index + 1}'),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}