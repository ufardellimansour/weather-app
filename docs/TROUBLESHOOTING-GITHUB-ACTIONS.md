# 🐛 Dépannage GitHub Actions - Erreurs Courantes

Guide de résolution des problèmes fréquents avec le workflow GitHub Actions.

---

## 🔴 Erreur: "invalid reference format"

### Symptôme
```
ERROR: failed to build: invalid tag "ghcr.io/username/weather-app:-abc123": 
invalid reference format
```

### Cause
Le tag Docker généré commence par un tiret `-` ce qui est invalide.

### Solution

Le workflow a été corrigé pour utiliser `sha-` comme préfixe au lieu de `{{branch}}-`.

**Tags générés maintenant :**
```
ghcr.io/username/weather-app:develop
ghcr.io/username/weather-app:main
ghcr.io/username/weather-app:sha-2a367ce  ✅
ghcr.io/username/weather-app:latest
ghcr.io/username/weather-app:pr-123
```

### Si le problème persiste

Édite `.github/workflows/ci-cd.yml` ligne ~40 :

```yaml
- name: Extract metadata
  id: meta
  uses: docker/metadata-action@v5
  with:
    images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
    tags: |
      type=ref,event=branch
      type=ref,event=pr
      type=sha,prefix=sha-  # ✅ Bon
      type=raw,value=latest,enable={{is_default_branch}}
```

**NE PAS utiliser** `prefix={{branch}}-` car `{{branch}}` peut être vide.

---

## 🔴 Erreur: "kubectl: connection refused"

### Symptôme
```
error: You must be logged in to the server (Unauthorized)
```

### Cause
Le secret `KUBECONFIG` est invalide ou mal encodé.

### Solution

1. **Regénérer le kubeconfig en base64 :**
   ```bash
   cat ~/.kube/config | base64 -w 0
   # Ou sur macOS :
   cat ~/.kube/config | base64
   ```

2. **Mettre à jour dans GitHub :**
   - Settings → Secrets and variables → Actions
   - Trouver `KUBECONFIG`
   - Update → Coller la nouvelle valeur

3. **Vérifier que le kubeconfig est valide :**
   ```bash
   # Tester localement
   kubectl get nodes
   
   # Si ça ne marche pas localement, ça ne marchera pas dans GitHub Actions
   ```

### Vérifications
- ✅ Le kubeconfig contient les certificats
- ✅ Le token/password est valide
- ✅ L'URL du cluster est accessible depuis internet
- ✅ Pas de caractères spéciaux mal échappés

---

## 🔴 Erreur: "permission denied" lors du push vers GHCR

### Symptôme
```
ERROR: failed to push: 
ghcr.io/username/weather-app:develop: unauthorized: permission denied
```

### Cause
Permissions insuffisantes pour le `GITHUB_TOKEN`.

### Solution

1. **Vérifier les permissions du job :**

Dans `.github/workflows/ci-cd.yml`, le job `build` doit avoir :

```yaml
build:
  runs-on: ubuntu-latest
  permissions:
    contents: read      # ✅ Lire le code
    packages: write     # ✅ Écrire dans GHCR
```

2. **Vérifier les settings du repo :**
   - Settings → Actions → General
   - Workflow permissions : **Read and write permissions** ✅

3. **Si l'image existe déjà :**
   - Elle peut être en lecture seule
   - Supprimer l'image et relancer

---

## 🔴 Erreur: "Helm install failed"

### Symptôme
```
Error: INSTALLATION FAILED: 
failed to create resource: namespaces is forbidden
```

### Cause
Le compte Kubernetes n'a pas les permissions suffisantes.

### Solution

1. **Vérifier les permissions kubectl :**
   ```bash
   kubectl auth can-i create namespace
   # Devrait retourner: yes
   ```

2. **Donner les permissions nécessaires :**
   ```bash
   kubectl create clusterrolebinding github-actions-admin \
     --clusterrole=cluster-admin \
     --serviceaccount=default:default
   ```

3. **Ou utiliser un namespace existant :**
   ```bash
   # Créer les namespaces manuellement
   kubectl create namespace weather-preprod
   kubectl create namespace weather-prod
   ```

---

## 🔴 Erreur: Pods en "ImagePullBackOff"

### Symptôme
```bash
kubectl get pods -n weather-preprod
NAME                           READY   STATUS             RESTARTS   AGE
weather-app-xxx-yyy           0/1     ImagePullBackOff   0          2m
```

### Cause
L'image Docker n'est pas accessible (privée sans authentification).

### Solution 1 : Rendre l'image publique

1. Va sur https://github.com/users/TON-USERNAME/packages
2. Sélectionne `weather-app`
3. Package settings → Change visibility → **Public** ✅

### Solution 2 : Créer un imagePullSecret

```bash
# Créer un token GitHub avec scope read:packages
# https://github.com/settings/tokens

kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=TON-USERNAME \
  --docker-password=TON-GITHUB-TOKEN \
  --docker-email=ton-email@example.com \
  -n weather-preprod

# Ajouter au deployment Helm
helm upgrade weather-app-preprod ./helm/weather-app \
  --set imagePullSecrets[0].name=ghcr-secret
```

---

## 🔴 Erreur: Pods en "CrashLoopBackOff"

### Symptôme
```bash
kubectl get pods -n weather-preprod
NAME                           READY   STATUS             RESTARTS   AGE
weather-app-xxx-yyy           0/1     CrashLoopBackOff   5          2m
```

### Cause
L'application crash au démarrage (souvent secret manquant).

### Solution

1. **Voir les logs :**
   ```bash
   kubectl logs -f deployment/weather-app-preprod -n weather-preprod
   ```

2. **Si "OPENWEATHER_API_KEY not set" :**
   ```bash
   # Le secret n'a pas été créé ou mal configuré
   kubectl create secret generic weather-app-preprod-secret \
     --from-literal=openweather-api-key="VOTRE-CLE-API" \
     -n weather-preprod
   
   # Redémarrer les pods
   kubectl rollout restart deployment/weather-app-preprod -n weather-preprod
   ```

3. **Vérifier le secret existe :**
   ```bash
   kubectl get secret -n weather-preprod
   kubectl describe secret weather-app-preprod-secret -n weather-preprod
   ```

---

## 🔴 Erreur: Workflow ne démarre pas

### Symptôme
Aucun workflow n'apparaît dans l'onglet Actions après un push.

### Causes possibles

1. **GitHub Actions désactivé**
   - Settings → Actions → General
   - Cocher "Allow all actions and reusable workflows" ✅

2. **Fichier au mauvais endroit**
   ```bash
   # Doit être :
   .github/workflows/ci-cd.yml  ✅
   
   # PAS :
   github/workflows/ci-cd.yml   ❌
   .github/workflow/ci-cd.yml   ❌
   ```

3. **Erreur de syntaxe YAML**
   - Valider sur https://www.yamllint.com/
   - GitHub affiche l'erreur dans Actions si syntaxe invalide

4. **Branch incorrecte**
   - Le workflow se déclenche sur `develop` et `main`
   - Vérifier que tu push sur une de ces branches

---

## 🔴 Erreur: Review App non créée

### Symptôme
Pull Request créée mais pas de review app déployée.

### Solution

1. **Vérifier les logs du job :**
   - Actions → Workflow → Job `deploy-review`
   - Voir les erreurs

2. **Vérifier la condition :**
   ```yaml
   deploy-review:
     if: github.event_name == 'pull_request'  # ✅ Doit être une PR
   ```

3. **La PR doit cibler `develop` ou `main` :**
   ```yaml
   on:
     pull_request:
       branches:
         - develop
         - main
   ```

4. **Permissions GitHub :**
   - Le workflow doit pouvoir commenter sur la PR
   - Settings → Actions → General
   - Workflow permissions → Read and write ✅

---

## 🔴 Erreur: "Environment protection rules" bloquent le déploiement

### Symptôme
Le job `deploy-production` est bloqué en attente d'approbation mais personne ne peut approuver.

### Solution

1. **Configurer les reviewers :**
   - Settings → Environments → production
   - Required reviewers → Ajouter des utilisateurs ✅

2. **Vérifier que le reviewer a les permissions :**
   - Doit avoir accès en écriture au repo
   - Settings → Collaborators → Ajouter si nécessaire

3. **Approuver le déploiement :**
   - Actions → Workflow en cours
   - Review deployments → Approve ✅

---

## 🔴 Erreur: "rate limit exceeded"

### Symptôme
```
ERROR: toomanyrequests: You have reached your pull rate limit
```

### Cause
Trop de pulls d'images Docker en peu de temps.

### Solution

1. **Utiliser le cache GitHub Actions :**
   ```yaml
   # Déjà configuré dans le workflow
   cache-from: type=gha
   cache-to: type=gha,mode=max
   ```

2. **Authentification Docker Hub (si tu pull des images) :**
   ```yaml
   - name: Login to Docker Hub
     uses: docker/login-action@v3
     with:
       username: ${{ secrets.DOCKERHUB_USERNAME }}
       password: ${{ secrets.DOCKERHUB_TOKEN }}
   ```

---

## 🔴 Erreur: "No space left on device"

### Symptôme
```
ERROR: failed to build: write /var/lib/docker: no space left on device
```

### Cause
Le runner GitHub Actions a manqué d'espace disque.

### Solution

1. **Nettoyer avant le build :**
   ```yaml
   - name: Free disk space
     run: |
       docker system prune -af
       sudo rm -rf /usr/share/dotnet
       sudo rm -rf /opt/ghc
       df -h
   ```

2. **Optimiser le Dockerfile :**
   - Multi-stage build (déjà configuré)
   - Nettoyer les caches apt/pip
   - Combiner les RUN commands

---

## 🔴 Erreur: Secrets non disponibles dans les forks

### Symptôme
Les secrets ne sont pas accessibles dans les PRs depuis des forks.

### Solution

**C'est normal et sécurisé !** Les secrets ne sont jamais exposés aux forks.

**Options :**

1. **Pull Request depuis une branche du même repo :**
   ```bash
   # Au lieu de forker, créer une branche
   git checkout -b feature/ma-feature
   git push origin feature/ma-feature
   # Créer la PR depuis cette branche
   ```

2. **Pour les contributeurs externes :**
   - Les maintainers doivent merger dans une branche du repo
   - Ou désactiver les review apps pour les forks

---

## 🛠️ Commandes de Diagnostic

### Vérifier l'état du workflow

```bash
# Via GitHub CLI
gh workflow list
gh run list
gh run view <run-id>

# Logs détaillés
gh run view <run-id> --log
```

### Vérifier Kubernetes

```bash
# État des pods
kubectl get pods -n weather-preprod -o wide

# Logs
kubectl logs -f deployment/weather-app-preprod -n weather-preprod

# Événements
kubectl get events -n weather-preprod --sort-by='.lastTimestamp' | tail -20

# Décrire un pod
kubectl describe pod <pod-name> -n weather-preprod
```

### Vérifier Helm

```bash
# Releases installées
helm list -n weather-preprod

# Historique
helm history weather-app-preprod -n weather-preprod

# Valeurs actuelles
helm get values weather-app-preprod -n weather-preprod

# Manifests générés
helm get manifest weather-app-preprod -n weather-preprod
```

### Tester le chart Helm localement

```bash
# Valider la syntaxe
helm lint ./helm/weather-app

# Dry-run
helm install weather-app-test ./helm/weather-app \
  --dry-run --debug \
  --namespace test

# Générer les manifests
helm template weather-app-test ./helm/weather-app \
  --namespace test
```

---

## 📞 Support Additionnel

Si le problème persiste :

1. **Vérifier les logs complets dans GitHub Actions**
2. **Vérifier les événements Kubernetes**
3. **Consulter la documentation :**
   - [docs/GITHUB-ACTIONS-SETUP.md](GITHUB-ACTIONS-SETUP.md)
   - [docs/QUICKSTART-GITHUB-ACTIONS.md](QUICKSTART-GITHUB-ACTIONS.md)

4. **Ressources externes :**
   - [GitHub Actions Documentation](https://docs.github.com/en/actions)
   - [Helm Documentation](https://helm.sh/docs/)
   - [Kubernetes Documentation](https://kubernetes.io/docs/)

---

## ✅ Checklist de Vérification Complète

Avant de créer un ticket de support, vérifie :

**GitHub :**
- [ ] Actions est activé (Settings → Actions)
- [ ] Workflow file dans `.github/workflows/`
- [ ] Syntaxe YAML valide
- [ ] Secrets configurés correctement
- [ ] Permissions workflow (read + write)

**Kubernetes :**
- [ ] kubectl fonctionne localement
- [ ] KUBECONFIG valide et encodé en base64
- [ ] Cluster accessible depuis internet
- [ ] Permissions suffisantes (créer namespaces)
- [ ] Secrets créés dans les namespaces

**Docker :**
- [ ] Images GHCR publiques ou imagePullSecret configuré
- [ ] Tags valides (pas de tiret au début)
- [ ] Dockerfile à la racine du repo

**Helm :**
- [ ] Chart valide (helm lint passe)
- [ ] Values files corrects
- [ ] Image repository correct dans values.yaml

---

**Bon débogage !** 🐛➡️✅
