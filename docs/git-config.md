# Configuration Git

## Déploiement sur le VPS de démonstration

Le remote Git `demo` pointe vers `ik_vps1_nico:/srv/ouilogique/demo/enfants-kara/repo.git`.
L’alias SSH `ik_vps1_nico` doit être configuré sur la machine utilisée.

### Configuration locale du dépôt

Après un nouveau clonage, ajouter le remote s’il n’existe pas encore :

```bash
git remote add demo ik_vps1_nico:/srv/ouilogique/demo/enfants-kara/repo.git
```

Désactiver ensuite la commande distante SSH prédéfinie pour les opérations Git de ce dépôt :

```bash
git config --local core.sshCommand "ssh -o RemoteCommand=none"
```

Ces réglages sont enregistrés dans `.git/config`, qui n’est pas versionné : ils doivent être refaits pour chaque nouveau clone. Le réglage `core.sshCommand` s’applique à tous les remotes de ce dépôt.

### Envoyer la branche principale

```bash
git push -u demo main
```

L’option `-u` configure `main` pour suivre `demo/main`.

### Dépannage SSH

Si le push échoue avec :

```text
Cannot execute command-line and remote command.
```

SSH reçoit à la fois une `RemoteCommand` prédéfinie et la commande distante demandée par Git. Le réglage `RemoteCommand=none` ci-dessus résout ce conflit. Le message Git qui suit, invitant à vérifier les droits d’accès et l’existence du dépôt, est générique.

Pour vérifier la configuration :

```bash
git remote get-url --push demo
git config --show-origin --get core.sshCommand
```
