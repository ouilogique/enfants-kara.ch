# TODO

- Supprimer les `# ...` redondants en debut de contenu quand le template affiche deja un `h1`, pour eviter les doubles titres masques en CSS.
- Revoir la regle `.content h1:first-child { display: none; }` dans `static/style.css` et la supprimer une fois les contenus nettoyes.
- Simplifier la gestion des URLs d'assets et supprimer la reecriture runtime dans `static/scripts.js` si Hugo peut produire directement les bons chemins avec `relURL` et les render hooks.
- Verifier la whitelist de reecriture restante dans `static/scripts.js` tant qu'elle existe, pour eviter les oublis lors de l'ajout de nouveaux assets.
- Sortir la table `section -> image de fond` du layout `layouts/_default/baseof.html` vers une configuration plus maintenable (`params` ou front matter de section).
- Verifier toutes les sections de niveau 1 pour s'assurer qu'elles declarent explicitement leur image de fond cible.
- Uniformiser le traitement des liens externes entre `layouts/_markup/render-link.html` et `static/scripts.js` afin d'eviter la double logique.
- Remplacer ou verifier les liens externes encore en `http://` dans le contenu quand une version `https://` existe.
- Localiser la police actuellement chargee depuis Google Fonts pour rester coherent avec l'objectif de site Hugo autonome.
