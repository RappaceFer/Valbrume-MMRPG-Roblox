# Chantier paysage S3-P6 0.3.0

Statut : code et artefact prepares ; test du moteur Roblox et validation visuelle EN ATTENTE.
Branche : `world/s3-p6-landscape`, issue de `23b4d9fcc40679ad7156db393f3c56c891fd7ecd`.
L'utilisateur autorise a repartir exactement de la candidate 0.2.5. La baseline et les originaux ne sont pas remplaces.

## Livrable unique

`VALBRUME_CHANTIER_S3_P6_0_3_0.rbxl`, 6 176 651 octets.
SHA-256 : `399ebac40cb65355e0098175b21fc1d7278fd8b8bedb021752aa96ea183c38a1`.
Base relue : `VALBRUME_CONTINENTS_CANDIDATE_0_2_5.rbxl`, SHA-256 `de4edf54d4e01bd0604046853e02839c347a92ab1f9c02b31bad3732613d91c2`.
Le binaire est fourni dans la conversation, pas publie comme nouvel asset Roblox.

## Portee exacte

Premiere reprise de l'APPROCHE de Brumepin : courbe d'environ 503 studs de (-1700,-760) a (-2028,-1140), coordonnees X/Z. Ce n'est pas toute la route jusqu'a P6, ni toute la region S3, ni la reprise des dix regions.
Le chemin suit une courbe douce, pas des rectangles de FillBlock juxtaposes. Le profil relie les hauteurs mesurees aux deux extremites, avec une petite crete. La modification s'attenue progressivement aux extremites et lateralement vers le relief reel. Les accotements ont une largeur variable.
Les empreintes completes des tuiles qui croisent les quatre cartes natives sont exclues. Un retrait supplementaire et une transition sont appliques devant leurs limites. Les routes V3 et leurs abords sont proteges ; les objets statiques proches sont releves avec leur rotation et leur taille, puis proteges par leur boite englobante, meme si CanQuery=false.
Les colonnes d'eau, les colonnes vides et les coupes qui perceraient la couche de sol au-dessus d'une cavite sont ignorees et comptees. La reprise ne deplace ni ne supprime de decor. Cela peut laisser un obstacle ou une pente non resolus : ils restent visibles dans l'audit.
Aucun nouvel asset de vegetation, aucun village, aucune quete ou mob n'est ajoute. H2, les cotes et le detroit ne sont pas recomposes par ce lot.

## Execution et securite

Cinq modules : Plan, Field, Voxels, Build, Audit. Un seul script existant change, OpenWorldBiomeV28 : appel de Build APRES Continents.prepare et AVANT Biome/Ready, puis audit local apres Ready. Le correctif 0.2.5 des six liaisons reste intact.
La sculpture se fait au Play via ReadVoxelChannels/WriteVoxelChannels, jamais par modification binaire hors ligne du Terrain. Les 36 912 instances originales sont comparees propriete par propriete : une seule Source change ; cinq ModuleScripts et un Folder sont ajoutes. Les 39 autres sources, les donnees SmoothGrid/PhysicsGrid, assets, parents, positions et rotations restent identiques. 2 238 chunks sont copies octet pour octet ; 24 chunks de metadonnees/instances/sources sont ajustes.
L'outil exige Studio/Server, un monde stable et la bonne phase. Toute la planification precede les ecritures. Chaque tuile ecrite est relue. Toute regression de support du controle local declenche la tentative de restauration de TOUTES les tuiles deja ecrites, et l'arret de generation. Une session differente interdit de restaurer dans le nouveau monde. Le budget expire n'interdit pas le rollback dans le meme monde.
La normalisation autorisee reste uniquement LiquidOccupancy=0 dans une cellule entierement solide non Air ; la tolerance reste 1/255+0.00001. Il ne s'agit pas d'une identite binaire brute du Terrain apres une ecriture native.
La nouvelle geometrie demeure temporaire au Play. Le fichier contient les sources necessaires pour la reproduire au prochain Play. Ne pas copier l'etat runtime par-dessus DEV. Ne pas publier : cette livraison contient volontairement un verrou Studio.

## Mesures et validation

Le meme controle est execute avant/apres, puis apres les autres etapes de generation. Il couvre cinq bandes laterales (-24,-12,0,12,24), un pas de 6 studs, et 24 studs au-dela des extremites. Il mesure Terrain, support physique, eau, pente, variations de hauteur, hauteur libre, boites de decors et balayage du haut du corps.
Les boites englobantes sont une detection conservative d'obstacles possibles, pas une preuve de collision exacte des meshes. Les sondages et balayages ne sont pas une traversee de personnage ni une certification mobile.
Les audits globaux precedents restent executes avec leurs axes et leurs seuils inchanges. Leurs etiquettes 0.2.5 restent normales : la nouvelle revision est `LandscapeRevision=s3-p6-landscape-0.3.0`.

## Tests locaux executes

`python tests/landscape-s3-p6/run.py` : 15 cas passent avec liblua5.4. Syntaxe commune Lua/Luau, geometrie, transitions, protection de l'emprise complete, metadata Size, normalisation, eau, cavites, NaN, execution du vrai builder sur une API simulee, echec d'ecriture, concurrence, expiration, changement de monde et regression de support.
195 tuiles candidates et 6 686 colonnes de masque geometrique avant prise en compte des objets et du terrain reels. Ce ne sont PAS des nombres de tuiles effectivement sculptees dans Roblox.
Aucun moteur Roblox ni compilateur Luau n'a execute cette revision ici. Le rendu n'a pas ete observe. Les passes a zero de 0.2.5 et du vieux preview ne sont pas transferees automatiquement a ce chantier.

## Prochaine action utilisateur

Ouvrir uniquement le nouveau rbxl separement ; lancer Play ; ne coller aucun ancien preview ou installateur. Recuperer l'Output serveur jusqu'a `VALBRUME_S3_P6_LANDSCAPE_AUDIT_END`, ou la premiere erreur. Si la generation reussit, `Workspace.ValbrumeContinents.S3_P6_Worksite` contient un repere invisible pour cadrer le secteur dans Studio. Une capture locale et une traversee suivront avant toute autre region.

References API consultees :
https://create.roblox.com/docs/reference/engine/classes/Terrain
https://create.roblox.com/docs/reference/engine/classes/WorldRoot
