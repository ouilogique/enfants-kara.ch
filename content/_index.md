---

###
#
# Rendu de la page d’accueil
# Ce fichier ne contient pas de corps Markdown : tout le contenu visuel
# vient du champ `params` ci-dessous et des templates Hugo.
#
# Chaîne de rendu :
# - content/_index.md → détecté par Hugo comme racine du site (/)
# - layouts/index.html → template prioritaire pour la homepage ;
#   injecte l’image “hero”, le logo et les textes issus de .Params
# - layouts/_default/baseof.html → fournit le squelette HTML complet
#   (head, sidebar de navigation, lightbox)
#
# Notes :
# - description → injectée comme <meta name="description"> et balises Open Graph/Twitter
# - &nbsp; dans les params est rendu tel quel grâce à safeHTML
# - Le bouton CTA (Call To Action) pointe automatiquement vers la 1ère section (par weight)
# - L’image de fond “hero” est définie dans bgImage ci-dessous
#
##

title: "Accueil"
draft: false
aliases:
  - "/index.html"
params:
  description: "Association Enfants-Kara — accompagner des enfants et des jeunes au Togo avec un engagement concret, durable et profondément humain."
  eyebrow: "Bienvenue"
  hero_title: "Association Enfants-Kara"
  hero_lead: "Une association qui accompagne des enfants et des&nbsp;jeunes au Togo avec un engagement concret, durable et&nbsp;profondément humain."
  hero_curiosity: "Derrière chaque action se cache une histoire, un&nbsp;visage et un&nbsp;avenir à&nbsp;découvrir."
  hero_button: "À la rencontre des&nbsp;Enfants-Kara"
bgImage: "images/bill-wegener-7MD4DR9jbP0-unsplash.jpg"
---
