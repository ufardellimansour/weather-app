# 🚀 Guide de Démarrage Rapide - Argo CD

Guide simplifié pour déployer l'application Weather App avec Argo CD sur preprod et prod.

## ⚡ Démarrage Ultra-Rapide (5 minutes)

### 1. Prérequis Vérification

```bash
# Vérifier que Argo CD est installé
kubectl get pods -n argocd

# Vérifier que vous êtes connecté
argocd version

# Installer Argo CD si nécessaire
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Configuration Rapide

```bash
cd k8s-argocd

# Éditer les fichiers Argo CD avec votre repo Git
sed -i 's|VOTRE-USERNAME|votre-github-username|g' argocd-*.yaml

# Créer les secrets manuellement (à faire UNE FOIS)
kubectl create secret generic weather-app-secret \
  --from-literal=OPENWEATHER_API_KEY="VOTRE_CLE_API" \
  -n weather-preprod --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic weather-app-secret \
  --from-literal=OPENWEATHER_API_KEY="VOTRE_CLE_API" \
  -n weather-prod --dry-run=client -o yaml | kubectl apply -f -
```

### 3. Déploiement

```bash
# Déployer les applications
make deploy-all

# OU manuellement
kubectl apply -f argocd-preprod.yaml
kubectl apply -f argocd-prod.yaml

# Synchroniser
make sync-all

# OU manuellement
argocd app sync weather-app-preprod
argocd app sync weather-app-prod  # Sync manuel en prod
```

### 4. Vérification

```bash
# Vérifier le statut
make status

# Accéder aux applications
make port-forward-preprod  # http://localhost:8080
make port-forward-prod     # http://localhost:8081
```

## 📋 Checklist de Déploiement

### Preprod ✅

- [ ] **Repository Git configuré**
  ```bash
  # Éditer argocd-preprod.yaml
  repoURL: https://github.com/votre-username/weather-app.git
  targetRevision: develop
  ```

- [ ] **Image Docker disponible**
  ```bash
  docker build -t votre-registry/weather-app:preprod .
  docker push votre-registry/weather-app:preprod
  ```

- [ ] **Image configurée dans Kustomize**
  ```bash
  # Éditer overlays/preprod/kustomization.yaml
  images:
    - name: weather-app
      newName: votre-registry/weather-app
      newTag: preprod
  ```

- [ ] **Secret créé**
  ```bash
  kubectl create secret generic weather-app-secret \
    --from-literal=OPENWEATHER_API_KEY="votre-cle" \
    -n weather-preprod
  ```

- [ ] **Application déployée**
  ```bash
  kubectl apply -f argocd-preprod.yaml
  argocd app sync weather-app-preprod
  ```

### Production ✅

- [ ] **Repository Git configuré**
  ```bash
  # Éditer argocd-prod.yaml
  repoURL: https://github.com/votre-username/weather-app.git
  targetRevision: main
  ```

- [ ] **Image Docker disponible**
  ```bash
  docker build -t votre-registry/weather-app:latest .
  docker push votre-registry/weather-app:latest
  ```

- [ ] **Image configurée dans Kustomize**
  ```bash
  # Éditer overlays/prod/kustomization.yaml
  images:
    - name: weather-app
      newName: votre-registry/weather-app
      newTag: latest
  ```

- [ ] **Secret créé**
  ```bash
  kubectl create secret generic weather-app-secret \
    --from-literal=OPENWEATHER_API_KEY="votre-cle" \
    -n weather-prod
  ```

- [ ] **Application déployée**
  ```bash
  kubectl apply -f argocd-prod.yaml
  argocd app sync weather-app-prod
  ```

## 🔄 Workflow de Déploiement

### Développement → Preprod

```bash
# 1. Faire des modifications
git checkout develop
# ... code changes ...

# 2. Build et push
docker build -t votre-registry/weather-app:preprod .
docker push votre-registry/weather-app:preprod

# 3. Commit et push
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin develop

# 4. Argo CD sync automatiquement (ou manuellement)
argocd app sync weather-app-preprod
```

### Preprod → Production

```bash
# 1. Merge dans main
git checkout main
git merge develop
git push origin main

# 2. Build et push production
docker build -t votre-registry/weather-app:latest .
docker push votre-registry/weather-app:latest

# 3. Sync manuel en production
argocd app sync weather-app-prod

# 4. Vérifier
make status-prod
```

## 🛠️ Commandes Essentielles

### Makefile (recommandé)

```bash
make help               # Voir toutes les commandes
make deploy-all         # Déployer preprod + prod
make sync-all           # Sync preprod + prod
make status             # Statut global
make status-preprod     # Statut détaillé preprod
make status-prod        # Statut détaillé prod
make logs-preprod       # Logs preprod
make logs-prod          # Logs prod
make port-forward-preprod  # Tunnel preprod
make port-forward-prod     # Tunnel prod
```

### Argo CD CLI

```bash
# Statut
argocd app list
argocd app get weather-app-preprod
argocd app get weather-app-prod

# Sync
argocd app sync weather-app-preprod
argocd app sync weather-app-prod

# Différences
argocd app diff weather-app-preprod
argocd app diff weather-app-prod

# Historique
argocd app history weather-app-prod

# Rollback
argocd app rollback weather-app-prod 5
```

### Kubectl

```bash
# Pods
kubectl get pods -n weather-preprod
kubectl get pods -n weather-prod

# Logs
kubectl logs -f -l app=weather-app -n weather-preprod
kubectl logs -f -l app=weather-app -n weather-prod

# HPA (prod seulement)
kubectl get hpa -n weather-prod
kubectl describe hpa weather-app-hpa -n weather-prod
```

## 🔧 Configuration des Environnements

### Modifier les Replicas

**Preprod:**
```bash
# Éditer overlays/preprod/deployment-patch.yaml
spec:
  replicas: 2  # Changer de 1 à 2

# Commit et sync
git add overlays/preprod/deployment-patch.yaml
git commit -m "scale: augmenter replicas preprod"
git push
argocd app sync weather-app-preprod
```

**Prod:**
```bash
# Éditer overlays/prod/deployment-patch.yaml
spec:
  replicas: 5  # Changer de 3 à 5

# OU utiliser HPA automatiquement
```

### Modifier les Ressources

**Preprod:**
```yaml
# overlays/preprod/deployment-patch.yaml
resources:
  requests:
    memory: "128Mi"  # Au lieu de 64Mi
    cpu: "100m"      # Au lieu de 50m
  limits:
    memory: "256Mi"  # Au lieu de 128Mi
    cpu: "500m"      # Au lieu de 200m
```

**Prod:**
```yaml
# overlays/prod/deployment-patch.yaml
resources:
  requests:
    memory: "512Mi"  # Au lieu de 256Mi
    cpu: "500m"      # Au lieu de 200m
  limits:
    memory: "1Gi"    # Au lieu de 512Mi
    cpu: "2000m"     # Au lieu de 1000m
```

## 🐛 Dépannage Rapide

### Application ne se sync pas

```bash
# Forcer la synchronisation
argocd app sync weather-app-preprod --force --prune

# Vérifier les erreurs
argocd app get weather-app-preprod
kubectl get events -n weather-preprod --sort-by='.lastTimestamp'
```

### Pods en CrashLoopBackOff

```bash
# Vérifier les logs
kubectl logs -l app=weather-app -n weather-preprod --tail=50

# Vérifier les secrets
kubectl get secret weather-app-secret -n weather-preprod -o yaml

# Vérifier la configuration
kubectl describe deployment weather-app -n weather-preprod
```

### Image non trouvée

```bash
# Vérifier l'image
docker pull votre-registry/weather-app:preprod

# Vérifier la config Kustomize
kustomize build overlays/preprod | grep image:

# Pousser l'image si nécessaire
docker push votre-registry/weather-app:preprod
```

### Out of Sync

```bash
# Voir les différences
argocd app diff weather-app-preprod

# Sync avec prune
argocd app sync weather-app-preprod --prune

# Hard refresh
argocd app get weather-app-preprod --hard-refresh
```

## 📊 Monitoring

### Interface Argo CD

```bash
# Port-forward vers Argo CD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Login
argocd login localhost:8080

# Obtenir le mot de passe admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

### Métriques

```bash
# Status global
make status

# Détails preprod
make status-preprod
kubectl top pods -n weather-preprod

# Détails prod
make status-prod
kubectl top pods -n weather-prod
kubectl get hpa -n weather-prod
```

## 🔐 Sécurité

### Gérer les Secrets

**Ne JAMAIS commiter les secrets en clair !**

**Option 1: Sealed Secrets**
```bash
kubeseal --controller-name=sealed-secrets \
  --controller-namespace=kube-system \
  < secret.yaml > sealed-secret.yaml
```

**Option 2: External Secrets**
```bash
# Utiliser External Secrets Operator avec Vault, AWS Secrets Manager, etc.
```

**Option 3: Création manuelle** (dev/test uniquement)
```bash
kubectl create secret generic weather-app-secret \
  --from-literal=OPENWEATHER_API_KEY="key" \
  -n weather-preprod
```

## 🎯 Best Practices

1. ✅ **Branches séparées**: `develop` pour preprod, `main` pour prod
2. ✅ **Tags d'images**: `preprod` et `latest` (ou versions sémantiques)
3. ✅ **Sync automatique**: preprod seulement, prod en manuel
4. ✅ **Secrets externes**: Sealed Secrets ou External Secrets
5. ✅ **Tests**: Valider en preprod avant prod
6. ✅ **Monitoring**: Logs, métriques, alertes
7. ✅ **Rollback plan**: Tester les rollbacks régulièrement

## 📚 Ressources

- [README complet](README.md) - Documentation détaillée
- [Argo CD Docs](https://argo-cd.readthedocs.io/)
- [Kustomize Docs](https://kustomize.io/)

---

**Prêt à déployer ?** Suivez la checklist et lancez `make deploy-all` ! 🚀
