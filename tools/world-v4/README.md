# Outils de chantier — deux continents V4

**Pas un installateur du MMO. Ne pas lancer BUILD dans DEV.**

Lire `../../docs/WORLD_V4_TWO_CONTINENTS.md` depuis ce dossier, ou `docs/WORLD_V4_TWO_CONTINENTS.md` depuis la racine du depot (le chemin relatif correct depuis tools/world-v4 est ../../docs).

Les cinq modules servent a exporter/copier du Terrain natif, assembler le territoire dans une place de travail VIDE et produire un rapport de sondage. Les modules ne s'executent pas a l'insertion du modele d'outils.

## Reproduction des commandes completes

```sh
python tools/world-v4/build_release.py --output tools/world-v4
python tools/world-v4/tests/check_local.py
```

Le generateur necessite seulement Python 3.10+. Les tests necessitent numpy, lxml et la bibliotheque partagee Lua 5.4 sous Linux. Ils ne lancent ni Studio ni le compilateur Luau : ils verifient la syntaxe commune Lua/Luau, le champ numerique et l'egalite des sources embarquees. Le constructeur Assemble et les API de capture n'ont pas ete executes dans Roblox.

Sorties : cinq commandes `exports_studio/EXPORT_*.txt`, `BUILD_IN_EMPTY_PLACE.txt`, `SCAN_WORLD_V4.txt`, `ValbrumeWorldV4Tools.rbxmx`.

## Ordre de travail

1. Dans chacune des quatre copies SCENE_ONLY, Play arrete, executer la commande correspondante et sauvegarder le Model `ServerStorage.WorldV4Export` en `.rbxm`. Garder les sources originales intactes.
2. Dans DEV, Play / Server, attendre GenerationReady puis executer EXPORT_VALBRUME_6_REGIONS. Sauvegarder le Model WorldV4Export AVANT Stop.
3. Dans une place de chantier vide, inserer les cinq fichiers de modeles sous ServerStorage.WorldV4Sources. Inserer le modele d'outils sous ServerStorage. Ne pas renommer les SourceId et ne pas retirer NativeTerrain.
4. En Edit, lancer BUILD_IN_EMPTY_PLACE. Le script attend dix noyaux, refuse les doublons et ne nettoie jamais une carte existante. La construction est volumineuse et peut prendre du temps.
5. Lancer SCAN_WORLD_V4, inspecter les jonctions et ensuite seulement preparer la migration des systemes Valbrume.

Si Studio ajoute un SpawnLocation a la nouvelle baseplate, le deplacer hors Workspace avant BUILD, par exemple dans ServerStorage. Le constructeur ne le retire pas automatiquement.

Le statut BUILT_UNVALIDATED n'est pas une validation. Les routes sont encore des liaisons candidates, les forêts supplementaires et details artistiques restent a composer ; l'eau native peut exiger un pont d'acces. Ne pas remplacer le monde DEV par ce chantier sans migration de ses coordonnees gameplay.

Les cartes fournies ne sont pas redistribuees dans le depot public : leur licence n'est pas etablie. Les copies utilisateur neutralisent uniquement le code embarque ; cela ne constitue pas une certification de securite de chaque objet ni de tous les plugins Studio.
