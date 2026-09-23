# Audit & suggestions d’amélioration — enfants-kara.ch

Date de l’audit : 23 septembre 2026

Le site est sain, bien structuré et le build est propre (aucun avertissement,
70 pages). Les remarques ci-dessous sont des pistes d’amélioration, classées
par priorité. Rien ici n’est bloquant.

---

## 1. Performance / poids — le plus gros levier

Le site publie environ **84 MB** pour 70 pages, presque entièrement en images
non optimisées.

### Fonds de page (Unsplit) — `static/images/`

-   5 photos, **14,7 MB** au total, jusqu’à 6048×4032 px, servies telles quelles
  en `background-image` (cover) et en `<img>` hero.
-   La page d’accueil charge à elle seule une image de **6 MB**
  (`themes/kara/layouts/index.html`, `baseof.html` pour le preload).
-   L’image de fond sert aussi d’`og:image` (partage réseaux sociaux).

Suggestion : sortir ces images de `static/` vers les ressources du thème et
générer des versions ~2000 px en WebP/AVIF avec Hugo (`resources.Get` +
`.Process "resize 2000x webp"`). Poids estimé après traitement : ~0,5 MB
au lieu de 6 MB.

### Photos de galeries — `content/**/images/`

-   337 photos (~60 MB), servies en taille native (jusqu’à 960×1280, 1,35 MB)
  même pour une vignette affichée à ~200 px.
-   Aucun traitement d’image n’est actuellement appliqué :
  `Processed images │ 0` au build.

Suggestion : dans `themes/kara/layouts/_markup/render-image.html`, traiter les
images via les page resources (`.Resources.GetMatch`) pour générer des
vignettes (~600 px, WebP), ajouter `loading="lazy"` et `decoding="async"`, et
réserver la taille maximale à la lightbox.

### Social card OG image

`og:image` pointe vers l’image de fond de 6 MB. Générer une vraie carte
sociale 1200×630 via `.Fill` serait plus léger et plus net.

### Minification en production

`config/production/hugo.yaml` ne déclare aucun `minify` — seul le dev/staging
le désactive explicitement. La lisibilité du HTML en CI est un choix assumé,
mais les CSS/JS pourraient au moins être minifiés en production (`.Minify` sur
les `resources` de `baseof.html`).

---

## 2. SEO / données structurées

-   **JSON-LD absent** : ajouter un partial `Organization`/`WebSite` dans `<head>`.
-   **Pas de page 404** thématisée : GitHub Pages renvoie sa 404 par défaut.
-   `generator-date` et `dcterms.modified` utilisent `now` (date de build) dans
  `baseof.html` → builds non déterministes. Préférer `.Lastmod`/`.Date`.
-   Le shortcode `update-date` affiche aussi la date de build : valable mais à
  documenter (le contenu dépend de la reconstruction).
-   Sitemap OK (`sitemap.xml` généré), mais `lastmod` reflète les anciennes dates
  du front matter (ex. `/` daté 2013).

---

## 3. Accessibilité

-   `aria-label="Image precedente"` → « précédente » (`baseof.html`).
-   Lightbox : chaque image reçoit `role="button"` + `tabindex="0"` **et** est
  enveloppée d’une ancre → double déclencheur au clic (`assets/scripts.js`).
  L’ancre seule suffirait.
-   Peu de `:focus-visible` explicites hors lightbox/page-nav : les
  `.leaf`/`.branch-link`/`.brand` reposent sur l’outline par défaut du
  navigateur.

---

## 4. Robustesse / dette / documentation

-   **CI production** : seul `deploy.yml` (GitHub Pages, env `staging`) est
  automatisé ; `enfants-kara.ch` n’a ni workflow dédié ni `CNAME` dans le repo.
  Vérifier comment la prod est réellement déployée et le documenter.
-   **AGENTS.md en partie obsolète** :
    -   chemin du repo différent (`/Users/nico/Downloads/...`),
    -   « 50 fichiers » de contenu vs 60 réels,
    -   `static/CNAME` cité mais absent du repo,
    -   section « Tests de thèmes alternatifs (mars 2026) » à relire.
-   `url:` explicite dans le front matter des 59 pages : justifié par les aliases
  Jimdo, mais risque de divergence avec les dossiers préfixés — garder et
  documenter.
-   Métadonnées de migration incohérentes (ex. « Photos soirée 2014 » datée 2013)
  — mineur.

---

## Priorité

1. **Images** (fonds + galeries) : seul point à fort impact, divisible par
   `~10` le poids publié avec Hugo seul, sans aucune dépendance.
2. JSON-LD, page 404, social card.
3. Accessibilité (lightbox, libellés).
4. Documentation (AGENTS.md, déploiement prod).
