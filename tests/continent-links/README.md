# Tests locaux des six raccords

Depuis la racine du depot, avec Lua 5.4 installe :

```sh
VALBRUME_LINK_RELEASE="$PWD" lua5.4 tests/continent-links/check_links.lua
```

Les deux fixtures sont des copies identiques de l'atlas candidate 0.1 et du Layout V3.1. Le code de production est celui de src, pas une reimplementation dans le test. Les API du moteur sont explicitement simulees pour le test du constructeur. Ces tests ne compilent pas le Luau de Roblox, ne chargent pas les rbxl et ne prouvent pas les collisions ou les performances du moteur.

Le fichier .rbxl, le manifeste de comparaison propriete par propriete et le script de fabrication sont conserves dans l'artefact de conversation. Les cartes tierces restent hors du depot public tant que leurs licences ne sont pas verifiees.
