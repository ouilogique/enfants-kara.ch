# Mémoire de projet — enfants-kara.ch

## But du fichier

Mémoire persistante pour les sessions futures. Ne contenir que les conventions, décisions et préférences durables. Mettre à jour à chaque nouvelle instruction persistante de l’utilisateur.

---

## Contexte du projet

Site Hugo de l’association Enfants-Kara (aide aux enfants et jeunes au Togo depuis 2001).
La migration depuis Jimdo est **terminée**. Le projet est en phase de maintenance et d’évolution.

-   Repo : `/Users/nico/Downloads/us.sitesucker.mac.sitesucker-pro/enfants-kara.ch`
-   Branche principale : `main`
-   Démo VPS : `https://demo.ouilogique.ch/enfants-kara/`
-   Site officiel : `https://enfants-kara.ch/`

---

## Structure des fichiers clés

```text
config/
  _default/hugo.yaml       — config de base (langue, titre, params globaux)
  development/hugo.yaml    — développement local (sans baseURL)
  staging/hugo.yaml        — démo GitHub Pages
  production/hugo.yaml     — production enfants-kara.ch
content/                   — contenu Markdown (50 fichiers)
themes/kara/               — thème actif (voir section Thème ci-dessous)
static/
  images/                  — images de contenu (fonds Unsplash, logos)
  documents/               — fichiers téléchargeables (PDF PV AG)
  favicon.svg              — favicon (identité de l’asso, indépendant du thème)
scripts/
  preview.sh               — serveur de développement local avec QR code
  get_ip_of_default_interface.sh — détection IP multi-plateforme
.github/workflows/deploy.yml — CI/CD GitHub Actions → GitHub Pages
.hugo/                       — sorties générées (`public/` et `resources/`)
```

---

## Sections du site

| Dossier                                | URL                         | Image de fond                                 |
| -------------------------------------- | --------------------------- | --------------------------------------------- |
| `content/_index.md`                    | `/`                         | `bill-wegener-7MD4DR9jbP0-unsplash.jpg`       |
| `content/010-accueil/`                 | `/accueil/`                 | `felicia-montenegro-EEbLJlfCnSI-unsplash.jpg` |
| `content/020-enfants-kara-suisse-eks/` | `/enfants-kara-suisse-eks/` | `bill-wegener-hs98_9hzTcU-unsplash.jpg`       |
| `content/030-enfants-kara-togo-ekt/`   | `/enfants-kara-togo-ekt/`   | `tobie-eniafe-7EZfQdvDAl8-unsplash.jpg`       |
| `content/040-projet-marcar/`           | `/projet-marcar/`           | `stijn-kleerebezem-bsk8f6BVSHc-unsplash.jpg`  |
| `content/050-remerciements/`           | `/remerciements/`           | `bill-wegener-7MD4DR9jbP0-unsplash.jpg`       |

---

## Conventions importantes

### Contenu et front matter

-   Unicode NFC pour tout le contenu texte, aliases et chemins.
-   HTML simple autorisé dans `title` du front matter (ex. `<br>`), mais pas dans la balise `<title>` HTML.
-   `linkTitle` à utiliser quand le libellé de nav diffère du titre de page.
-   Interpréter `linkTitle` avec `safeHTML` dans les listings et la nav.
-   `goldmark.renderer.unsafe: true` activé — HTML brut autorisé dans le Markdown.

### Navigation

-   Ordre via préfixes numériques des dossiers (`010-`, `020-`…) → trié par `File.Path`, pas alphabétique.
-   Navigation récursive dans la sidebar (`nav-tree.html`) : `<details>` pour les sections, `<a>` pour les pages.
-   Prev/next entre pages généré par Hugo (`nav-pages-flat.html` + `page-header.html`) :
    liens `<a href>` natifs (fonctionnent sans JS). `scripts.js` intercepte uniquement
    le clic pour poser le flag des transitions fluides.
-   Sur la page d’accueil : lien `<a data-page-nav="next" hidden>` dans `index.html`
    pour la navigation clavier (ArrowRight).
-   Les fichiers dans `content/` avec `build.render: never` doivent aussi avoir
    `build.list: never` pour ne pas polluer la liste des pages.

### Thème Hugo

-   Thème actif : `kara` (déclaré dans `config/_default/hugo.yaml` : `theme: kara`)
-   Structure : `themes/kara/layouts/`, `themes/kara/assets/` (CSS + JS), `themes/kara/hugo.toml`
-   Les layouts (`_default/`, `_markup/`, `partials/`, `shortcodes/`) sont **dans le thème**, pas à la racine.
-   **Pour créer une variante de thème** : copier `themes/kara/assets/css/themes/_kara.css` sous un nouveau nom,
    modifier les tokens CSS, puis remplacer la référence `css/themes/_kara.css` dans
    `baseof.html` par le nouveau fichier (`resources.Get "css/themes/mon-theme.css"`).

### Ressources statiques

-   Images de contenu : `static/images/` (hors thème — restent lors d’un changement de thème)
-   Documents téléchargeables : `static/documents/`
-   JS du thème : `themes/kara/assets/scripts.js`
-   CSS du thème : CSS pur assemblé via Hugo Pipes (`resources.Concat`) dans `baseof.html`
-   Pas d’URL distantes résiduelles dans le contenu livré.
-   Preload uniquement l’image de fond de la section courante (voir `themes/kara/layouts/_default/baseof.html`).

### Style visuel

-   Thème “Terre & lumière” : tons sable (`#f3e4d2`), terracotta (`#b5562d`), ivoire, brun doux.
-   Police : Georgia serif.
-   Boîtes semi-transparentes (légèrement cuivrées) : opacité contrôlée par `--panel-alpha: 0.8`.
-   CSS View Transitions activées pour la navigation.
-   Animations d’apparition en cascade sur les éléments de page.

### Architecture CSS (`themes/kara/assets/`)

```text
css/style.css              — point d’entrée (déclare l’ordre des @layer)
css/themes/_kara.css       — tokens CSS du thème (couleurs, alpha, fonds, gradients) — @layer theme
css/_base.css              — reset, body, liens, .page-background            — @layer base
css/_layout.css            — grille principale (.shell, .app, .sidepane, .mainpane) — @layer layout
css/_nav.css               — .brand, .sidebar, arbre de navigation          — @layer nav
css/_page.css              — .page-header, .page-nav, footer                — @layer page
css/_home.css              — hero page d’accueil                            — @layer home
css/_content.css           — zone de contenu éditorial, tableaux, galeries  — @layer content
css/_components.css        — .card, .document-card, .listing, .lightbox     — @layer components
css/_responsive.css        — @media queries                                 — @layer responsive
```

**Tokens clés dans `_kara.css`** (à surcharger pour un thème alternatif) :

| Token                        | Rôle                             |
| ---------------------------- | -------------------------------- |
| `--panel-alpha`              | Opacité globale des boîtes (0–1) |
| `--panel-bg`                 | Fond `.brand` et `.sidebar`      |
| `--content-bg`               | Fond `.content`                  |
| `--card-bg`                  | Fond `.card`                     |
| `--header-bg`                | Fond `.page-header`              |
| `--accent` / `--accent-deep` | Couleur d’accentuation           |
| `--bg` / `--bg-deep`         | Fond de page                     |

**Pipeline Hugo Pipes** dans `baseof.html` :

```go-html-template
{{ $css := slice
  (resources.Get "css/style.css")
  (resources.Get "css/themes/_kara.css")
  ...
  (resources.Get "css/_responsive.css") | resources.Concat "style.css" }}
```

CSS pur uniquement — **aucune dépendance Sass/Dart Sass** requise.
L’ordre des couches est déclaré en tête de `css/style.css` :
`@layer theme, base, layout, nav, page, home, content, components, responsive;`.

### Shortcodes disponibles

-   `{{< document-card href="..." img="..." alt="..." title="..." desc="..." >}}` — carte PDF.
-   `{{< note >}}...{{< /note >}}` — commentaire invisible dans le contenu.

### Environnements de build

-   Push vers le VPS de démonstration : remote `demo` = `ik_vps1_nico:/srv/ouilogique/demo/enfants-kara/repo.git`.
    Configurer chaque clone avec `git config --local core.sshCommand "ssh -o RemoteCommand=none"`
    pour éviter le conflit entre la `RemoteCommand` SSH et la commande Git.
    Ce réglage est local à `.git/config`, non versionné. Procédure complète dans `docs/git-config.md`.

-   `development` : `hugo server` (IP auto, port 1313, QR code via `scripts/preview.sh`)
-   `staging` : baseURL de la démonstration GitHub Pages, utilisée par le workflow de déploiement
-   `production` : baseURL `https://enfants-kara.ch/` (détection via `static/CNAME`)
-   Le HTML reste lisible en CI ; seules les ressources explicitement minifiées dans les gabarits le sont.

### Installation locale Windows (mars 2026)

-   Hugo : installer `Hugo.Hugo.Extended` via `winget`, vérifier avec `hugo version`
    et exiger `extended` + version récente (site validé avec `v0.165.0`).
-   Si le lien `C:\Users\Nico\AppData\Local\Microsoft\WinGet\Links\hugo.exe` est cassé,
    utiliser l’exécutable réel sous
    `C:\Users\Nico\AppData\Local\Microsoft\WinGet\Packages\Hugo.Hugo.Extended_Microsoft.Winget.Source_8wekyb3d8bbwe\hugo.exe`.
-   Aucun compilateur CSS à installer (CSS pur via `resources.Concat`) — pas de Dart Sass.
-   Lancement Windows fiable : `scripts/preview.ps1` ou double-clic sur
    `scripts/preview.cmd`

### Transitions de navigation (CSS View Transitions)

La navigation entre pages (flèches clavier, boutons Précédente/Suivante) utilise les CSS View Transitions. Ce mécanisme doit rester intact lors de toute modification du thème.

**Noms des 4 boîtes et leur comportement de transition :**

| Boîte      | Classe CSS     | `view-transition-name` | Comportement                                     |
| ---------- | -------------- | ---------------------- | ------------------------------------------------ |
| Logo       | `.brand`       | `panel-brand`          | Snap instantané (identique sur toutes les pages) |
| Navigation | `.sidebar`     | `panel-sidebar`        | Morph rapide 160ms                               |
| En-tête    | `.page-header` | `panel-header`         | Taille snap, contenu cross-fade 180→300ms        |
| Contenu    | `.content`     | `panel-content`        | Cross-fade 200→340ms                             |

**Règle importante :** `box-appear` (animation d’entrée des boîtes) est supprimé pendant la navigation via la classe `no-box-appear` posée sur `<html>` par un script inline dans `<head>` (`baseof.html`). Ce script lit un flag `sessionStorage` (`ek-nav`) posé par `scripts.js` avant chaque navigation.

**À respecter lors de modifications futures :**

-   Tout nouvel élément animé par `box-appear` doit être ajouté à la règle `.no-box-appear` dans `css/_base.css`
-   Tout nouveau chemin de navigation dans `scripts.js` doit poser `sessionStorage.setItem('ek-nav', '1')` avant `window.location.href`
-   Ne pas supprimer les `view-transition-name` des 4 boîtes
-   Ne pas retirer le script inline de `baseof.html`

### Robots.txt

-   Production : allow all (via `themes/kara/layouts/partials/prod/robots.txt`)
-   Dev : disallow all (via `themes/kara/layouts/partials/dev/robots.txt`)
-   Sélection automatique selon `hugo.Environment`.

---

## Tests de thèmes alternatifs (mars 2026)

Cinq thèmes Hugo testés comme alternatives au thème `kara`. Conclusion : aucun ne convient — tous nécessitent trop d’adaptation pour le contenu et la structure de ce site.

| Thème         | Navigation            | Notes                                                |
| ------------- | --------------------- | ---------------------------------------------------- |
| **PaperMod**  | `menu.main` ✓         | Blog-centré, peu adapté à une asso                   |
| **Congo**     | `menu.main` ✓         | Riche mais complexe, `.Author` cassé sur Hugo 0.157+ |
| **Anatole**   | `menu.main` ✓         | Requiert Dart Sass, look blog                        |
| **Hugo Book** | Arborescence fichiers | Nécessite `BookSection: "/"`, look documentation     |
| **Ananke**    | `menu.main` ✓         | Générique, peu adapté                                |

### Conventions établies lors des tests

-   `config/_default/menus.yaml` — navigation portable via `menu.main` (5 sections principales)
-   `scripts/maintenance/compare_themes.py` — sert tous les builds en parallèle (un port par thème à partir de 8080), option `--build` pour rebuilder depuis chaque branche
-   Shortcodes (`note`, `document-card`) et renderers (`_markup/`) doivent être à la racine `layouts/` pour être disponibles hors thème `kara`
-   `config/compare/config.yaml` — environnement local avec `relativeURLs: true` pour servir sans serveur web

---

## Règles générales

-   Avant toute opération importante ou ambiguë, indiquer brièvement si la consigne peut être optimisée ou resserrée.
-   **Ne jamais créer un commit sans validation explicite de l’utilisateur.** Préparer le travail, puis demander confirmation avant de committer.
