import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    Widget section(String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(body, style: t.bodyMedium?.copyWith(height: 1.45)),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text('CliniFlow',
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Qualifier une recherche clinique et en suivre les démarches.',
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 24),
          section(
            'Ce que couvre l\'application',
            'Recherches impliquant la personne humaine (loi Jardé, RIPH 1, 2 '
                'et 3), essais cliniques de médicaments (règlement '
                '536/2014), investigations de dispositifs médicaux et de '
                'diagnostic in vitro, recherches sur données (méthodologies '
                'de référence CNIL, SNDS, autorisation).',
          ),
          section(
            'Une aide, pas une décision',
            'Les résultats proposés sont indicatifs. La qualification '
                'définitive relève du promoteur ; en cas de doute, '
                'rapprochez-vous de votre DRCI, de votre délégué à la '
                'protection des données ou du CPP saisi. Les délais '
                'indiqués sont des repères et ne remplacent pas les textes.',
          ),
          section(
            'Vos données',
            'Les projets sont enregistrés uniquement sur cet appareil. '
                'CliniFlow n\'utilise aucun compte, aucun serveur et aucun '
                'traceur. Ne saisissez aucune donnée de patient.',
          ),
          section(
            'Référentiel',
            'Contenu réglementaire vérifié en octobre 2026 à partir des '
                'publications de l\'ANSM, de la CNIL et du Code de la santé '
                'publique.',
          ),
        ],
      ),
    );
  }
}
