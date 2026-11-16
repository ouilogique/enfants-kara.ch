# Mise à jour périodique de Hugo sur ikvps1

Cette procédure décrit la mise à jour de la version de Hugo utilisée par un
projet et par sa construction de démonstration sur ikvps1.

Dans les commandes ci-dessous, remplacer les variables suivantes :

- `nom-du-projet` par le nom du projet, utilisé dans l’URL de démonstration ;
- `https://site-de-production.example/` par l’URL de production du projet ;
- `X.Y.Z` par la version de Hugo à installer.

La démonstration est toujours accessible à l’adresse
<https://demo.ouilogique.ch/nom-du-projet/>.

## Checklist

- [ ] Vérifier la dernière version stable publiée sur
      <https://github.com/gohugoio/hugo/releases>.
- [ ] Rechercher toutes les mentions de Hugo et des versions dans le projet.
- [ ] Vérifier la version minimale déclarée par le thème utilisé, s’il en
      existe une.
- [ ] Mettre à jour `HUGO_VERSION` dans `.github/workflows/deploy.yml`.
- [ ] Construire le site en environnement de production avec la nouvelle
      version.
- [ ] Vérifier que la construction se termine sans erreur et que le fichier
      d’accueil est généré dans le répertoire de publication configuré par le
      projet.
- [ ] Contrôler les modifications avec `git diff --check` et `git status`.
- [ ] Faire valider la modification avant de la publier.
- [ ] Créer un commit dédié à la mise à jour de Hugo.
- [ ] Pousser la branche de travail vers `demo:dev`.
- [ ] Vérifier la démonstration sur
      <https://demo.ouilogique.ch/nom-du-projet/>.
- [ ] Noter le résultat dans le journal de maintenance.

## Vérifier les références existantes

Depuis la racine du dépôt :

```shell
git grep -n -i -E 'hugo|version'
```

Les références à une version minimale, à une fonctionnalité ou à une
modification historique ne doivent pas être remplacées automatiquement. Les
versions générées dans les répertoires ignorés par Git ne constituent pas des
références de configuration.

## Vérifier la compatibilité du thème

Rechercher le fichier `hugo.toml` du thème actif, généralement sous
`themes/<nom-du-thème>/hugo.toml`, puis vérifier la valeur éventuelle de
`min_version`. Une contrainte minimale ne doit pas être remplacée par la
version courante : elle indique la compatibilité minimale du thème.

## Mettre à jour le workflow

Modifier la variable `HUGO_VERSION` dans `.github/workflows/deploy.yml` :

```yaml
env:
  HUGO_VERSION: X.Y.Z
```

Le workflow doit télécharger l’archive correspondant à la version et à
l’architecture utilisées par le runner. Depuis Hugo 0.170.0, l’édition
“Extended” a été supprimée : utiliser l’archive standard
`hugo_${HUGO_VERSION}_linux-amd64.tar.gz`.

## Vérifier la construction localement

Utiliser la version mise à jour de Hugo et une destination temporaire afin de
ne pas remplacer les fichiers générés du projet. Adapter `--baseURL` à l’URL
de production du projet :

```shell
verify_dir="$(mktemp -d)"
export HUGO_RESOURCEDIR="$verify_dir/resources"
hugo build \
  --environment production \
  --gc \
  --noBuildLock \
  --baseURL https://site-de-production.example/ \
  --cacheDir "$verify_dir/cache" \
  --destination "$verify_dir/public"
test -f "$verify_dir/public/index.html"
```

Si le projet utilise une autre destination ou un autre fichier d’accueil,
adapter la dernière commande à sa configuration.

Si un serveur Hugo est déjà lancé avec un script de prévisualisation, il doit
être réutilisé pour les vérifications. Ne pas démarrer une deuxième instance.

## Publier sur la démonstration

Avant toute publication, contrôler la branche et les modifications :

```shell
git status --short
git branch --show-current
git ls-remote --heads demo
git diff --check
```

Après validation humaine explicite :

```shell
git add .github/workflows/deploy.yml
git commit -m "ci: update Hugo to X.Y.Z"
git push demo HEAD:dev
```

Si la procédure elle-même est modifiée, l’ajouter explicitement au commit :

```shell
git add .github/workflows/deploy.yml \
    docs/maintenance/mise-a-jour-hugo-sur-ikvps1.md
```

La publication sur `demo:dev` doit être vérifiée sur
<https://demo.ouilogique.ch/nom-du-projet/>. Contrôler notamment que la
réponse HTTP est `200` et que l’en-tête `x-robots-tag` indique
`noindex, nofollow`.

Ne jamais pousser vers `main` ou `origin` sans la validation prévue par le
projet.

## Journal de maintenance

Après chaque mise à jour, ajouter une entrée comprenant :

- la date ;
- le nom du projet ;
- l’ancienne et la nouvelle version ;
- le résultat de la construction locale ;
- le hash du commit ;
- le résultat de la publication sur la démonstration ;
- les éventuels avertissements ou régressions observés.

Exemple :

```markdown
### AAAA-MM-JJ — nom-du-projet — Hugo X.Y.Z → X.Y.Z

- Construction locale : réussie.
- Commit : `abcdef0`.
- Démonstration : publiée sur
  <https://demo.ouilogique.ch/nom-du-projet/>, réponse HTTP 200.
- Remarque : aucune.
```
