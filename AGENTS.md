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
  prod-github/config.yaml  — production enfants-kara.ch
content/                   — contenu Markdown (50 fichiers)
themes/kara/               — thème actif (voir section Thème ci-dessous)
static/
  images/                  — images de contenu (fonds Unsplash, logos)
  documents/               — fichiers téléchargeables (PDF PV AG)
  favicon.svg              — favicon (identité de l'asso, indépendant du thème)
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

### Thème Hugo
- Thème actif : `kara` (déclaré dans `config/_default/config.yaml` : `theme: kara`)
- Structure : `themes/kara/layouts/`, `themes/kara/static/` (CSS + JS), `themes/kara/theme.toml`
- Pour tester une variante : créer `themes/autre/` et changer `theme: kara` → `theme: autre`
- Les layouts (`_default/`, `_markup/`, `partials/`, `shortcodes/`) sont **dans le thème**, pas à la racine.

### Ressources statiques
- Images de contenu : `static/images/` (hors thème — restent lors d'un changement de thème)
- Documents téléchargeables : `static/documents/`
- CSS/JS du thème : `themes/kara/static/style.css` et `scripts.js`
- Pas d'URL distantes résiduelles dans le contenu livré.
- Preload uniquement l'image de fond de la section courante (voir `themes/kara/layouts/_default/baseof.html`).

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
- `prod-github` : baseURL `https://enfants-kara.ch/` (détection via `static/CNAME`)
- Minification activée en CI (`hugo --gc --minify`).

### Robots.txt
- Production : allow all (via `themes/kara/layouts/partials/prod/robots.txt`)
- Dev : disallow all (via `themes/kara/layouts/partials/dev/robots.txt`)
- Sélection automatique selon `hugo.Environment`.

---

## Tests de thèmes alternatifs (mars 2026)

Cinq thèmes Hugo testés comme alternatives au thème `kara`. Conclusion : aucun ne convient — tous nécessitent trop d'adaptation pour le contenu et la structure de ce site.

| Thème | Navigation | Notes |
|---|---|---|
| **PaperMod** | `menu.main` ✓ | Blog-centré, peu adapté à une asso |
| **Congo** | `menu.main` ✓ | Riche mais complexe, `.Author` cassé sur Hugo 0.157+ |
| **Anatole** | `menu.main` ✓ | Requiert Dart Sass, look blog |
| **Hugo Book** | Arborescence fichiers | Nécessite `BookSection: "/"`, look documentation |
| **Ananke** | `menu.main` ✓ | Générique, peu adapté |

### Conventions établies lors des tests
- `config/_default/menus.yaml` — navigation portable via `menu.main` (5 sections principales)
- `scripts/compare_themes.py` — sert tous les builds en parallèle (un port par thème à partir de 8080), option `--build` pour rebuilder depuis chaque branche
- Shortcodes (`note`, `document-card`) et renderers (`_markup/`) doivent être à la racine `layouts/` pour être disponibles hors thème `kara`
- `config/compare/config.yaml` — environnement local avec `relativeURLs: true` pour servir sans serveur web

---

## Règle générale
Avant toute opération importante ou ambiguë, indiquer brièvement si la consigne peut être optimisée ou resserrée.
