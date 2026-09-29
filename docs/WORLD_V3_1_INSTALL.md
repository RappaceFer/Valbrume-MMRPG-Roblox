# Valbrume World V3.1 — installation et validation

**Statut : code préparé et tests locaux réussis ; validation Roblox Studio en attente.**
Branche de travail : `world/valbrume-rebuild-v3`. Ne pas publier cette version avant les tests.

## Ce qui est livré

Un bootstrap compatible avec `OpenWorldContinentsV28` et cinq ModuleScripts dans
`ServerScriptService.ValbrumeServer.WorldV3` : Layout, Geometry, TerrainBuilder,
Dressing et Audit. Le bootstrap conserve l'étape `Continents`, les noms de régions
et les dossiers attendus par les services existants.

Le lot traite quatre liaisons régionales et deux accès aux quais. Les profils sont
numériques et déterministes ; les cols ont une bande centrale de 56 studs et des
accotements. Les surfaces sont écrites par tuiles de 64 studs, sur la grille Terrain
à 4 studs. Les colonnes au-dessus du passage sont dégagées jusqu'à Y=192 ; les
colonnes en dehors des masques ne sont pas changées par le constructeur de corridors.
L'empreinte maritime V2.8 reste générée comme avant.

Des bornes et bannières originales servent de repères. Seuls les modèles Tree/Cactus
ancrés et reconnaissables de WorldBuilder sont replacés au sol/décalés hors du passage.
Aucun pack externe ni faux MeshId n'est ajouté. Les maisons, PNJ, remotes, combat,
progression, DataStores et données de quêtes ne sont pas réécrits.

## Installation dans la copie DEV

1. Ouvrir **VALBRUME_DEV**, conserver la copie BASELINE fermée et intacte. Arrêter Play.
2. Fermer l'onglet d'édition du Script `OpenWorldContinentsV28`, s'il est ouvert.
3. Ouvrir `01_INSTALL_WORLD_V3_1.txt` (ou `.lua`) dans un éditeur de texte, tout copier
   puis exécuter le contenu dans la **Command Bar de Studio, en mode Edit**.
4. Attendre `[VALBRUME V3.1 INSTALL] OK`. En cas de refus, conserver le message : ne pas
   supprimer les contrôles d'intégrité ni remplacer les sources à la main.
5. Enregistrer DEV, lancer Play et attendre la fin du rapport automatique côté serveur.

**Ce n'est pas un audit en lecture seule : l'installateur écrit six fichiers de code.**
Il ne sculpte pas la carte en mode Edit. La nouvelle géographie est construite au Play
par le serveur, comme l'était la géographie précédente. Le nom de fichier `.rbxl`
ouvert n'est pas vérifiable de façon fiable par cet installateur : choisir DEV reste
indispensable. Le contrôle de `game.Name` contenant BASELINE n'est qu'une précaution.

## Protection des sources

Avant toute écriture, l'installateur vérifie les 28 sources connues de la baseline,
les classes et les remotes/bindables indispensables. Seule la source du générateur
accepte aussi la révision V3.0 déjà préparée dans GitHub. Les empreintes sont celles
des blobs Git SHA-1 (normalisation CRLF vers LF uniquement), et non une signature de sécurité.
Les sources ouvertes avec des modifications non enregistrées font refuser l'installation.
Ce contrôle couvre les fichiers connus ; il ne certifie pas l'absence de scripts
supplémentaires apportés par d'autres modèles ou plugins.

Le script remplacé est conservé en `StringValue`, non exécutable, dans :
`ServerStorage.ValbrumeInstallBackups.WorldV3_3_1_0_<GUID>.OriginalSource`.
Les modules sont écrits et relus avant de remplacer le point d'entrée. Une transaction
ChangeHistoryService permet l'annulation en cas d'erreur. Le script vérifie ensuite
le retour à l'ancien état ; si cette vérification échoue, recharger DEV sans enregistrer.
Une réexécution identique ne fait rien. Une installation locale modifiée est refusée.

## Rapport à renvoyer

Copier le bloc serveur complet :

```text
=== VALBRUME_WORLD_V3_AUDIT_BEGIN ===
...
=== VALBRUME_WORLD_V3_AUDIT_END ===
```

Le rapport démarre automatiquement **dans Studio seulement**, après `GenerationReady`.
Pour le relancer : exécuter `02_SCAN_WORLD_V3_1.lua` dans la Command Bar en **Play / Server**.
Le scan est en lecture seule. Il échantillonne les parcours déclarés tous les 6 studs,
à -8, 0 et +8 studs de l'axe, distingue Terrain et support physique, et vérifie aussi
pentes, variations de hauteur, écart au profil et obstacles à hauteur de personnage.
Les détails sont plafonnés à 60 anomalies par parcours mais les compteurs continuent ;
`omitted` indique combien de détails supplémentaires n'ont pas été imprimés.
`SAMPLED_OK` signifie seulement qu'aucune anomalie n'a été détectée aux points sondés.

Ensuite, parcourir les quatre liaisons et les deux accès aux quais dans les deux sens,
avec un avatar réel, puis contrôler le mobile, les PNJ, les quêtes et les populations.
Un résultat de raycast n'est pas un test de déplacement complet.

## Retour arrière

Arrêter Play. Fermer les onglets des six scripts V3.1. Exécuter
`03_ROLLBACK_WORLD_V3_1.lua` depuis la Command Bar en mode Edit. Il refuse d'écraser une
modification locale ultérieure, vérifie sa sauvegarde, restaure le générateur précédent
et détache le dossier WorldV3. La sauvegarde reste conservée. Relancer Play ensuite.
Les anciens fichiers `.rbxl`, `main` et la branche baseline ne sont pas touchés.

## Limites connues et rectification du premier audit

- Les 57 `missingSamples` de l'ancien rapport sont **57 sondages sans Terrain**, pas
  57 trous distincts. Ils excluent les compteurs des anneaux extérieurs.
- Les quatre anciens sondages d'axe n'avaient pas de point manquant ; cela ne démontrait
  pas la praticabilité. Le filtre ignorait tous les Parts, et des dénivelés sévères existaient.
- L'ancien scanner prenait les spawns A2/H2 à Z=20 pour des centres de terrain à Z=0.
  Ses cercles de rayon 300 débordaient jusqu'à Z=320 au-delà du socle carré. Les cinq
  points extérieurs manquants par région ne justifient donc pas, seuls, de combler la bordure.
- V3.1 déclare explicitement ses itinéraires, dont les terminaux se situent hors des camps.
  Les mesures V1 sur un axe différent ne sont pas une comparaison exacte point par point.
- La première passe V3.0 était une proposition non testée. V3.1 retire ses boules d'arrivée
  surélevées et remplace ses blocs inclinés/dégagement partiel par des colonnes voxel.
- Les falaises hors parcours, la jonction détaillée avec les camps et les obstacles
  créés ensuite par les autres services restent à examiner visuellement. Aucun résultat
  de test Roblox, rendu artistique final, performance mobile ou conformité de publication
  n'est revendiqué dans cette livraison.

## Reproduire le paquet et les tests

Depuis un checkout Git contenant l'historique de la baseline :

```sh
python tools/world-v3/build_release.py --output ./dist/world-v3.1
python tests/world-v3/run_local.py
```

Le deuxième programme nécessite la bibliothèque partagée Lua 5.4 sous Linux. Il teste
le sous-ensemble syntaxique commun à Lua/Luau et les algorithmes avec des doublures
explicites des API, **pas le moteur Roblox ni son compilateur Luau**. Sans les objets
Git historiques, `--baseline-zip CHEMIN` accepte l'archive source de la baseline.

Références d'implémentation : documentation officielle Roblox, classes Terrain
(ReadVoxelChannels/WriteVoxelChannels), ScriptEditorService (GetEditorSource/UpdateSourceAsync),
ChangeHistoryService (TryBeginRecording/FinishRecording). Ces API ont été consultées
le 29 septembre 2026 ; aucune dépendance tierce ne s'exécute dans le jeu.
