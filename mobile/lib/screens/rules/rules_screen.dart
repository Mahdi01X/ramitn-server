import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Règles du Rami Tunisien')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('🎴 Matériel'),
            Text('• 2 jeux de 52 cartes + 4 jokers (108 cartes)\n• 2 à 4 joueurs'),
            SizedBox(height: 20),

            _SectionTitle('🎯 But du jeu'),
            Text('Se débarrasser de toutes ses cartes en posant des combinaisons valides sur la table.'),
            SizedBox(height: 20),

            _SectionTitle('🃏 Distribution'),
            Text('Chaque joueur reçoit 14 cartes. Le reste forme la pioche. La première carte est retournée pour créer le talon (défausse).'),
            SizedBox(height: 20),

            _SectionTitle('📋 Combinaisons valides'),
            _SubTitle('Suite (Run)'),
            Text('3 cartes ou plus consécutives de la même couleur.\nExemple : 5♥ 6♥ 7♥'),
            SizedBox(height: 8),
            _SubTitle('Brelan / Carré (Set)'),
            Text('3 ou 4 cartes de même rang, de couleurs différentes.\nExemple : 7♥ 7♠ 7♦'),
            SizedBox(height: 20),

            _SectionTitle('🔄 Tour de jeu'),
            Text('1. Piocher : prendre une carte de la pioche OU du talon\n'
                '2. Poser (optionnel) : poser des combinaisons ou compléter des existantes\n'
                '3. Défausser : poser une carte sur le talon'),
            SizedBox(height: 20),

            _SectionTitle('🔓 Ouverture'),
            Text('Pour poser pour la première fois, il faut :\n\n'
                '1. Que la somme des points des combinaisons posées atteigne le seuil minimum (71 points par défaut).\n\n'
                '2. Qu\'au moins une des combinaisons soit une SUITE SANS JOKER (ex: 10♥ J♥ Q♥ K♥).\n\n'
                'Exemple : une suite 10♥ J♥ Q♥ K♥ (40 pts) + un brelan d\'As A♥ A♠ A♦ (33 pts) = 73 pts ≥ 71 ✓'),
            SizedBox(height: 20),

            _SectionTitle('🃏 Jokers'),
            Text('• Un joker remplace n\'importe quelle carte dans une combinaison\n'
                '• Maximum 1 joker par combinaison\n'
                '• Un joker posé peut être récupéré si vous avez la carte qu\'il remplace'),
            SizedBox(height: 20),

            _SectionTitle('📊 Valeurs des cartes'),
            Text('• As : 11 points\n'
                '• 2-10 : valeur faciale\n'
                '• Valet, Dame, Roi : 10 points\n'
                '• Joker : 30 points'),
            SizedBox(height: 20),

            _SectionTitle('🏁 Fin de manche'),
            Text('Quand un joueur n\'a plus de cartes, la manche se termine. Les autres joueurs comptent les points des cartes restant en main.'),
            SizedBox(height: 20),

            _SectionTitle('🏆 Victoire'),
            Text('Après 5 manches (configurable), le joueur avec le score le plus bas gagne !'),
            SizedBox(height: 20),

            _SectionTitle('💡 Astuces'),
            Text('• Double-tapez une carte pour la défausser rapidement\n'
                '• Sélectionnez 3+ cartes puis appuyez sur "Poser" pour créer une combinaison\n'
                '• Pensez à piéger vos adversaires en gardant les cartes qu\'ils cherchent !'),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SubTitle extends StatelessWidget {
  final String text;
  const _SubTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}



