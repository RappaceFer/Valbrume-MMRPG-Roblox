# Revue visuelle — H2, mer centrale et A2 — 30 septembre 2026

Statut : **reprise visuelle nécessaire ; aucune validation artistique du monde**.
Base du dépôt relue : `3488f23abba5966ba6c484977febdc9ebd264ddf`, branche `fix/continent-six-links`.
Cette étape modifie uniquement la documentation. Aucun script de jeu, Terrain, objet, fichier rbxl ou réglage d'éclairage n'est modifié.

## Sources et repérage fourni par l'utilisateur

Dix captures reçues dans la conversation. L'utilisateur indique : images 1–3 côté H2 ; image 4 entre les continents ; images 5–10 côté A2. Ces indications désignent les côtés du monde, pas dix régions précises.
Les captures n'affichent ni coordonnées de caméra, ni sélection d'instance, ni identité de génération. Elles ne permettent pas d'attribuer chaque raccord à un script ou de reconnaître avec certitude toute la portion S3–P6 prévisualisée. La présence de la sculpture temporaire dans chacune des vues n'est pas démontrée.

| Image | Fichier reçu | Observation visuelle |
|---|---|---|
| 1 | image(20260930-054145).png | Côté H2 : grandes surfaces planes, limites droites, volumes rocheux très arrondis et voie rectiligne. |
| 2 | image(20260930-054225).png | Côté H2 : rupture nette entre le grand terrain gris et le secteur du château, dont l'environnement paraît plus détaillé. |
| 3 | image(20260930-054308).png | Côté H2 : côte pâle anguleuse et longues bandes droites ; contraste avec les formes plus irrégulières du secteur entouré d'eau. |
| 4 | image(20260930-054418).png | Mer centrale : longue séparation bleue, deux bandes littorales pâles presque parallèles et rectilignes ; effet de canal artificiel à cette échelle. |
| 5 | image(20260930-054522).png | Côté A2 : gros dômes rocheux, longues surfaces planes et axes rectilignes autour du village. |
| 6 | image(20260930-054545).png | Côté A2 : passage allongé entre des surfaces aux limites géométriques, raccordements visuellement marqués. |
| 7 | image(20260930-054603).png | Côté A2 : encadrement rectangulaire très lisible autour d'une surface rocheuse ; silhouette de plateforme plutôt que de relief continu. |
| 8 | image(20260930-054630).png | Côté A2 : village, rivière, champs et ponts détaillés ; une large bande grise en relief traverse visuellement la composition. Sa fonction et sa provenance restent à vérifier. |
| 9 | image(20260930-054652).png | Côté A2 : rivage et îlot irréguliers au voisinage d'une limite terrestre très droite. |
| 10 | image(20260930-054800).png | Côté A2 : ensemble de montagnes, eaux et village plus organique ; grandes périphéries peu détaillées et transitions encore visibles. |

Ce tableau décrit ce qui apparaît à l'image. Il ne classe pas les bandes sombres comme des trous physiques et ne mesure ni pente, ni collision, ni performances. La brume limite la lecture à distance ; aucun réglage de Lighting n'est déduit de ces seules vues.

## Résultats techniques à conserver, sans les élargir

La candidate 0.2.5 a passé le contrôle de support sur les **1 959 sondages des six liaisons**, pas sur toute la surface des continents. Le rapport du 29 septembre à 22:18 conserve `terrainMissing=0`, `unsupported=0`, mais 157 alertes de pente, 144 de dénivelé et 80 d'eau. La mer centrale reste à 29 détections d'eau sur 66. Le statut global reste REVIEW_REQUIRED.

La prévisualisation S3–P6 du 30 septembre à 07:25:18 a passé 66 sondages de Terrain sur son axe central : missing=0, water=0, steep=0, abrupt=0. Ce résultat demeure acquis dans sa portée exacte. Il ne valide pas les côtés, les deux raccordements avec le terrain non sculpté, les obstacles de décor ou l'itinéraire complet jusqu'à Brumepin.

La sculpture temporaire et les captures ne justifient donc pas une promotion automatique en DEV ni une publication.

## Vérifications dans le code actuel

Source : `src/ServerScriptService/ValbrumeServer/OpenWorldContinentsV28.server.lua`, blob `06528e778b307114d9a5bc4c292ffeb13a40e298` à la base relue.
Ce générateur écrit encore deux bandes de Sand de taille `(160,20,2100)` centrées en `(-500,8,0)` et `(500,8,0)`, ainsi qu'un bloc d'eau central. Ces bandes constituent une explication plausible des longs rubans pâles visibles sur la quatrième image. Une correspondance instance/coordonnées dans Studio reste nécessaire pour attribuer chaque forme visible avec certitude.

Source : `src/ServerScriptService/ValbrumeServer/ZoneExpansionService.server.lua`, blob `f5d6f62bcd65ab10b69f1a32cd26057a502464f5`, lignes de source 1–165 relues.
La fonction clearRegion y utilise un volume rectangulaire de `(720,300,720)` et les fonctions de relief emploient FillBlock/FillBall. Cela confirme la présence d'une génération par volumes géométriques ; ce n'est pas une preuve que chacune des arêtes ou chacun des dômes montrés provient de cette fonction.

Ne pas effacer ces volumes ni changer les générateurs globalement sur la seule base des captures. Certains accès et systèmes existants dépendent de leurs coordonnées.

## Décision de revue

- La qualité visuelle du monde montré n'est pas approuvée : effet de plaques, frontières droites, dômes isolés et côtes artificielles encore trop visibles.
- Les noyaux détaillés — villages, château, champs, rivières, ponts et montagnes composées — sont à préserver, pas à reconstruire pour les uniformiser.
- Le preview S3–P6 reste non intégré. Le zéro de son scanner ne suffit pas à l'approuver visuellement ; cette série n'isole pas avec certitude ses deux extrémités.
- Les captures ne rouvrent pas le correctif de support déjà validé sur les sondages. La suite concerne la forme des raccords et la praticabilité, sans réécriture du gameplay.

## Prochaine unité de travail proposée

Rester sur **S3–P6**, sans lancer simultanément la sculpture de H2, du détroit et des quatre cartes. Préparer une révision locale du passage avec un profil raccordé au terrain réel aux deux extrémités, des accotements fondus dans le relief et une protection de l'emprise COMPLETE des brosses vis-à-vis de P6. Le test actuel des seuls centres d'opération ne suffit pas.

Avant toute intégration : lire les objets réellement concernés ; contrôler l'ensemble de la largeur utile, le dégagement d'avatar, les obstacles et les transitions avec le sol non sculpté ; refaire les contrôles de non-régression du support. Ne pas masquer les défauts par de la brume, des arbres ou un relâchement des seuils.

Le travail sur O5–P8, V6–P7, N4–P9 et les frontières internes reste ensuite dans l'ordre convenu. La reprise des deux côtes est un lot visuel distinct à planifier en protégeant quais et ferry, pas une suppression immédiate des bandes de sable.

## Traçabilité des captures

Les images ne sont pas publiées dans le dépôt ; les originaux restent dans la conversation. SHA-256, dans l'ordre fourni :

```text
1  9105a1da1aff14209a5854ebb59026535addb16c987a1e42c732633e24d7831b
2  5a6622101ee688cb8aa71c0a44e53e69d351637098b99d28347c9397d6afc887
3  b743f34c9223b53cc818d2616654894d6334094ccdd6dc9a0d78610ac26f5926
4  98d20f0cfc778ea44264d881336a7dcd503d0c3eca5c92cc3660c76cfd5043be
5  362b22108c70e8181b172c784162ffc640d01d51552c2990b769be01e25452fd
6  d00de97526caeaf6eb105748808475111a0267dc3193e7d23887ea24d690a50c
7  4cffeb6cc4d6881706efc8b28a26d0d5098ecdcf583c363f7c0ab414da4186ef
8  3c4a6dcd35abeef2beeb33f2b143ac3402b6570509819e2ba339c36625b5499e
9  c28933940490b5fbbeafb00ce69cd3e04b10bf8ce9bf06cc71a5499ddba97bec
10 d9d0eb658713d24b1d9460188d28b04a7807ca8af79068a3a17986fd1c31212f
```
