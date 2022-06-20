

Note de patch 3739 (20 juin 2022)
==========================

## Correction de Bug

- (#3978) Corriger les améliorations des missiles tactiques des (S)ACUs

## Contributeurs

- Jip (#3978)

Note de patch 3738 (19 juin 2022)
=================================

Le mois dernier a été passionnant - c'est le moins qu'on puisse dire.

Du point de vue du développement, nous allons bientôt être en mesure de fournir un environnement de création moderne et interactif à notre communauté. Avec le travail d'Eluvatar, une extension Visual Studio Code (VSC) est sur le point de sortir, et fournira un support intellisense pour les scripteurs de carte, les concepteurs de mods et les développeurs de jeux. Grâce au travail d'Ejsstiil, le débogueur Lua intégré au jeu est à nouveau entièrement fonctionnel lorsque vous travaillez à partir de votre environnement de développement. Les programmeurs comprennent à quel point ces fonctionnalités sont essentielles pour la quasi-totalité des développements.

Et du point de vue de l'utilisateur, le jeu n'a jamais été aussi performant. Plus précisément, les batailles ASF tristement lentes ont été abordées. Pour la majorité des matchs, le jeu ne ralentit plus, en supposant qu'aucun des joueurs ne joue sur le PC de leurs grands parents.

Tout cela occulte tous les autres travaux critiques qui ont été effectués le mois dernier grâce à tous les contributeurs, avec notamment SpikeyNoob, Hdt80bro et LilJoe7k4 qui ont apporté leurs premières contributions au code du jeu.

Un grand merci à tous ceux qui ont rendu ce patch possible.

J'espère que vous apprécierez tous, le manque d'APM, lors d'un match tardif de Seton's Clutch,

Amicalement,

Jip

## Correction de Bug

- (#3896, #3899, #3901) Correction d'éléments d'interface qui ignoraient la commande UI_ToggleGamePanels

- (#3909) Correction des notifications d'améliorations des UBC qui se superposaient sur le deuxième écran lors de l'utilisation de l'écran partagé

- (#3876) Nettoyage des cibles prioritaires des armes des tourelles de défenses
    Cela corrige le problème selon lequel les tourelles de défense ne tiraient pas lorsqu'une cible était à portée

- (#3923, #3924) Correction d'un problème lié à l'économie, qui vous permettait d'obtenir des ressources gratuitement
    A toutes fins utiles, nous n'entrerons pas dans les détails ;)

- (#3946) Correction des dégâts des projectiles enfants, tels que les missiles tactiques Cybran après leur séparation

- (#3961) Correction d'un problème avec les os d'attachement du transport Aeon tech 2
    En conséquence, le transport Aeon tech 2 peut maintenant transporter jusqu'à 3 unités tech 3, au lieu de 2.

- (#3966) Correction des points d'arrêt pour diverses usines
    Les points d'ancrage n'étaient pas correctement alignés, en conséquence les vaisseaux avaient du mal à quitter le quai. Ceci était particulièrement visible sur les usines navales de la faction Cybran.

## Fonctionnalités

- (#3887, #3968) Introduction de la prise en charge d'Intellisense pour l'extension FA Visual Studio Code (VSC)
    En tant que scripteurs de cartes, créateurs de mods et développeurs de jeux, nous vivions dans une grotte. Mais plus maintenant - grâce au travail sur l'extension (FA VSC) et au travail dans cette demande d'amélioration, nous introduisons petit à petit des annotations dans le code.

    En parlant en langage programmeur : c'est comme l'introduction de Typescript, après avoir travaillé pendant des années sur des bouts en Javascript.

    Cela fonctionne également lorsque vous n'avez pas d'environnement de développement pour le dépôt GIT FA sur votre système, consultez le fichier readme sur la page Github du dépôt FA pour plus d'informations.

- (#3938) Résurrection du débogueur lua de FA
    Réhabilite le débogueur lua de FA, lorsque vous travaillez à partir de votre environnement de développement. Vous permets de définir des points d'arrêt et d'inspecter la pile, les variables locales et globales. Extrêmement utile lorsque vous déboguez vos cartes, vos mods et lorsque vous travaillez sur le développement de jeux en général.

    Nécessite un environnement de développement pour fonctionner. Vous pouvez configurer cela en une demi-heure, consultez le fichier readme sur la page Github du dépôt FA pour plus d'informations.

- (#3883) Introduction d'une interface utilisateur pour suivre le comportement des MassFab
    L'élément d'interface se trouve à droite du panneau d'économie. Il peut être déplacé horizontalement à l'aide du bouton central de la souris.

- (#3889, #3906) Amélioration de la fenêtre des paramètres du chat en jeu
    Résout divers petits problèmes avec le panneau de discussion et vous permet de visualiser et d'inspecter les modifications apportées aux paramètres en direct en utilisant le bouton Appliquer.

- (#3863) Customisation du complexe optique quantique Aeon
    L'unité était inachevée à tous égards - dans le cadre d'une session de programmation en direct, nous avons amélioré les effets visuels et l'esthétique.

- (#3905) Ajout de directives permettant de se créer un environnement de développement pour FA sur un système d'exploitation basés sur Linux
    Pour plus d'informations, consultez les instructions de travail de la page github.

- (#3933) Affichage, sur le tableau de bord par défaut, de la zone jouable de la carte au lieu de sa taille de base 

- (#3835) Introduction d'un builder pattern pour créer des éléments d'interface utilisateur
    Une approche alternative et plus moderne de la création, du positionnement et de la vérification des éléments de l'interface utilisateur.

- (#3972) Ajout de possibilité de re-vérifier manuellement les cibles des armes des unités sélectionnées via un raccourci clavier.
    Conformément à la #3857, les armes de la majorité des unités ne revérifient pas leurs cibles. Habituellement, cela n'est pas nécessaire, mais cela entraîne une baisse importante des performances. Ce nouveau raccourci est introduit pour vous permettre de laisser vos unités recibler sur commande pour les situations où cela est nécessaire.

    Vous pouvez trouver le raccourci en recherchant 'recheck' dans le menu des raccourcis.

### Pour les développeurs de cartes, de mods et d'IA

- (#3884) Ajout de prise en charge d'un drapeau unit.IsCivilian
    Introduit un drapeau facile à utiliser pour indiquer si une unité appartient à une armée civile

- (#3894) Ajout de prise en charge d'un drapeau unit.ImmuneToStun
    Introduit un drapeau facile à utiliser pour immuniser une unité contre les étourdissements

- (#3894) Ajout de prise en charge d'un drapeau shield.SkipAttachment
    Introduit un drapeau facile à utiliser pour permettre aux boucliers de fonctionner lorsqu'ils sont attachés

- (#3944) Ajout de la prise en charge de plusieurs animations d'amélioration via la fonction unit.GetUpgradeAnimation

## Performance

- (#3845) Réduction des allocations de table lors de la définition des cibles prioritaires des armes

- (#3875, #3945) Réduction de l'impact des unités, des armes et des accessoires, sur la mémoire

- (#3891, 6fefe78) Nettoyage du rayon de surveillance des unités
    Le rayon de surveillance est utilisé par les unités en mouvement d'attaque ou en patrouille pour trouver et engager des unités hostiles dans leur environnement. La valeur était partout et pouvait causer de sérieux ralentissements, surtout en fin de partie.

- (#3892, #3903) Nettoyage des tailles des hitbox des unités aériennes
    Toutes les unités aériennes non expérimentales avaient une taille de hitbox de 1 - la taille d'un mur. À cause de cela, il y avait deux problèmes : en raison de leur proximité, cela a introduit des chevauchements de modèles qui brisent l'immersion du jeu. Et en raison de leur densité, cela entraîne des problèmes de performances. Désormais, tous les bombardiers ont une taille de hitbox de 4, tous les vaisseaux de combat (Canonnières) ont une taille de hitbox de 3 et tous les intercepteurs ont une taille de hitbox de 2.

- (#3930) Suppression de la dépendance au dossier schook
    Facilite la maintenance du code et réduit le nombre d'ancrage avec le jeu.

- (#3857, #3931, #3950) Nettoyage des paramètres d'arme
    Trois paramètres cruciaux des armes déterminent leurs comportement et leurs performances : l'intervalle de contrôle de la cible, le rayon de suivi et le comportement de reciblage. L'intervalle de contrôle de la cible de l'arme est désormais basé sur la cadence de tir de l'arme. Le rayon de suivi des armes est réduit à 7 % pour les unités autres qu'anti-aériennes et à 15 % pour les unités anti-aériennes. Le reciblage est désactivé sauf si l'arme est considérée comme de l'artillerie ou antiaérienne.

    Cela modifie légèrement le comportement des unités, en standardisant les paramètres de leurs armes. En retour, le jeu fonctionne beaucoup mieux et les unités répondent de manière plus cohérente en fonction de leurs statistiques d'armes.

- (#3949) Réduction de l'impact des objets de détails sur le FPS
    Aligne la distance de rendu des objets de détails (arbres, pierres ect.) avec le jeu de base

- (#3943, #3951) Réduction de l'impact des modèles 3D sur les FPS
    Aligne le rendu de divers modèles 3D avec leur taille respective. A titre d'exemple, le nœud de contiguïté entre deux batiments adjacent était modélisé jusqu'à la même distance que des boucliers.

- (#3967, #3965) Réduction de l'impact des projectiles sur les FPS
    Assainissement de LODCutoff des projectiles qui ont un mesh. Le projectile moyen est basé sur un émetteur, mais certains utilisent un maillage. Ces maillages étaient visibles à des distances très éloignées, ce qui les rendait visibles même s'ils étaient complètement cachés derrière la superposition stratégique des projectiles (points).

Traduit avec www.DeepL.com/Translator (version gratuite)

## Autres changements

- (#3885) Correction des argumentations pour l'IA Hunter

- (#3879) Correction d'un problème mineur avec le lobby

- (#3881) Modification de l'emplacement des fichiers d'effets du Lighting Tank
    Comme nous l'a dit Rowey - nous serions perdus sans lui.

- (#3895) Correction de problèmes mineurs avec les fichiers d'initialisation

- (#3907, #3926) Amélioration de la commande /nomovie

- (#3908) Introduction de la commande /nomusic

- (#3904) Correction du menu des options du jeu qui n'était pas défilable par la molette de la souris

- (#3913) Correction des problèmes avec le .gitignore du dépôt

- (#3921) Ajout d'une info-bulle au bouton des notes de mise à jour dans le lobby
    Le puissant Rowey - à nouveau au travail.

- (#3882) Correction des noms des attaches du modèle, des ruches (cybran) améliorées

- (#3925) Correction de la taille et de la disposition de divers éléments de l'interface utilisateur

- (#3912, #3724) Ajout des Blueprint et des scripts, du jeu de base, restant
    Facilite considérablement la maintenance du code du jeu dans son ensemble.

- (#3947) Correction des ingénieurs UEF n'appliquant pas leur animation d'eau

- (#3948) Correction d'un problème rare où le réglage de la vitesse des unités aéroglisseur (lent) provoquait une erreur

- (#3941) Correction de catégories non correspondantes pour l'Atlantis

- (#3969) Correction des missiles Flayer (AA) du croiseur UEF tech 2
    Les missiles utilisaient un mesh de torpille, au lieu du mesh typique de la FTU AA Flayer utilisé par les sams.

## Contributeurs

- LilJoe7k4: (#3845)
- speed2: (#3885)
- 4z0t: (#3879, #3883, #3835)
- Jip: (#3895, #3894, #3884, #3875, #3863, #3891, #3892, #3903, #3923, #3913, #3924, #3857, #3931, #3912, #3724, #3944, #3947, #3946, #3945, #3948, #3950, #3972)
- Ejsstiil: (#3896, #3889, #3899, #3907, #3908, #3909, #3904, #3906, #3901, #3926, #3925, #3937)
- Madmax: (#3863, #3951, #3943, #3961)
- SpikeyNoob: (#3905)
- Tagada: (#3876)
- Rowey: (#3921, #3881, #3882)
- Hdt80bro: (#3933)
- Eluvatar: (#3887, #3968)
- Uveso: (#3941)
- M0rph3us (#3969, #3967, #3965)
- KionX (6fefe78)

## Translators

- 4z0t (Russian)
- M0rph3us (French)
- Unknow (French)
- Carchagassky (French)
