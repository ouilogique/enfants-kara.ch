# Memoire de projet

## But du fichier
- Ce fichier sert de memoire persistante pour les sessions futures sur ce projet.
- Il doit contenir uniquement les instructions durables dont l'assistant a besoin pour reprendre le travail efficacement.
- Il ne doit pas contenir les details temporaires, les notes de travail jetables, ni les informations faciles a redecouvrir.

## Regle de maintenance
- Mettre ce fichier a jour a chaque fois que l'utilisateur donne une instruction qui restera utile dans de futures sessions.
- Ne consigner que les preferences, contraintes, conventions et decisions persistantes.
- Garder une structure simple et concise.

## Instructions persistantes actuelles
- Maintenir ce fichier a jour a chaque nouvelle instruction persistante donnee par l'utilisateur.
- Utiliser ce fichier comme source principale de contexte a relire au debut des futures sessions sur ce projet.
- Le projet consiste a migrer un site miroir Jimdo vers une structure compatible Hugo.
- Privilegier une sortie directement exploitable par Hugo, notamment dans `content/`.
- Avant une operation importante ou ambigue, indiquer brievement si la consigne utilisateur peut etre optimisee ou resserree.
- Privilegier un site Hugo autonome, avec les ressources distantes rapatriees localement quand c'est pertinent.
- Les images du contenu sont relocalisees dans `static/media/jimdo`.
- Les documents telechargeables rapatries sont relocalises dans `static/downloads`.
- Exclure de la sortie Hugo les pages techniques, les pages protegees et les feuilles vides sans contenu editorial exploitable.
- Normaliser en Unicode NFC tout ce qui est controle par le projet, en particulier le contenu texte, les aliases et les chemins generes.
- Le menu du site doit refleter directement la structure des fichiers sous `content/`, avec navigation recursive pour les niveaux imbriques.
- L'ordre de navigation ne doit pas etre alphabetique quand le site d'origine definissait un autre ordre; conserver cet ordre via les `weight`, y compris pour les pages de niveau 3.
- Quand le libelle de navigation d'origine differe du titre affiche dans la page, conserver ce libelle dans le menu Hugo via `linkTitle`, sans forcer le titre de la page a etre identique.
- Relocaliser les ressources distantes encore utiles au site dans le projet local et eviter de laisser des URL distantes residuelles dans le contenu livre.
- Pour les images locales sous `static/media/jimdo`, privilegier une restauration depuis l'historique Git avant tout reteledchargement. Ne pas vider ce dossier lors d'une relance du script si aucun URL distant n'est encore present dans `content/`.
