# Six raccords — correctif I/O et diagnostic 0.2.1

Branche : `fix/continent-six-links`. Base relue : `873724b79bf248125f494a5d9da4e9de3709e0cb`.
Statut : correction du rollback préparée ; cause du premier écart voxel encore inconnue ; test Studio en attente.

## Retour réel de la candidate 0.2

La génération `b6b2bd0b-abc1-44b1-b5af-539051850a93` du 29 septembre 2026 à 21:12
atteint Continents puis échoue dans ContinentLinkRepair, avant Biome/Ready :

- `Voxel readback mismatch` pendant la vérification de la tuile ;
- `tileRestored=false Unknown channel id 'Size'` pendant la tentative de restauration.

Il ne s'agit pas d'une réussite d'audit. Le log ne contient pas les valeurs du premier
écart. Rien ne prouve à ce stade une simple normalisation d'Air, une perte de liquide,
un arrondi, un délai ou un problème moteur. Aucun de ces scénarios n'est tenu pour acquis.

## Défaut certain et correction

`ReadVoxelChannels` retourne les trois canaux ET une métadonnée `Size`. L'ancien
rollback repassait le dictionnaire brut à `WriteVoxelChannels`, qui rejetait `Size`.
`V.commit` copie maintenant exclusivement SolidMaterial, SolidOccupancy et
LiquidOccupancy avant toute écriture, y compris pour la restauration. L'adaptateur
filtre de nouveau ces trois clés à la frontière API. Les tableaux de lecture restent
intacts et leurs métadonnées ne sont jamais envoyées comme canaux.

Les callbacks de restauration contrôlent toujours l'identité du monde, mais ne
réutilisent plus le budget temporel expiré de la réparation. Si le monde a changé,
aucune restauration n'est tentée dans le nouveau monde.

## Premier écart : instrumentation, pas dissimulation

La comparaison des matériaux reste stricte, même dans une cellule vide. La tolérance
d'occupation reste exactement `1/255 + 0.00001`, comme en 0.2.0. NaN et valeurs hors
[0,1] sont explicitement refusés. Aucun contrôle de lecture n'est supprimé ou assoupli.

Une divergence provoque au maximum trois relectures, séparées d'une étape physique,
sans répéter l'écriture destructive. Si elle persiste, le journal imprime
`[VALBRUME VOXEL DIAGNOSTIC]` avec le canal, la tuile, les coordonnées de cellule, les
triplets matériau/solide/liquide attendus, relus et précédents. La tuile est alors
restaurée avec les seules clés autorisées, sa restauration est relue et la génération
s'arrête. `tileRestored` ne concerne que cette tuile, pas les précédentes.

L'hypothèse de reconstitution locale des collisions et les six liaisons restent à
valider dans Roblox. Un écart persistant doit être analysé à partir de ces nouvelles
valeurs, et non contourné avec une tolérance arbitraire.

## Portée et artefact

`VALBRUME_CONTINENTS_CANDIDATE_0_2_1.rbxl` : 6 163 498 octets.
SHA256 : `aeb9e15bbec2c38352acce2abb684018490f99a222bbecadd65924450aff1ec4`.

Comparé à 0.2, seules quatre Sources changent : Voxels, Repair, et les étiquettes de
version dans Plan/ContinentsRuntime. 36 autres sources sont identiques. Le fichier
conserve ses 36 912 instances. Un seul chunk de propriétés Source est réécrit ; les
2 261 autres chunks sont repris octet pour octet. Terrain, meshes, textures, parents,
positions et rotations enregistrés sont inchangés. Aucun objet n'est ajouté.

## Tests locaux

12 cas exécutés avec Lua 5.4 et une API simulée qui retourne Size et refuse les canaux
inconnus, dont reproduction du défaut de rollback de 0.2, restauration après erreur
d'écriture et après divergence, lectures différées, refus des matériaux altérés,
NaN, payload incomplet, budget expiré, changement de monde, panne du logger.
Quatre fichiers acceptés syntaxiquement par Lua 5.4. Ce ne sont ni des tests du moteur
Roblox, ni une compilation officielle Luau, ni une validation des raccords.

## Une seule prochaine action

Arrêter Play et ouvrir 0.2.1 comme fichier distinct. Ne rien installer à la main.
Lancer Play et renvoyer l'Output serveur, y compris les lignes VOXEL DIAGNOSTIC si
présentes. En cas d'échec : Stop, ne pas publier et ne pas poursuivre sur un monde
partiellement généré. DEV, la baseline et la candidate précédente sont conservés.

Référence d'API consultée : https://create.roblox.com/docs/reference/engine/classes/Terrain
(ReadVoxelChannels et WriteVoxelChannels, 29 septembre 2026).
