# Résultats locaux — World V3.1.0

Exécution du 29 septembre 2026, environnement Linux, bibliothèque Lua 5.4.
Aucun moteur Roblox Studio disponible dans cet environnement.

| Contrôle | Résultat |
|---|---|
| Syntaxe partagée Lua/Luau des six fichiers runtime et quatre outils Lua | 10 fichiers acceptés |
| Géométrie : points sondés dans les cinq bandes de contrôle | 4 910 points, succès |
| Planification de tuiles | 286 tuiles uniques, budget 512 respecté |
| Pente maximale du modèle numérique sondé | 5,635° (ce n'est pas une mesure du Terrain Roblox) |
| Paramètres invalides | 6 cas refusés avant écriture |
| Empreintes blobs Git | vide, texte, CRLF et vraie source de baseline conformes |
| Vrai constructeur exécuté contre une API voxel simulée | 24 tuiles synthétiques |
| Occupation du cœur des corridors, scène synthétique | 8 960 voxels vérifiés |
| Terrain/eau hors masque, scène synthétique | 20 720 voxels inchangés |
| Monde remplacé / budget dépassé | refus sans écriture |
| Fichiers Command Bar générés | les 3 fichiers sont analysables |
| Installation / réexécution / retour arrière / conflits / erreur injectée | 10 scénarios réussis avec API Studio simulée |

Le rendu du Smooth Terrain, ses normales/collisions, la réplication, les permissions
Studio, la vraie transaction d'annulation et les performances nécessitent les tests
Roblox. Les doublures d'API vérifient la logique, pas ces comportements du moteur.
