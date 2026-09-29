# Candidate 0.2 — six raccords uniquement

Branche : `fix/continent-six-links`. Base relue : `06f81b3c25155e63139dc2053c384d3d4f29b193`.
Statut : correctif préparé, tests locaux réussis, **test Roblox de 0.2 en attente**.

## Point de reprise

Le rapport serveur utilisateur du 29 septembre 2026, génération
`3ff401fc-8247-4176-afcd-aad8b247f884`, confirme le démarrage de la candidate 0.1
jusqu'à Ready et les 30 730 pièces des quatre maps. Les six lignes de prospection
signalent respectivement 59, 80, 90, 143, 33 et 33 sondages sans Terrain pour
S3_P6, N4_P9, O5_P8, V6_P7, S3_N4_BORDER et O5_V6_BORDER. Ce sont des sondages,
pas des trous distincts. Le journal ne compte pas encore unsupported dans ses totaux.

Une nuance change le correctif : le fichier livré contient, selon le décodeur hors
ligne, du terrain aux coordonnées où les raycasts n'en détectent pas. Par exemple,
(-1900,-1000) donne une surface encodée vers Y=27.66. Cela ne démontre pas un bug
Roblox ni une cause unique. Une incohérence entre données natives et collisions est
une hypothèse à tester, plutôt qu'une raison de remblayer aveuglément les cartes.

## Comportement du correctif

Un seul module existant change : ContinentsRuntime. Il appelle cinq petits modules
Plan / Geometry / Voxels / Repair / Audit après sa réparation de bordure, avant Biome
et Ready. Les autres 34 sources de la candidate 0.1 restent identiques.

Sur les six polylignes d'origine, une bande de 96 studs est examinée par tuiles de
64 studs. Les emprises V3 complètes, leurs accotements, les camps et la mer centrale
sont exclus des colonnes modifiables. Les axes de test ne sont pas déplacés.

- Si les données voxel existent mais que le raycast est absent ou fortement décalé,
  les colonnes concernées sont temporairement vidées puis restaurées par les API
  natives de Terrain, avec une étape physique entre les deux écritures. La forme,
  les cavités et l'eau d'origine sont conservées dans l'état final.
- Si une colonne est réellement vide et sans support physique, un remblai est ajouté
  uniquement hors des enveloppes des quatre cartes natives. Son altitude de secours
  est interpolée ; le bord du remblai est adouci. Aucun relief occupé n'est aplati.
- Une colonne vide dans une carte native, ou sous une pièce qui fait support, n'est
  pas remplie arbitrairement. Elle reste explicitement visible dans les diagnostics.
- Chaque tuile écrite est relue. En cas d'erreur, sa restauration est tentée et la
  génération s'arrête avec FAILED_PARTIAL. Stop restaure l'état de la session Edit ;
  aucun résultat incomplet n'est annoncé comme réussi.

`refreshed`, `filled`, `nativeRayMismatch` et `protectedEmpty` distinguent les cas.
Le correctif n'ajoute aucune pièce, ne déplace aucun décor et ne touche à aucun
Remote, profil, combat, PNJ, quête ou système de sauvegarde. Il ne répare pas la mer.

## Livrable et contrôle local

Fichier : `VALBRUME_CONTINENTS_CANDIDATE_0_2.rbxl` (6 161 783 octets).
SHA-256 : `0791f525d3d917b70fd6cc48441e1f928759271075e79f63c1498dfac3f83048`.

Les 36 907 instances originales sont relues et comparées propriété par propriété :
une seule Source diffère, cinq ModuleScripts sont ajoutés. Les données enregistrées
SmoothGrid et PhysicsGrid sont strictement inchangées. Les modifications du terrain
ont lieu au Play via Roblox, pas par une nouvelle écriture binaire hors ligne.

Contrôles locaux : six fichiers acceptés par le parseur Lua 5.4 sur leur syntaxe
commune Lua/Luau ; 337 tuiles uniques et 44 326 colonnes de masque ; exclusion V3/mer,
protection des cavités/eaux, comblement de colonne vide, restauration après erreur,
réexécution sans doublon et appel du vrai module contre des API simulées.
179 824 assertions répétées vérifient ces cas : ce n'est PAS 179 824 tests Roblox.
Aucun moteur Roblox ni compilateur Luau n'a exécuté cette livraison ici.

## Test suivant — une seule carte à ouvrir

Ouvrir la candidate 0.2 séparément, sans écraser DEV ou 0.1. Ne rien réinstaller.
Lancer Play ; attendre la génération et les deux audits automatiques. Conserver
l'Output complet. En cas d'erreur, arrêter Play sans correction manuelle.

Le bloc `VALBRUME_CONTINENTS_AUDIT_BEGIN/END` contient désormais six `LINK_SUPPORT`
et un `LINK_SUPPORT_SUMMARY`. Le contrôle conserve les sondages centraux de 0.1 et
ajoute les bandes -16/+16 studs. Le critère de cette étape est terrainMissing=0 et
unsupported=0. SUPPORT_SAMPLED_OK n'atteste ni pente praticable, ni absence d'obstacle,
ni performance mobile. Les avertissements antérieurs restent affichés.

Le contrôle central de la mer (29 hits eau sur 66 dans le rapport 0.1) n'est pas
masqué : REVIEW_REQUIRED peut donc rester vrai même si les six raccords passent.
Les obstacles N4_WindBridge/O5_RuinPillar et les alertes de pente des anciens chemins
restent hors du présent correctif. La carte reste non publiable tant que ces contrôles
et les traversées réelles ne sont pas validés.

Référence d'API : https://create.roblox.com/docs/reference/engine/classes/Terrain
(ReadVoxelChannels / WriteVoxelChannels, résolution 4). La compatibilité moteur réelle
et l'hypothèse de reconstruction des collisions restent à confirmer par le prochain Play.
