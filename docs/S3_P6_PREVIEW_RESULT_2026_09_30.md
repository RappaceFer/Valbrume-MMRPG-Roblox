# S3–P6 : résultat de prévisualisation du 30 septembre 2026

Statut : **contrôle Terrain de l'axe central réussi sur une portion ; rendu, largeur et raccordements non validés**.
Branche relue : `fix/continent-six-links`, tête `82006f9d3f7442f31b8a5212f6b95b7181fa7eaf`.
Source relue : `tools/world-passes/VALBRUME_S3_P6_COL_PREVIEW.lua`, blob `0d3c982e79afa18bd2aa88308bcd51926cf83fef`.
Cette étape consigne un retour utilisateur. Elle ne modifie aucun script, aucun terrain et aucun fichier rbxl.

## Preuve reçue

Journal collé par l'utilisateur dans la conversation, le 30 septembre 2026 :

```text
07:25:18.060 === VALBRUME_S3_P6_COL_PREVIEW_BEGIN === - Server
07:25:18.262 [VALBRUME S3_P6 COL] samples=66 missing=0 water=0 steep=0 abrupt=0 terrainWrites=975 protectedSkipped=0 - Server
07:25:18.262 === VALBRUME_S3_P6_COL_PREVIEW_END === - Server
```

Les 66 rayons verticaux trouvent du Terrain. Aucun ne détecte Water, aucune normale échantillonnée ne dépasse le seuil de 30 degrés et aucun intervalle échantillonné ne dépasse le seuil de dénivelé de 25 degrés. Les zéros ne signifient pas que le passage est plat.

La portion prévisualisée suit les points (X,Y,Z) :
`(-1700,29,-760) -> (-1790,30,-860) -> (-1880,32,-965) -> (-1970,35,-1070) -> (-2028,36,-1140)`.
Ce n'est pas l'itinéraire S3–P6 complet jusqu'au point terminal de prospection `(-2225,-1483)` en X/Z. Les seuils et le tracé diffèrent de l'audit global : ne pas comparer leurs compteurs comme s'il s'agissait des mêmes sondages.

## Portée exacte et limites

- Le scan final du preview inclut uniquement Terrain et l'axe central. Il ne mesure pas toute la bande latérale et n'inspecte ni les collisions de décors, ni la hauteur libre pour un avatar.
- Les jonctions entre cette portion et le relief non sculpté ne sont pas parcourues par le scan. Une falaise à une extrémité reste possible malgré le zéro sur l'axe interne.
- `terrainWrites=975` compte des appels de sculpture, pas des pièces créées ou des secteurs uniques.
- `protectedSkipped=0` signifie qu'aucun centre d'opération n'a déclenché l'exclusion P6. Ce n'est PAS la preuve qu'aucune empreinte de FillBlock/FillBall ne dépasse cette limite. Le contrôle des volumes complets reste à faire avant intégration.
- Il n'y a pas encore de capture du rendu de ce col, de traversée avec avatar ou de mesure mobile dans ce retour.
- Le résultat est celui de la session Play utilisateur, pas d'un test exécuté ici. Aucune sauvegarde permanente de la sculpture n'est validée.

## Ne pas confondre les deux audits

L'audit global termine à 07:25:15.024, AVANT l'exécution du preview à 07:25:18. Il confirme, pour la candidate 0.2.5 avant sculpture, 1 959 sondages / 6 raccords, `terrainMissing=0`, `unsupported=0`, mais 157 alertes de pente, 144 de dénivelé et 80 d'eau. La mer centrale reste à 29 détections d'eau sur 66. Le statut général reste REVIEW_REQUIRED.

Le rapport complet précédent du 29 septembre à 22:18 (génération `e8e715e0-b390-4899-99d0-901993fee4b6`) confirme également ces valeurs et 30 730 pièces importées sans source étrangère ni pièce non ancrée. Il ne valide pas les parcours joueur.

## Message Explorer distinct

À 07:25:14.994, la pile de l'outil Explorer de Studio indique `Instance added to parent we don't know about`. Le preview commence ensuite et imprime son marqueur de fin. Ce message ne prouve pas une erreur du preview ; sa cause et sa résolution ne sont pas établies. Ne pas désactiver les plugins ni modifier le jeu sur cette seule base.

## Prochaine action unique

Obtenir une vue aérienne oblique du col dans la session Play qui contient la sculpture, avec les deux extrémités visibles. Examiner l'insertion dans le relief, les accotements et les décors avant d'intégrer le preview ou de passer à O5–P8. Ne pas publier et ne pas conserver les changements de la session comme nouvelle référence sans validation.
