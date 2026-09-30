# Paysage 0.3.0 — échec moteur reçu et passage de relais

Date : 30 septembre 2026. Source : journal utilisateur `Texte collé(20260930-062529).txt`, 10 228 octets, SHA-256 `45c9abb4659c583476b372274d843f63040013c8b4172e5f7d6c0794a61cfffb`.
Génération : `ca4b619b-ea88-4dfd-8def-2b131b0bb57c`.
Code relu sur `world/s3-p6-landscape` : `7c9cee6aee23cfb64d797d6a5c579b591df00184`.
Cette mise à jour est DOCUMENTAIRE : aucun runtime, aucun Terrain et aucun binaire ne sont corrigés.

## Résultat observé

À 08:24:49, le correctif de support 0.2.5 annonce `postMissing=0` sur 1 959 sondages, avec 43 tuiles rafraîchies et 86 écritures de rafraîchissement. Ce résultat précède la sculpture 0.3.0 et ne la valide pas.

À 08:24:51, le plan de sculpture annonce 5 918 colonnes, 120 tuiles et 46 objets protégés. Les hauteurs des extrémités mesurées sont 29 et environ 42,1484 studs.

À 08:24:52, l'étape s'arrête sur :

```text
Landscape readback mismatch -2016,-1184 SolidMaterial (8,42,4) Enum.Material.Grass / Enum.Material.Air
status = FAILED_RESTORED
canonicalWorksiteRestored = true
changedTiles = 7
writes = 16
after = []
```

L'erreur vient de la vérification de relecture dans `LandscapeS3P6/Build.lua`, appelée par `OpenWorldBiomeV28`. Le programme annonce avoir restauré les tuiles écrites à partir de ses snapshots canoniques. Ce n'est ni une preuve indépendante d'identité binaire du Terrain, ni un test de déplacement. La génération s'arrête avant Biome/Ready ; aucun audit après sculpture réussi n'est fourni.

Le journal ne donne pas les occupations solide/liquide attendues et relues de la cellule fautive. Il ne permet donc pas d'attribuer avec certitude Grass/Air à un arrondi, à une normalisation de cellule vide, à un délai, à une interférence ou à un défaut moteur. La prochaine reproduction doit distinguer ces hypothèses au lieu de supprimer le contrôle. La valeur maxFill d'environ 117,5 studs appartient à la planification, pas à un relevé de modification effectivement appliquée à toutes les colonnes.

## Base conservée

Repartir de `VALBRUME_CONTINENTS_CANDIDATE_0_2_5.rbxl` sur COPIE, comme autorisé par l'utilisateur. Son succès concerne le support sondé ; le rendu, les pentes, l'eau et la mer centrale restent à revoir.

Empreintes revérifiées dans les fichiers disponibles au relais :
- Candidate 0.2.5 : 6 164 684 octets ; SHA-256 `de4edf54d4e01bd0604046853e02839c347a92ab1f9c02b31bad3732613d91c2`.
- Chantier 0.3.0 échoué : 6 176 651 octets ; SHA-256 `399ebac40cb65355e0098175b21fc1d7278fd8b8bedb021752aa96ea183c38a1`.

Aucune nouvelle candidate 0.3.1 n'est fournie à cette étape. Le fichier 0.3.0 n'est conservé que pour reproduire le défaut. Le statut historique « Studio pending » est remplacé par le résultat reçu, sans effacer les tests locaux antérieurs qui ne constituaient pas une validation moteur.

## Mandat demandé pour Codex

L'utilisateur demande un prompt professionnel pour poursuivre dans VS Code avec MCP : reprendre la géographie du monde principal, retirer l'aspect de raccords artificiels et créer un second monde original accessible par portail. Le brief complet est `docs/PROMPT_CODEX_VALBRUME.md`.

La seconde Place dans la même expérience est l'architecture cible proposée par ce brief, pas une ressource déjà créée ni une publication autorisée. Les deux continents actuels restent connectés par leurs régions ; le portail concerne le second monde. Les systèmes fonctionnels de gameplay et de sauvegarde sont conservés, avec seulement les adaptations inter-Places indispensables après audit.

Codex doit d'abord vérifier ses accès locaux, les outils MCP effectivement disponibles et la scène ouverte. Ne pas présumer qu'un MCP documentaire peut modifier Studio. Le nom du modèle n'est pas une preuve de ces capacités. L'autonomie est limitée au chantier réversible ; publication, dépenses, données de production et écrasements restent interdits sans accord.

## Paquet de relais fourni dans la conversation

`VALBRUME_PASSAGE_CODEX.zip` regroupe le prompt, la candidate 0.2.5, les deux journaux utiles, les dix captures, les quatre maps sources de référence et le chantier échoué séparément. Les copies des binaires et preuves sont inchangées ; leurs empreintes sont dans le manifeste du paquet. Les sources originales ne doivent pas être exécutées automatiquement. Les binaires et captures ne sont pas ajoutés à Git par ce commit.

Prochaine action : arrêter le Play échoué, ouvrir le clone Git dans VS Code, rendre le paquet décompressé accessible et lancer le prompt. Pas de nouvel installateur à exécuter dans Roblox pour ce relais.
