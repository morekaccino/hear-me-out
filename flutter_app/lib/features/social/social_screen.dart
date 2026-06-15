import 'package:flutter/material.dart';
import 'widgets/leaderboard.dart';
import 'widgets/duel_card.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Social', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            const Leaderboard(
              leagueName: 'Sapphire League',
              endsIn: '2 days',
              entries: [
                LeaderboardEntry(rank: 1, name: 'Alex M.', instrument: 'guitar', xp: 2840),
                LeaderboardEntry(rank: 2, name: 'Jordan K.', instrument: 'piano', xp: 2610),
                LeaderboardEntry(rank: 3, name: 'Riley C.', instrument: 'violin', xp: 2350),
                LeaderboardEntry(rank: 4, name: 'You', instrument: 'guitar', xp: 2120, isCurrentUser: true),
                LeaderboardEntry(rank: 5, name: 'Casey W.', instrument: 'saxophone', xp: 1980),
              ],
            ),
            const SizedBox(height: 16),
            DuelCard(onChallenge: () {}),
          ]),
        ),
      ),
    );
  }
}
