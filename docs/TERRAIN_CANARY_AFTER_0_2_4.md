# Après 0.2.4 : test natif sur une seule tuile

Statut : **outil de diagnostic préparé ; résultat moteur du test local inconnu**.
Branche : `fix/continent-six-links`. Base relue : `91ec677d301c9551029b09f8082a5f07677006e4`.
Aucun fichier de jeu sous `src/` et aucun `.rbxl` n'est modifié dans cette étape.

## Preuve reçue

Source : `Texte collé(20260929-195058).txt`, 59 301 octets,
SHA256 `e3aa7fc27bf34bbc2c7a2eecd02f495a18cf82c66a24a85d66a65ed7facf472f`.
Génération `95da8983-a746-46e6-a90e-993f49d27571`, le 29 septembre 2026 à 21:50.

Le monde atteint Ready. Les quatre cartes comptent 30 730 pièces, sans source
étrangère ni pièce non ancrée selon le scanner. Les 1 959 sondages des six liens
rapportent 131 absences de Terrain et 129 absences de support physique.
S3_P6 : 46/46 ; O5_P8 : 79/79 ; V6_P7 : 6/4 (Terrain/support).
N4_P9, S3_N4_BORDER et O5_V6_BORDER : 0/0 pour ces deux critères seulement.
Le total conserve 80 sondages d'eau, 117 de pente et 113 de dénivelé brusque.
La mer centrale conserve 29 détections d'eau sur 66 sondages.

La passe effectue 732 FillBlock. Après l'attente supplémentaire, les mêmes
131 sondages échouent. ReadVoxels trouve une occupation dans chacune de leurs
petites régions de lecture ; aucune de ces régions n'est complètement vide.

## Rectifications importantes

Le diagnostic 0.2.4 inspecte une région de plusieurs colonnes autour du rayon.
`voxelOccupied=true` ne prouve donc pas la présence d'une surface à l'intersection
exacte du rayon. Son `voxelTop` est une estimation de colonne, pas la hauteur du
maillage final. Il ne prouve ni un bogue de Roblox ni un défaut de collision.
Les trois liens à 0/0 ne sont pas déclarés praticables : des pentes, de l'eau et des
variations de plus de 100 studs restent présents dans les sondages de bordure.

L'inspection hors ligne de la candidate montre un SmoothGrid de 6 695 590 octets,
mais un PhysicsGrid de 14 octets, repris du DEV dont le Terrain enregistré était
vide. Cela constitue une piste sur l'assemblage hors ligne, pas une preuve de cause.
Aucune nouvelle modification de ce format binaire n'est tentée ici.

Une autre vérification relève que la Source ContinentLinkRepair embarquée dans le
fichier 0.2.4 a pour blob Git `3a02d7f9f93b78a61a43c81b1d499acbeb652fb9`, alors que
la source du dépôt relue a pour blob `846a61ddfc66dc21fa0dc7e5c81806d1fce96427`.
Ne pas revendiquer une identité octet pour octet du générateur livré avec le dépôt.
Le nouveau test autonome n'utilise ni ne remplace cette Source.

## Test limité fourni

`tools/terrain-canary/TEST_TERRAIN_S3.lua` est autonome. La copie utilisateur
`TEST_TERRAIN_S3.txt` est exactement ce même texte, pas un template incomplet.

Il exige Studio Play/Server, Ready et la candidate 0.2.4. Il cible uniquement
S3_P6 au point X=-1962.0330907564604, Z=-1056.6750321948148.
L'emprise est X=[-1976,-1948], Y=[-256,384], Z=[-1072,-1044] : 28 x 640 x 28 studs,
soit 7 840 voxels. Elle est hors des noyaux de gameplay et hors du noyau importé P6.

Avant toute écriture, il compare plusieurs paramètres de raycast et lit la colonne
exacte contenant ce point. Il ne réécrit rien si le rayon normal détecte déjà le
Terrain, si la colonne est sans solide ou si les propriétés de filtrage sont suspectes.
Sinon il garde les canaux en mémoire, vide temporairement la petite région et
restaure ses données via WriteVoxelChannels. Il relit les canaux et compare les rayons.

**Ce n'est pas un scan en lecture seule.** Il ne modifie aucune Source, aucun décor,
aucun avatar ni aucune donnée joueur. Il n'ajoute pas de hauteur de secours et ne
se propage pas aux cinq autres raccords. Arrêter Play après avoir capturé le résultat.

## Politique d'écriture explicite

La documentation Roblox indique que LiquidOccupancy vaut zéro dans une cellule
entièrement solide dont le matériau n'est pas Air. Le log 0.2.1 avait montré le cas
Sand/solid=1/liquid=1 devenant Sand/solid=1/liquid=0 après écriture.

Ce test applique UNIQUEMENT cette normalisation documentée aux données attendues,
avec un compteur `normalizedFullSolidLiquidCells`. Les matériaux et occupations
solides ne sont pas changés ; l'eau des cellules partiellement solides ou d'Air
n'est pas supprimée. `Size` n'est jamais transmis à l'API d'écriture.
La comparaison des matériaux reste stricte et la tolérance numérique reste
1/255 + 0.00001. Aucune identité binaire brute n'est revendiquée.

Une erreur d'écriture ou de vérification tente de restaurer le snapshot canonique,
et signale honnêtement son résultat. Un budget expiré n'empêche pas la restauration ;
un changement de monde empêche en revanche d'écrire dans une autre session.
Ne pas confondre `canonicalTileRestored=true` avec une restauration binaire exacte.

## Exécution, une seule action

Dans la candidate 0.2.4 déjà ouverte, lancer Play et attendre Ready, puis exécuter
TOUT le fichier TEST_TERRAIN_S3.txt dans la Command Bar **Server**.
Renvoyer le bloc VALBRUME_TERRAIN_CANARY_BEGIN/END et toute erreur éventuelle.
Arrêter Play ensuite, ne pas conserver les modifications de test et ne pas publier.

ONE_TILE_RAY_RECOVERED signifie uniquement que le rayon ciblé détecte du Terrain
après cette opération locale. Ce n'est ni une certification de déplacement d'avatar
ni la validation des six liaisons. ONE_TILE_STILL_MISSING ou ERROR_STOP_PLAY reste
un échec à étudier ; ne pas étendre automatiquement la réécriture à la carte.

## Contrôles locaux

Le fichier autonome a été analysé syntaxiquement par Lua 5.4, sous-ensemble commun
Lua/Luau. Treize cas ont été exécutés sur la logique réelle de normalisation et de
restauration avec une API simulée : métadonnées interdites, snapshot immuable,
cavités et eau partielle conservées, erreur d'écriture, mauvaise relecture,
restauration défaillante, budget expiré, concurrence, NaN et lecture différée.
Ce ne sont pas des tests Roblox ni une compilation officielle Luau.

Reproduction sous Linux avec liblua5.4.so.0 :
`python tests/terrain-canary/run.py`

Références d'implémentation consultées :
https://create.roblox.com/docs/reference/engine/classes/Terrain
https://create.roblox.com/docs/reference/engine/datatypes/RaycastParams
La variante BruteForceAllSlow est utilisée sur ce seul point, jamais dans le jeu publié.
