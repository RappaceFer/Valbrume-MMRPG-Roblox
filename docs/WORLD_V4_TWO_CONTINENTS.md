# Valbrume — deux continents, dix régions (V4)

## Décision utilisateur et portée

Le monde cible est UNE place Roblox : deux continents séparés par la mer, avec cinq régions terrestres reliées sur chaque continent. Cette décision remplace la proposition précédente de quatre Places d'extension séparées. Les nouvelles cartes deviennent des noyaux de régions agrandies, et non des destinations de téléportation indépendantes.

L'agrandissement porte sur les territoires, les vallées, les forêts, les massifs, les côtes et les transitions. Les constructions et arbres importés restent à l'échelle 1. Les noms des quatre nouvelles régions sont des noms de travail.

Branche : `world/two-continents-v4`, issue du commit `0f9f190077a3174a0a418eac0aae7c551871b7df` de V3.1. La réussite de l'installation V3.1 a été confirmée par l'utilisateur, mais aucun rapport de validation du monde V3.1 après installation n'a encore été reçu.

## Organisation cible

| Continent | Région | Source du noyau | Identité cible |
|---|---|---|---|
| Elyndra | A2 — Val d'Astréa | Valbrume existant | Vallée habitée et prairies |
| Elyndra | S3 — Sylvebrume | Valbrume existant | Forêt dense et brume |
| Elyndra | N4 — Caps de Nacre | Valbrume existant | Massifs, falaises et côte |
| Elyndra | P6 — Marches de Brumepin | Place6.rbxl | Forêt et cabanes |
| Elyndra | P9 — Val de Bellécorce | Place9.rbxl | Village, campagne et marais |
| Varkhûn | H2 — Terres cendrées de Khar | Valbrume existant | Désert et canyons |
| Varkhûn | O5 — Forges d'Ormefer | Valbrume existant | Relief volcanique |
| Varkhûn | V6 — Profondeurs de l'Écho | Valbrume existant | Roche et cristaux |
| Varkhûn | P7 — Cendremer | Place7.rbxl | Région volcanique et maritime |
| Varkhûn | P8 — Citadelle de Noctefort | Place8.rbxl | Château et arrière-pays montagneux |

Le canevas de construction est de 12 288 × 8 192 studs, OCÉAN COMPRIS. Ce n'est ni une mesure de surface jouable ni une promesse de performances. Le champ de hauteur global définit deux masses terrestres ; il n'assemble pas dix plaques indépendantes. Le contour extérieur et le détroit sont en eau. Les coordonnées V4 sont des coordonnées d'AUTHORING, pas des valeurs à copier directement dans Config du jeu.

## Inspection réelle des quatre entrées

Lecture binaire locale des fichiers fournis, sans exécuter leur code :

| Entrée | Instances sérialisées | Script/LocalScript/ModuleScript |
|---|---:|---:|
| Place6.rbxl | 2 536 | 30 |
| Place7.rbxl | 17 107 | 49 |
| Place8.rbxl | 40 190 | 14 |
| Place9.rbxl | 21 618 | 30 |

Les quatre fichiers contiennent du Terrain natif (SmoothGrid et PhysicsGrid), pas seulement des Parts. Des copies SCENE_ONLY sont fournies dans le paquet utilisateur : Source/LinkedSource/Bytecode des conteneurs de scripts vidés, BaseScripts désactivés. Tous les autres chunks décompressés restent identiques, y compris le Terrain, les CFrames, tailles et données CSG. Les originaux ne sont pas modifiés. Ces copies contiennent encore des objets interactifs inactifs ; l'export Studio élimine ces objets dans la COPIE exportée.

Aucune licence de redistribution de ces quatre cartes n'a été établie à partir des seules pièces jointes. Elles ne sont pas assimilées aux packs Quaternius CC0. Les fichiers rbxl et les exports natifs restent hors du dépôt public ; conserver les sources/provenances avant publication.

## Livré, mais pas encore validé dans Studio

- Copies des quatre cartes avec anciens scripts neutralisés et inventaire JSON.
- Cinq modules d'authoring : Layout, HeightField, NativeCapture, Assemble, Audit.
- Quatre commandes d'export de cartes sources et une commande groupée pour les six régions existantes.
- Un modèle d'outils rbxmx inerte (ModuleScripts), une commande de construction et une commande de scan.
- Tests locaux du champ de hauteur et vérification de la sérialisation des outils.

L'assembleur exige DIX exports natifs. Il refuse une entrée manquante, une capture superposée, une translation hors grille et une place qui contient le serveur Valbrume ou du terrain existant. Il ne remplace pas automatiquement le MMO. Il travaille dans une place de chantier vide, réutilisable pour la migration, sans toucher à DEV ou à la baseline.

Il conserve les colonnes de terrain natif non vides des noyaux et reconstruit le territoire autour d'elles. Les marges vides dans les captures sont remplies ; les grottes et eaux natives restent conservées là où la colonne contient déjà du terrain/eau. Les jonctions sont interpolées à partir de sondages préalables. Ce n'est pas une preuve de raccord parfait : une côte, un ravin, un obstacle ou une porte native peut nécessiter une entrée aménagée.

## Procédure native — pas d'import FBX

1. Ouvrir Place6_SCENE_ONLY.rbxl en mode Edit et exécuter EXPORT_PLACE6.txt dans la Command Bar. Le modèle ServerStorage.WorldV4Export est sélectionné. Le sauvegarder en fichier .rbxm, puis fermer la place sans enregistrer. Répéter avec Place7, Place8, Place9 et leurs commandes correspondantes.
2. Ouvrir DEV en Play / SERVER. Attendre GenerationReady puis exécuter EXPORT_VALBRUME_6_REGIONS.txt. Sauvegarder le modèle WorldV4Export en .rbxm AVANT Stop. Les sources du jeu ne sont pas modifiées par cette capture.
3. Dans une nouvelle place vide de chantier, insérer les cinq exports sous ServerStorage.WorldV4Sources. Les dix sous-modèles sont identifiés par SourceId ; conserver leurs attributs, NativeTerrain et Decor.
4. Insérer ValbrumeWorldV4Tools.rbxmx sous ServerStorage, puis exécuter BUILD_IN_EMPTY_PLACE.txt en mode Edit. La construction peut être longue ; la progression est imprimée. Ne pas lancer Play pendant la construction.
5. Exécuter SCAN_WORLD_V4.txt et conserver tout le bloc VALBRUME_CONTINENTS_V4_AUDIT_BEGIN/END. Contrôler aussi les entrées, les cols, les rives, le château et les collisions avec un avatar.

Les commandes complètes sont générées avec leur code embarqué ; aucun template incomplet, chargement réseau ou MeshId inventé n'est nécessaire. Les captures sont à conserver dans ServerStorage, car TerrainRegion ne se réplique pas aux clients.

## Ce qui N'EST PAS fait

- Pas de migration du combat, des données joueur, des quêtes, des spawns ou du ferry vers les coordonnées V4.
- Pas de garantie de routes praticables ni de résultat Roblox Studio : aucun moteur Studio n'a exécuté ce paquet ici.
- Pas de nouvelle quête, nouveau boss ou changement d'économie.
- Pas d'optimisation mobile démontrée ; le streaming devra être configuré et mesuré.
- Pas de rendu artistique final ni de claim « sans défaut ».

Les anciennes coordonnées sont utilisées dans plusieurs services et configurations. Déplacer uniquement Config casserait des correspondances : la migration du gameplay doit être séparée, explicite et testée. Les itinéraires sondés par Audit sont des candidats rectilignes, pas des routes finales validées. Le statut BUILT_UNVALIDATED ne signifie pas que la carte est prête à publier.

En cas d'échec de génération, FAILED_PARTIAL est enregistré et aucun résultat valide n'est annoncé. Recharger la place de chantier vide : ne pas essayer d'utiliser le terrain partiellement construit. Aucun script ne nettoie automatiquement une place existante.

## Critères de validation

Deux continents réellement séparés par l'eau ; dix régions identifiables ; liaisons terrestres aménagées dans les deux sens ; pas de chute accidentelle sur les parcours ; accès praticables aux cartes natives ; identité visuelle et échelle cohérentes ; tests de streaming PC/mobile ; migration complète des coordonnées gameplay avant remplacement du monde DEV.

Références consultées : documentation Roblox Terrain (CopyRegion/PasteRegion, ReadVoxelChannels/WriteVoxelChannels), TerrainRegion, Model et instance streaming ; spécification communautaire du format binaire rbx-dom pour l'inspection hors ligne. Les tests locaux ne remplacent pas les tests du moteur.
