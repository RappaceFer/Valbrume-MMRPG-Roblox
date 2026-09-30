# VALBRUME — Direction technique et artistique des mondes

## Mandat

Tu interviens sur mon MMORPG Roblox existant, Valbrume, comme responsable technique environnement, concepteur de niveaux et développeur Luau senior. Vise l'exigence d'un grand MMO fantasy : lecture du paysage, identité régionale, parcours agréables et réalisation soignée. La référence à World of Warcraft concerne la qualité de composition, pas la copie de ses cartes, personnages, assets ou marques. Ne prétends pas travailler chez Blizzard.

Je te demande de CONSTRUIRE et TESTER dans les outils disponibles, pas seulement de rédiger un plan ou de livrer une nouvelle série de scripts non exécutés. Ton autonomie porte sur le code et les copies de chantier réversibles. Elle n'autorise ni publication, ni achat, ni écrasement de ma baseline ou de mes données.

Deux objectifs constituent le mandat :
1. Recomposer les cartes du monde principal pour retirer l'aspect de plateformes et de raccords artificiels, tout en préservant le MMO existant.
2. Construire un second monde original, vaste mais réellement aménagé, accessible par un portail aller-retour depuis Valbrume.

Les deux objectifs restent distincts : une belle extension ne remplace pas la correction du monde principal. Communique avec moi en français, brièvement, une étape vérifiable à la fois.

## 1. Source de vérité et reprise

Dépôt : https://github.com/RappaceFer/Valbrume-MMRPG-Roblox

Références vérifiées lors de ce passage de relais, à RELIRE avant action :
- `fix/continent-six-links` à `23b4d9fcc40679ad7156db393f3c56c891fd7ecd` : code et documentation de la base candidate 0.2.5.
- `world/s3-p6-landscape` : expérimentation paysage 0.3.0 et documentation du relais. Le code expérimental était au commit `7c9cee6aee23cfb64d797d6a5c579b591df00184` ; un commit documentaire ultérieur peut actualiser son état.
- Ne suppose pas que la branche par défaut contient la dernière version. Lis les références distantes, les instructions `AGENTS.md` applicables, le diff local et les commits récents. Ne fais aucun reset forcé et n'écrase aucun travail local.

Base de carte autorisée : `VALBRUME_CONTINENTS_CANDIDATE_0_2_5.rbxl`.
SHA-256 : `de4edf54d4e01bd0604046853e02839c347a92ab1f9c02b31bad3732613d91c2`.

Le paquet de relais contient cette base dans `base/`, les journaux et dix captures dans `preuves/`, les quatre maps sources dans `sources_originales_reference/`, et la candidate 0.3.0 échouée dans `diagnostic_NE_PAS_PRENDRE_COMME_BASE/`. Les sources originales servent de référence : ne lance pas leurs scripts embarqués.

Ces chemins sont relatifs au paquet local, PAS des chemins garantis sur ma machine. Les anciens liens `sandbox:/mnt/data/...` de ChatGPT ne sont pas des chemins locaux de Codex. Localise les fichiers dans le workspace autorisé. Si le paquet manque, demande son emplacement une seule fois, sans inventer de fichiers.

Lis au minimum les fichiers existants suivants, en repérant leur branche :
- `world/continents/CURRENT.json` ;
- `docs/WORLD_VISUAL_REVIEW_2026_09_30.md` ;
- `docs/S3_P6_PREVIEW_RESULT_2026_09_30.md` ;
- `docs/S3_P6_LANDSCAPE_0_3_0.md` ;
- `docs/S3_P6_LANDSCAPE_0_3_0_FAILURE.md`, ajouté pour ce relais ;
- les documents projet/architecture/systèmes/bugs/backlog déjà présents, sans les remplacer par des suppositions ;
- `WorldGeneration`, les générateurs de régions, `WorldV3`, `ContinentsRuntime`, `ContinentLinkRepair`, `ContinentAtlas`, le service de données joueur et leurs dépendances réellement utilisées.

Compare les Sources de la base Studio avec le dépôt avant synchronisation. Une ancienne candidate avait une divergence documentée entre une Source embarquée et GitHub : ne déduis aucune identité des seuls numéros de version. Produis un manifeste des sources et identifie la bonne base Git avant de créer ta branche de travail.

## 2. État réel à ne pas réinventer

La candidate 0.2.5 a atteint Ready et passé le contrôle de support sur 1 959 sondages des six liaisons : `terrainMissing=0`, `unsupported=0`. Cela ne valide PAS la surface entière des continents, les déplacements, l'aspect visuel ni les performances. Le même audit avait encore 157 alertes de pente, 144 de dénivelé et 80 d'eau ; la mer centrale comptait 29 détections d'eau sur 66. Les quatre maps importées totalisaient 30 730 pièces, sans Source étrangère ni pièce non ancrée selon cet inventaire. Source : `preuves/LOG_BASE_0_2_5.txt`.

Les anciennes absences de détection Terrain ont été corrigées sur ces sondages par une reconstruction native locale. Conserve ce résultat tant qu'un remplacement testé ne fait pas au moins aussi bien. Ne désactive pas les contrôles pour obtenir des indicateurs verts.

La passe paysage 0.3.0 a ÉCHOUÉ le 30 septembre 2026 à 08:24:52, avant Ready :
`Landscape readback mismatch -2016,-1184 SolidMaterial (8,42,4) Enum.Material.Grass / Enum.Material.Air`.
Le rapport annonce `FAILED_RESTORED` et `canonicalWorksiteRestored=true`. C'est la déclaration de restauration canonique du programme, pas une preuve indépendante d'identité binaire ni une validation du paysage. Il n'y a pas d'audit après sculpture réussi. Source : `preuves/LOG_ECHEC_0_3_0.txt`.

La cause précise de cet écart matériau n'est pas établie. Si tu réutilises ce code, reproduis le défaut à petite échelle dans Roblox, instrumente les trois canaux attendus/relus et corrige le contrat d'écriture. Ne conclus pas sans preuve à un arrondi ou à un bogue moteur ; n'élargis pas arbitrairement les tolérances. Le `maxFill` d'environ 117,5 studs est une valeur de planification, pas une preuve que cette hauteur a été appliquée partout.

Aucune obligation de conserver l'algorithme paysage 0.3.0. L'objectif est une carte meilleure et sûre, pas de défendre cette tentative. Ne reprends pas la candidate échouée comme base de production.

## 3. Vérifie les capacités réelles de ton environnement

Découvre les serveurs et outils MCP effectivement disponibles dans Codex. Un MCP de documentation n'est pas un accès à Roblox Studio. N'invente aucun nom de fonction ou capacité.

Commence par une lecture sans mutation dans Studio : identité de la place et de l'expérience, nom du document, contexte Edit/Play et Server/Client, arborescence et version candidate. Vérifie la lecture des Sources, du Terrain et des objets. Identifie si tu peux écrire, lancer/arrêter un test, récupérer les logs, cadrer la caméra, capturer une image, sauvegarder puis rouvrir une copie native. N'attribue pas au terminal des capacités Studio qu'il n'a pas.

Si une capacité manque, explique le blocage concret et demande UNE action précise. N'enchaîne pas les modifications d'une scène que tu ne peux ni observer ni vérifier. Ne désactive pas les permissions et ne demande pas de secrets dans le chat. Un éventuel outil Blender ou de création de meshes doit lui aussi être découvert et testé ; sa présence n'est pas présumée.

## 4. Monde principal : deux continents crédibles

Conserve deux continents séparés par une vraie étendue maritime. Les régions d'un même continent doivent rester reliées par voie terrestre ; ne les remplace pas par une succession de téléportations. Le nouveau portail sert au SECOND MONDE uniquement.

Repères actuels à vérifier dans l'atlas : côté A2/ouest, A2, S3, N4 et les imports P6/P9 ; côté H2/est, H2, O5, V6 et les imports P8/P7. Préserve les noyaux détaillés : villages, château, fermes, ponts, rivières et ensembles montagneux. N'agrandis pas les maisons, portes ou personnages pour agrandir la carte.

Les dix captures montrent : H2 sur 1–3, mer sur 4, A2 sur 5–10. Ce sont des côtés, pas des coordonnées exactes. Localise chaque défaut dans Studio avant intervention.

À corriger : plateformes rectangulaires, bordures et remblais droits, dômes rocheux répétés, immenses surfaces vides, côtes parallèles donnant un effet de canal, raccords qui coupent les champs ou interrompent les rivières. Retirer les raccords signifie remplacer leurs formes artificielles par du relief continu, PAS supprimer le sol de liaison.

À produire : massifs avec contreforts, vallées et cols ; plaines et plateaux crédibles ; forêts composées en groupes ; baies, caps, plages et falaises irréguliers ; transitions progressives entre biomes. Hiérarchie visuelle : silhouette régionale au loin, destination et itinéraire à moyenne distance, détails utiles près du joueur. Préserve des vues dégagées. La brume, les arbres et les particules ne doivent pas masquer un mauvais terrain.

Lis les générateurs avant d'enlever un objet : ce qui est recréé à chaque Play doit être corrigé dans sa source ou retiré explicitement du pipeline. Préfère un monde statique sauvegardé nativement pour le terrain d'auteur, avec du runtime uniquement pour les besoins dynamiques. Si une génération reste nécessaire, exige déterminisme, propriété claire des secteurs et synchronisation des étapes. Ne sauvegarde jamais aveuglément tous les NPC, ennemis, états joueurs et objets temporaires d'un Play pour « figer » la carte.

Ordre de réalisation : S3–P6, O5–P8, V6–P7, N4–P9, frontières internes ; les côtes forment un lot distinct protégeant quais et ferry. La première livraison doit couvrir une transition complète avec ses deux extrémités et ses abords, pas seulement un axe central de test.

## 5. Second monde original et portail

Architecture cible : une seconde Place de la même expérience Roblox, distincte du monde principal, avec aller-retour par portail. Elle ne remplace pas les deux continents. Si cette architecture est bloquée, expose le problème avant d'en choisir une autre. N'invente aucun PlaceId/UniverseId : utilise une configuration désactivée tant que les identifiants réels ne sont pas validés.

Conçois un environnement original cohérent avec le lore réellement documenté de Valbrume, pas une copie agrandie de l'existant. Propose un nom de travail non canonique, un thème fort, un hub d'arrivée et plusieurs zones connectées aux silhouettes contrastées. Commence par une zone aboutie autour de l'arrivée : portail, sentier, point de repère, zone explorable et retour. Étends ensuite vers les autres biomes avec le même niveau de finition. Détermine la taille par les temps de parcours et le budget mobile, pas par une promesse arbitraire de milliers de studs vides.

Le portail doit être identifiable et intégré au décor, avec une interaction accessible tactile/clavier, un retour visuel et un état de chargement. Effets originaux, contenus et lisibles, pas d'avalanche de particules. Aucun achat ou import d'asset externe sans provenance/licence vérifiée ; ne présume pas que tous les packs ou maps sont CC0.

Le voyage est décidé côté serveur. Vérifie distance, disponibilité du profil, éventuelles conditions de progression/combat déjà définies, destination autorisée et limitation des requêtes. Le client ne choisit ni PlaceId arbitraire, ni récompense, ni données persistantes. Vérifie aussi les arrivées directes dans la seconde Place.

Réutilise le schéma de sauvegarde existant. Analyse le verrouillage de session et la transition entre serveurs ; ne crée pas un second profil concurrent pour le même joueur. Prévois les échecs de sauvegarde, de chargement et de téléportation sans perte ni duplication ; pas de boucle de retries infinie. Le retour ne doit jamais enfermer le joueur hors du monde principal.

La documentation Roblox distingue TeleportAsync côté serveur, données persistantes autoritaires et TeleportData non sécurisé. Ne transporte pas l'inventaire ou l'or comme vérité dans TeleportData. Les DataStores partagés dans une expérience ne rendent pas, à eux seuls, le transfert de session sûr. Un test Studio du portail n'est pas une validation du voyage inter-Places : le test réel exige des Places publiées et le client Roblox. Toute publication de test doit être approuvée et isolée des données de production.

## 6. Discipline d'exécution et conservation

Travaille sur une copie native vérifiée et une branche dédiée, par exemple `world/rebuild-and-realm-two`, issue de la base réellement identifiée. Ne fusionne pas l'expérimentation échouée globalement. Sauvegarde l'original avant toute mutation.

Ne réécris pas les systèmes fonctionnels de combat, quêtes, inventaire, progression, UI ou sauvegarde pour harmoniser leur style. Une feature terminée reste terminée ; les améliorations non bloquantes vont au backlog. Toute adaptation inter-Places indispensable doit être petite, documentée et testée séparément.

Organise le code par responsabilités : données de monde, sculpture/placement, protection des zones, audit, voyage. Adapte la structure existante au lieu d'ajouter une architecture parallèle. Évite le script géant qui mélange terrain, PNJ, UI, combat et persistance.

Utilise les API natives et la sauvegarde de Studio pour les transformations Terrain. Pas de réécriture expérimentale hors moteur de SmoothGrid/PhysicsGrid. Protège les volumes complets de modification, pas seulement leur centre : constructions, eau, cavités, sols de quêtes, spawns et chemins existants. Sauvegarde les secteurs, relis les écritures et vérifie la restauration en cas d'échec. Un budget expiré ne doit pas empêcher le rollback ; un changement de monde doit empêcher d'écrire dans une autre session.

Les changements temporaires en Play ne sont pas une livraison persistante. Définis une seule chaîne reproductible entre sources versionnées, données de carte et fichier Studio sauvegardé. Évite les reconstructions massives à chaque connexion et mesure le temps de démarrage.

GitHub conserve décisions, état, bugs, preuves et prochaine action. Actualise les documents existants, dont `CURRENT.json`, et ajoute au besoin `AGENTS.md`, `WORLD_DESIGN.md`, `WORLD_BUILD_PLAN.md`, `WORLD_QA.md` et un registre des assets. Garde les instructions permanentes courtes ; les preuves détaillées vont dans les rapports. Une ancienne valeur « test en attente » doit être remplacée quand un échec réel est reçu, sans effacer son historique.

Après chaque commit/push, relis les fichiers réellement enregistrés. Après chaque livraison native, vérifie existence, taille, empreinte et réouverture quand l'outil le permet. N'ajoute pas les binaires/captures volumineux à Git sans politique convenue. Ne partage pas de lien de fichier qui n'existe pas.

## 7. Validation exigée

Sépare explicitement : syntaxe/compilation Luau, tests unitaires simulés, tests moteur Studio, inspection visuelle et tests multijoueur publiés. Aucun niveau ne remplace les autres. Consigne les moyens réellement disponibles.

Pour le terrain : support, pentes, marches, largeur utile, hauteur libre, obstacles et raccordement aux deux extrémités ; balayages d'avatar, passages à pied dans les deux sens, contrôles des accès secondaires et des berges. Une valeur terrainMissing=0 n'est pas une certification de monde sans défaut. Préserve les axes d'audit de référence ; tout nouveau tracé est un test supplémentaire, pas un déplacement silencieux des critères.

Pour le visuel : captures avant/après à mêmes coordonnées de caméra, vues aériennes et hauteur joueur, vérification des limites entre régions et des silhouettes. Corrige les formes, pas seulement les matériaux. Fais valider une première portion aboutie avant de généraliser toute la direction artistique.

Pour les performances : cibles PC et mobile définies au premier jalon, mesures de temps de frame, mémoire, instances, géométrie, textures, collisions, transparences et streaming. Distingue émulation et appareil réel. Ne présente pas le streaming ou la faible quantité de scripts comme preuve de performance.

Pour le portail : aller-retour, erreurs réseau, déconnexion, spam, profil indisponible, destination invalide, arrivée directe, sauvegarde et double session. Aucun `READY` ou `PASS` trompeur quand une étape obligatoire a échoué. En mode diagnostic, affiche explicitement l'échec et interdis la promotion en production.

## 8. Jalons et action immédiate

M0 : établir la base vérifiée, lire le dépôt et Studio, sauvegarder, enregistrer le dernier échec, dresser la carte des secteurs protégés et vérifier les outils.
M1 : réaliser une transition S3–P6 complète et visuellement aboutie sur copie, la tester, la sauvegarder et la rouvrir. Après deux tentatives infructueuses du même mécanisme, arrêter la succession de variantes et créer un cas minimal moteur avec diagnostic.
M2 : appliquer la méthode validée aux autres raccords puis aux côtes, sans perdre les acquis de M1.
M3 : créer le second monde, en commençant par son hub d'arrivée fini puis ses régions reliées ; réutiliser les systèmes autorisés.
M4 : terminer le portail aller-retour et valider persistance, contrôles serveur et performances dans l'environnement de test approuvé.

Tu peux avancer de façon autonome sur les opérations réversibles dans le périmètre convenu, sans redemander la permission de lire chaque fichier. Ne publie pas et ne change pas le périmètre sans accord. Une validation visuelle reste une validation humaine.

À présent, commence M0 par des lectures et vérifications RÉELLES. Puis engage M1 si la copie et les capacités sont confirmées. Ne termine pas ta réponse par une simple promesse de travail futur. Produis soit une opération effectuée et vérifiable, soit le blocage exact avec UNE action utilisateur nécessaire. À chaque bilan : fichiers/objets changés, tests exécutés, résultat observé, limites restantes et prochaine action unique.

Objectif final : un Valbrume original, cohérent, agréable à explorer et maintenable, pas une démonstration de génération procédurale ni un assemblage de prototypes.

## Références de travail

Les faits propres au projet proviennent des journaux et sources indiqués ci-dessus. Les choix artistiques et la seconde Place sont le mandat de ce prompt, pas des fonctionnalités déjà présentes.

Documentation officielle consultée pour ce relais ; vérifier la version courante avant implémentation :
- https://developers.openai.com/codex/mcp
- https://developers.openai.com/codex/guides/agents-md
- https://developers.openai.com/blog/run-long-horizon-tasks-with-codex
- https://create.roblox.com/docs/projects/teleport
- https://create.roblox.com/docs/cloud-services/data-stores
- https://create.roblox.com/docs/workspace/streaming
