# Deux continents — copie candidate 0.1

Date : 2026-09-29. Statut : **assemblage hors ligne ; ouverture et Play dans Roblox Studio non exécutés**.
Cette note est le point de reprise après réception du DEV. Elle remplace les positions provisoires et le blocage « DEV manquant » du premier plan, pas ses critères de validation.

## Source reçue

VALBRUME_DEV.rbxl : 538575 octets, 662 instances, 33 sources Luau.
SHA256 : `34972d22124532166516022bfaf97dbbdc5b6e25784e84f78c2367c164fae4c9`.
Les cinq modules WorldV3 et le bootstrap V3.1 sont présents. Son SmoothGrid enregistré est vide (2 octets) ; le monde principal se génère au Play.

## Artefact livré séparément

`VALBRUME_CONTINENTS_CANDIDATE_0_1.rbxl` : 6151807 octets, 36907 instances, 35 sources.
SHA256 : `ac798471ab560f6369f30720217557f8a72403a6bd5cbb9fdbd5962432a3000b`.
Le fichier et les outils de construction hors ligne sont livrés dans l'archive de conversation `Valbrume_Continents_Candidate_0_1.zip`. Conserver cette archive localement : les quatre cartes binaires ne sont pas publiées dans le dépôt public, leurs licences n'étant pas vérifiées.

## Implantation appliquée à cette copie

| Source | Région | Continent | Translation X,Y,Z | BaseParts conservés |
|---|---|---|---|---:|
| Place6.rbxl | P6 Brumepin | Elyndra | -2560,0,-1664 | 1753 |
| Place9.rbxl | P9 Bellecorce | Elyndra | -2560,0,1664 | 4447 |
| Place8.rbxl | P8 Noctefort | Varkhun | 2560,0,-1664 | 9168 |
| Place7.rbxl | P7 Cendremer | Varkhun | 2944,0,2048 | 15362 |

Translations identiques pour les pièces et le Terrain, alignées sur 128 studs. Échelle 1, rotation ajoutée 0. Les noms nouveaux restent provisoires.
Les décors sont sous `Workspace.ValbrumeContinents.ImportedRegions`. Le Terrain reste dans `Workspace.Terrain`.
Deux masses principales et l'océan sont préparés sur une emprise de 8960 x 6656 studs, océan compris. Les noyaux de gameplay existants restent à leurs coordonnées ; l'agrandissement concerne les périphéries. La partie détaillée des quatre cartes n'est pas uniformément agrandie.
Les colonnes de terrain natif occupées sont protégées, cavités comprises, sauf une liaison maritime explicitement remblayée au nord-ouest de l'île volcanique P7. Des îlots côtiers secondaires restent séparés. Ce n'est pas encore une promesse de traversée piétonne de chaque élément des cartes.

## Séparation du gameplay étranger

Aucun code des quatre sources n'a été exécuté. Dans les copies importées, les scripts, remotes, bindables, outils, anciens spawns, rigs à Humanoid, anciennes interfaces/interactions, sons et joints/movers ont été exclus. Les pièces restantes sont ancrées. Les anciens bateaux, canons et portes mobiles deviennent du décor statique.
Les originaux fournis sont inchangés. Les MeshId/textures/données d'union conservés restent soumis aux permissions de chargement de Roblox.

## Modifications du code Valbrume

30 des 33 sources DEV restent bit-identiques. Seuls OpenWorldContinentsV28 (pas d'îlots au milieu de la mer dans cette copie), OpenWorldBiomeV28 (atlas des dix régions, bordures et audit) et OpenWorldAtmosphereClientV28 (alias d'ambiances) sont adaptés.
Deux modules sont ajoutés : ContinentAtlas et ContinentsRuntime. Aucun contrat de Remote, profil, inventaire, combat, sauvegarde ou progression n'est refondu.
Les trois racines éditoriales `Workspace.Baseplate`, `Workspace.SpawnLocation` et le `Workspace.ValbrumeWorld` sauvegardé sont archivées par changement de parent sous `ServerStorage.ValbrumeEditorArchive_Continents01`, sans supprimer leurs données. La grande Baseplate ne doit plus constituer un sol artificiel sous l'océan.

## Vérifications locales effectuées

- Réencodage bit-identique des tableaux de propriétés avant transformation ; relecture du DOM complet de sortie.
- Aucune modification des objets DEV hors de l'allowlist de sources, parents et SmoothGrid.
- Cinq fichiers nouveaux/modifiés acceptés par Lua 5.4, sous-ensemble commun seulement : pas une compilation du moteur Luau.
- Centres de l'atlas et partition de la bande maritime testés.
- 1158 chunks natifs comparés ; 34711264 cellules protégées identiques sur les trois champs décodés.

Le codec binaire est limité au format rencontré. La relecture par ce même codec ne remplace pas un test Roblox. Le cache PhysicsGrid vide de DEV est conservé ; la reconstruction effective des collisions doit être vérifiée à l'ouverture.
Le test d'altitude seule ne suffit pas : Place6 comporte du terrain sec sous l'altitude globale de la mer ; les douves/ponts de Place8 doivent être évalués avec les Parts, pas seulement le Terrain.

## Test utilisateur suivant

Ouvrir la copie candidate comme fichier distinct, ne pas écraser DEV ni la baseline. Inspecter les quatre régions en Edit, puis lancer Play. Ne pas publier.
Renvoyer l'Output serveur entre `=== VALBRUME_CONTINENTS_AUDIT_BEGIN ===` et `=== VALBRUME_CONTINENTS_AUDIT_END ===`, et toute erreur rouge. Le scanner V3.1 continue aussi de fonctionner.
Si le fichier ne s'ouvre pas ou le Terrain ne charge pas, arrêter et transmettre l'erreur. Aucun bricolage manuel ni réinstallation V3.1 dans cette copie n'est demandé.

## Toujours en attente

Ouverture moteur, collisions, franchissement des frontières, accès aux douves/ponts/bâtiments, tests gameplay existant, droits des assets, mémoire et performances mobile. Les nouvelles régions n'ont pas encore leurs quêtes/mobs/boss Valbrume. Les lignes du scan sont des parcours de prospection, pas des routes certifiées. Cette livraison n'est ni le rendu artistique final ni une version publiable.
