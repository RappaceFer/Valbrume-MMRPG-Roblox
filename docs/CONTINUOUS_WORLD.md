# Valbrume — Deux continents continus

Date : 2026-09-29. Branche : `world/two-continent-layout`.
Base Git relue : `0f9f190077a3174a0a418eac0aae7c551871b7df`.
Statut : **plan d'assemblage, pas une installation ni une carte jouable validée**.

## Décision demandée par le propriétaire

Conserver une seule Place pour le monde ouvert. Agrandir les territoires existants et intégrer Place6/7/8/9 comme régions contiguës de deux continents. Les régions d'un continent partagent du terrain : ni téléportation inter-Place obligatoire, ni succession de plateaux carrés reliés seulement par des chemins étroits.

Cette décision remplace la proposition antérieure de quatre Places d'extension indépendantes. Les originaux restent conservés. Aucune fusion dans main, aucune publication Roblox, aucune suppression des sources.

## Composition proposée

### Ouest — Elyndra

- A2 : Val d'Astréa, vallée habitée, plaines et reliefs périphériques agrandis.
- S3 : Sylvebrume, forêt dense avec transition vers les hauts bois.
- N4 : Caps de Nacre, falaises et littoral.
- Place6 / P6 : Marches de Brumepin, nom provisoire ; forêt, cabanes et passages montagneux.
- Place9 / P9 : Val de Bellecorce, nom provisoire ; village, champs, vergers, marais et lisières.

### Est — Varkhûn

- H2 : Terres cendrées de Khar, désert et mesas agrandis.
- O5 : Forges d'Ormefer, relief minéral et forges.
- V6 : Profondeurs de l'Écho, fractures et cristaux.
- Place8 / P8 : Citadelle de Noctefort, nom provisoire ; château associé à une région montagneuse.
- Place7 / P7 : Presqu'île de Cendremer, nom provisoire ; thème volcanique et maritime. La région doit être reliée au continent par une vraie masse de terre, pas rester une extension isolée.

Les éléments maritimes de Place7 (VolcanoIsland, FortIsland, AtollIsland et DesertedIsland dans le fichier) ne sont pas silencieusement considérés comme déjà reliés : l'adaptation de leur Terrain et de leurs rivages reste à faire.

## Eau et limites

La Mer d'Obsidienne sépare les deux continents et rejoint l'océan autour d'eux. Pas de pont terrestre entre Elyndra et Varkhûn. Le ferry existant reste à vérifier comme traversée maritime. Une bande centrale X=-400 à X=400 est réservée à la mer dans le plan ; altitude d'eau proposée Y=8 pour rester cohérent avec l'empreinte maritime actuelle.

Ce sont des contraintes de conception, pas des résultats mesurés sur un nouveau Terrain. Les îlots générés par l'ancien script et les eaux natives des sources demandent une décision explicite lors du raccordement. Les lacs, rivières, marais et lave internes restent possibles, mais aucun ne doit couper involontairement le passage terrestre principal d'une région.

## Agrandir sans détruire l'existant

Ne pas appliquer un ScaleTo global au jeu. Garder les coordonnées des noyaux de gameplay existants et prolonger leurs périphéries : vallées larges, plateaux, forêts, montagnes et littoraux. Préserver PNJ, objectifs de quête, identifiants de régions, remotes, économie, inventaire, progression et sauvegarde.

Les centres relevés dans WorldV3/Layout.lua restent : A2=(-900,0,0), H2=(900,0,0), S3=(-1520,0,-560), N4=(-1520,0,560), O5=(1520,0,-560), V6=(1520,0,560). Le spawn A2/H2 à Z=20 ne doit pas être confondu avec le centre du Terrain à Z=0.

Les nouvelles frontières doivent être des surfaces contiguës avec des transitions de biome, pas seulement un graphe de routes. Les chemins indiquent où passer ; ils ne doivent pas être les seuls endroits où le sol existe.

## Mesures réalisées sur les quatre fichiers reçus

Lecture hors ligne des chunks INST/PROP/PRNT, des CFrame et des tailles. Aucun script des maps n'a été exécuté. Les volumes des pièces tiennent compte de leurs matrices de rotation.

| Source | Instances du fichier entier | BaseParts dans Workspace | Sources Luau | Emprise X x Z des pièces, studs |
|---|---:|---:|---:|---:|
| Place6.rbxl | 2536 | 1767 | 30 | 1001.60 x 988.00 |
| Place7.rbxl | 17107 | 15363 | 49 | 1466.10 x 1724.70 |
| Place8.rbxl | 40190 | 9209 | 14 | 922.10 x 966.05 |
| Place9.rbxl | 21618 | 4491 | 30 | 974.40 x 967.10 |

Les 81451 instances comprennent services, joints et scripts : ce n'est pas le nombre d'objets à importer activement. Chaque source contient des données SmoothGrid et PhysicsGrid non vides. **Leurs limites de Terrain ne sont pas déduites de l'emprise des Parts** : les blobs de Terrain sont identifiés et hachés, pas décodés en voxels. L'inspection ne constitue pas une validation visuelle ou physique dans Studio.

Les licences des quatre places ne sont pas établies par leur présence dans la conversation. Conserver la provenance et vérifier les droits avant publication ; ne pas leur attribuer la licence CC0 des packs Quaternius.

## Implantation candidate, non appliquée

Translation depuis les coordonnées originales, sans changement d'échelle, ni de rotation :

| Source | Continent | Translation proposée X,Y,Z |
|---|---|---|
| Place6 | Elyndra | -2368, 0, -1408 |
| Place9 | Elyndra | -2368, 0, 1408 |
| Place8 | Varkhûn | 2368, 0, -1408 |
| Place7 | Varkhûn | 2560, 0, 1344 |

Ces positions utilisent un pas de 4 studs. L'altitude et les limites finales devront être adaptées au Terrain réel et aux entrées des cartes. Toutes les emprises de pièces translatées restent hors de la bande maritime centrale ; ce contrôle ne prouve pas le raccordement du Terrain.

## Ordre de réalisation

1. Obtenir le fichier complet **VALBRUME_DEV.rbxl actuel**, enregistré en mode Edit après l'installation V3.1. Les quatre places et les sources Git sont disponibles ; le fichier complet de la place principale ne l'est pas encore.
2. Capturer les zones de Terrain réellement occupées et les entrées de chaque source. Conserver décor, Terrain et coordonnées internes. Isoler le gameplay étranger dans des copies ; ne pas supprimer indistinctement tous les joints d'un décor mobile.
3. Construire deux empreintes continentales larges et des masques de protection des noyaux existants et des cartes importées.
4. Raccorder les surfaces, puis les itinéraires et les accès aux bâtiments. Ne pas remplir aveuglément les sous-sols, caves, ponts et cours d'eau.
5. Adapter la détection des dix régions et les limites de déplacement. L'ancien détecteur ne connaît que six régions ; les ajouts ne sont pas automatiquement intégrés à la progression.
6. Refaire QA terrain, collisions, quêtes, spawns, donjons et mesures client/serveur. Aucun test positif de génération V3.1 n'a encore été fourni après l'installation réussie signalée par l'utilisateur.

## Critères d'acceptation

Deux masses continentales principales distinctes ; graphe de régions terrestres connecté dans chacune ; mer centrale continue ; aucune absence de support sur les parcours testés ; pas de paroi bloquant involontairement une frontière ; raccords de bâtiments, ponts et sous-sols respectés ; pas de régression gameplay ; budgets mémoire/temps de génération et performances mobile mesurés.

Un raycast sans anomalie ne garantit pas qu'un avatar peut traverser. Une connexion sur le plan ne garantit pas une connexion de voxels. Les anciennes 57 mesures MISSING sont des sondages sans Terrain, pas 57 trous distincts. Le résultat « sans défaut » reste un objectif de validation, pas une promesse obtenue avec le seul code.

## Références techniques

Roblox : https://create.roblox.com/docs/workspace/streaming ; https://create.roblox.com/docs/reference/engine/classes/Terrain .
Format binaire, documentation communautaire : https://dom.rojo.space/binary.html .
Le streaming est prévu pour charger/décharger les secteurs côté client. Il ne supprime pas le coût serveur et ne remplace pas le profilage.
