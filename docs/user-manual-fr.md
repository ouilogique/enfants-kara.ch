# Manuel utilisateur

## Prérequis

-   Créer un compte utilisateur GitHub (https://github.com/signup)
    Le nom nom d’utilisateur et l’adresse mail seront utilisés pour la suite.

## Modifier le site depuis github.com

Par exemple, si on veut modifier la page
https://ouilogique.github.io/enfants-kara.ch/enfants-kara-togo-ekt/status/

-   Se connecter à son compte GitHub (https://github.com/login)
-   Aller sur la page du dépôt
    -   https://github.com/ouilogique/enfants-kara.ch
-   Dans la liste des fichier et répertoires, cliquer sur :
    -   `content`
    -   `030-enfants-kara-togo-ekt`
    -   `020-status`
    -   `index.md`
    -   l’icône `Edit this file` en forme de crayon en haut à droite
-   Modifier la page en dessous du *frontmatter*
    -   N.B. Le *frontamatter* est le texte en début de fichier entouré des caractères `---` ou `+++`.
-   Modifier le fichier.
-   Cliquer sur le bouton vert en haut à droite `Commit changes...`
-   Dans le dialogue qui apparait, Copilot remplit le message de commit automatiquement après une ou deux secondes.
-   Cliquer sur le bouton vert `Commit changes`
-   Dans le menu en haut de la fenêtre, cliquer sur `Actions`
-   L’état du build est affiché en live.
    S’il réussit, une icône verte apparait et la modification sera visible en ligne :
    https://ouilogique.github.io/enfants-kara.ch/enfants-kara-togo-ekt/status/

## Modifier le site depuis un ordinateur personnel

### Installation des outils sur Windows

Ouvrir PowerShell 5 avec le raccourci `Win+R` puis en tapant `powershell` et `Enter` dans le dialogue qui apparait.

```
winget install -e --id Microsoft.PowerShell       --scope machine --silent --accept-package-agreements --accept-source-agreements;
winget install -e --id Git.Git                    --scope machine --silent --accept-package-agreements --accept-source-agreements;
winget install -e --id Microsoft.VisualStudioCode --scope machine --silent --accept-package-agreements --accept-source-agreements;
winget install -e --id Hugo.Hugo.Extended         --scope machine --silent --accept-package-agreements --accept-source-agreements;
winget install -e --id PedroAlbanese.QREncode     --scope machine --silent --accept-package-agreements --accept-source-agreements;
```

Fermer la fenêtre PowerShell 5 et ouvrir la nouvelle version PowerShell 7 avec le raccourci `Win+R` puis en tapant `pwsh` et `Enter` dans le dialogue qui apparait.

Indiquer vos identifiants pour les commandes git :

```
git config --global user.name "Votre nom utilisateur GitHub";
git config --global user.email "Votre adresse mail sur GitHub";
```

Télécharger le dépôt contenant le site web et installer Dart-Sass :

```
cd $env:USERPROFILE\Documents
git clone https://github.com/ouilogique/enfants-kara.ch.git
cd .\enfants-kara.ch\
powershell -ExecutionPolicy Bypass -File .\scripts\install_dart_sass.ps1
```

> Important !
>
> Avant la première modification du site, ouvrir https://github.com/signup dans un navigateur web et se connecter à son compte GitHub.
>
> VSCode utilisera cette connexion pour vous identifier sur GitHub lors de la première synchronisation.

## Modifier le site

-   Ouvrir l’explorateur Windows
-   Aller dans le répertoire du site
-   Double clic sur
    -   ___enfants-kara.ch.code-workspace
    -   scripts\hugo_preview.cmd
-   Dans VScode, modifier le site
-   Ouvrir les outils Git (Ctrl+Shift+G)
-   Cliquer sur + à côté de `Changes`
-   Cliquer sur `Commit` puis sur `Sync Changes`
