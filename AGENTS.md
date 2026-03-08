# Mémoire de projet — enfants-kara.ch

## But du fichier
Mémoire persistante pour les sessions futures. Ne contenir que les conventions, décisions et préférences durables. Mettre à jour à chaque nouvelle instruction persistante de l'utilisateur.

---

## Contexte du projet
Site Hugo de l'association Enfants-Kara (aide aux enfants et jeunes au Togo depuis 2001).
La migration depuis Jimdo est **terminée**. Le projet est en phase de maintenance et d'évolution.

- Repo : `/Users/nico/Downloads/us.sitesucker.mac.sitesucker-pro/enfants-kara.ch`
- Branche principale : `hugo`
- Démo GitHub Pages : `https://nichub.github.io/enfants-kara.ch/`
- Site officiel : `https://enfants-kara.ch/`

---

## Structure des fichiers clés

```
config/
  _default/config.yaml     — config de base (langue, titre, params globaux)
  dev-local/config.yaml    — dev local (sans baseURL)
  dev-github/config.yaml   — demo GitHub Pages
  production/config.yaml   — production enfants-kara.ch
content/                   — contenu Markdown (50 fichiers)
layouts/
  _default/baseof.html     — squelette HTML, sidebar nav, lightbox, fonds par section
  _default/single.html     — template page simple
  _default/list.html       — template section (liste les pages enfants)
  index.html               — page d'accueil (hero)
  partials/nav-tree.html   — navigation récursive par poids
  partials/page-header.html — en-tête de page avec titre et nav prev/next
  _markup/render-image.html — rendu Markdown image (URL relatives)
  _markup/render-link.html  — rendu Markdown lien (URL relatives, target externe)
  shortcodes/document-card.html — carte PDF téléchargeable
  shortcodes/note.html     — commentaire invisible dans le contenu
static/
  images/                  — images (fonds Unsplash, logos)
  documents/               — fichiers téléchargeables (PDF PV AG)
  style.css                — feuille de style principale (~1300 lignes)
  scripts.js               — JS vanilla : lightbox, nav prev/next, View Transitions
scripts/
  hugo_preview.sh          — serveur de développement local avec QR code
  get_ip_of_default_interface.sh — détection IP multi-plateforme
.github/workflows/hugo.yaml — CI/CD GitHub Actions → GitHub Pages
```

---

## Sections du site

| Dossier                            | URL                        | Image de fond                                      |
|------------------------------------|----------------------------|----------------------------------------------------|
| `content/_index.md`                | `/`                        | `bill-wegener-7MD4DR9jbP0-unsplash.jpg`            |
| `content/010-accueil/`             | `/accueil/`                | `felicia-montenegro-EEbLJlfCnSI-unsplash.jpg`      |
| `content/020-enfants-kara-suisse-eks/` | `/enfants-kara-suisse-eks/` | `bill-wegener-hs98_9hzTcU-unsplash.jpg`       |
| `content/030-enfants-kara-togo-ekt/`   | `/enfants-kara-togo-ekt/`  | `tobie-eniafe-7EZfQdvDAl8-unsplash.jpg`       |
| `content/040-projet-marcar/`       | `/projet-marcar/`          | `stijn-kleerebezem-bsk8f6BVSHc-unsplash.jpg`       |
| `content/050-remerciements/`       | `/remerciements/`          | `bill-wegener-7MD4DR9jbP0-unsplash.jpg`            |

---

## Conventions importantes

### Contenu et front matter
- Unicode NFC pour tout le contenu texte, aliases et chemins.
- HTML simple autorisé dans `title` du front matter (ex. `<br>`), mais pas dans la balise `<title>` HTML.
- `linkTitle` à utiliser quand le libellé de nav diffère du titre de page.
- Interpréter `linkTitle` avec `safeHTML` dans les listings et la nav.
- `goldmark.renderer.unsafe: true` activé — HTML brut autorisé dans le Markdown.

### Navigation
- Ordre via préfixes numériques des dossiers (`010-`, `020-`…) → trié par `File.Path`, pas alphabétique.
- Navigation récursive dans la sidebar (`nav-tree.html`) : `<details>` pour les sections, `<a>` pour les pages.
- Prev/next entre pages via `scripts.js`.

### Ressources statiques
- Images : `static/images/`
- Documents téléchargeables : `static/documents/`
- Pas d'URL distantes résiduelles dans le contenu livré.
- Preload uniquement l'image de fond de la section courante (voir `baseof.html`).

### Style visuel
- Thème "Terre & lumière" : tons sable (`#f3e4d2`), terracotta (`#b5562d`), ivoire, brun doux.
- Police : Georgia serif (dans `style.css`).
- CSS View Transitions activées pour la navigation.
- Animations d'apparition en cascade sur les éléments de page.

### Shortcodes disponibles
- `{{< document-card href="..." img="..." alt="..." title="..." desc="..." >}}` — carte PDF.
- `{{< note >}}...{{< /note >}}` — commentaire invisible dans le contenu.

### Environnements de build
- `dev-local` : `hugo server --environment dev-local` (IP auto, port 1313, QR code via `scripts/hugo_preview.sh`)
- `dev-github` : baseURL GitHub Pages (CI auto sur push `hugo`)
- `production` : baseURL `https://enfants-kara.ch/` (détection via `static/CNAME`)
- Minification activée en CI (`hugo --gc --minify`).

### Robots.txt
- Production : allow all (via `partials/prod/robots.txt`)
- Dev : disallow all (via `partials/dev/robots.txt`)
- Sélection automatique selon `hugo.Environment`.

---

## Règle générale
Avant toute opération importante ou ambiguë, indiquer brièvement si la consigne peut être optimisée ou resserrée.
