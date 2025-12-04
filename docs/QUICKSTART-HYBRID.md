# 🚀 Démarrage Rapide - GitHub Actions + Argo CD

Configuration en **10 minutes** pour une architecture CI/CD professionnelle.

---

## ⚡ Configuration Express

### 1. Push sur GitHub (1 min)

```bash
git remote add origin https://github.com/VOTRE-USERNAME/weather-app.git
git checkout -b develop
git push -u origin develop
git checkout -b main
git push -u origin main
```

### 2. GitHub Actions - Aucun Secret Requis ! (0 min)

**Le workflow est prêt !** Aucune configuration GitHub nécessaire.

- ✅ `GITHUB_TOKEN` est fourni automatiquement
- ✅ Permissions GHCR configurées dans le workflow
- ✅ Pas de secrets Kubernetes nécessaires

Le workflow se lance automatiquement sur chaque push.

### 3. Installer Argo CD (3 min)

```bash
# Créer le namespace
kubectl create namespace argocd

# Installer Argo CD
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Attendre que les pods soient prêts
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### 4. Accéder à Argo CD UI (2 min)

```bash
# Port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Obtenir le mot de passe admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Ouvrir dans le navigateur
open https://localhost:8080
# Username: admin
# Password: (celui obtenu ci-dessus)
```

### 5. Configurer les Applications Argo CD (2 min)

```bash
# Éditer avec ton username GitHub
cd k8s-argocd
nano argocd-preprod.yaml  # Remplacer VOTRE-USERNAME
nano argocd-prod.yaml     # Remplacer VOTRE-USERNAME

# Créer les applications
kubectl apply -f argocd-preprod.yaml
kubectl apply -f argocd-prod.yaml
```

### 6. Créer les Secrets Kubernetes (2 min)

```bash
# Obtenir une clé API gratuite sur:
# https://openweathermap.org/api

# Créer le secret preprod
kubectl create secret generic weather-app-secret \
  --from-literal=openweather-api-key="VOTRE-CLE-API" \
  -n weather-preprod

# Créer le secret prod
kubectl create secret generic weather-app-secret \
  --from-literal=openweather-api-key="VOTRE-CLE-API" \
  -n weather-prod
```

---

## ✅ Vérification

### GitHub Actions

```bash
# Via GitHub UI
# → Actions → CI - Build & Publish
# Tous les jobs doivent être verts ✅

# Via CLI
gh run list
gh run view <run-id>
```

### Argo CD

```bash
# Via Argo CD UI
# → Applications → weather-app-preprod
# Status: Healthy + Synced ✅

# Via CLI
argocd app list
argocd app get weather-app-preprod
```

### Application Déployée

```bash
# Vérifier les pods
kubectl get pods -n weather-preprod

# Port-forward vers l'app
kubectl port-forward service/weather-app -n weather-preprod 8081:80

# Ouvrir
open http://localhost:8081
```

---

## 🔄 Workflow Quotidien

### Développer une Feature

```bash
# 1. Créer une branche
git checkout develop
git checkout -b feature/awesome

# 2. Coder
# ... modifications ...

# 3. Commit et push
git commit -am "feat: awesome feature"
git push origin feature/awesome

# 4. Le workflow GitHub Actions se lance automatiquement
# → Build
# → Test
# → Scan
# → Publish vers GHCR

# 5. Merger dans develop
# Via Pull Request sur GitHub

# 6. Argo CD détecte le changement (3 min max)
# → Sync automatique en preprod ✅
```

### Déployer en Production

```bash
# 1. Créer une PR de develop vers main
git checkout main
git merge develop
git push origin main

# 2. GitHub Actions build l'image
# → ghcr.io/username/weather-app:main
# → ghcr.io/username/weather-app:latest
# → ghcr.io/username/weather-app:sha-abc123

# 3. Dans Argo CD UI
# → weather-app-prod
# → SYNC (manuel)
# → SYNCHRONIZE

# Ou via CLI:
argocd app sync weather-app-prod

# 4. Vérifier
kubectl get pods -n weather-prod
```

---

## 🎯 Architecture Résumé

```
Developer Push
      ↓
GitHub Actions (CI)
  - Build Docker
  - Scan Trivy
  - Publish GHCR
      ↓
Argo CD (CD)
  - Detect changes
  - Sync to K8s
      ↓
Application Running
```

---

## 📊 Ce Qui Se Passe Automatiquement

### Sur chaque Push

✅ **GitHub Actions** :
- Build l'image Docker
- Run les tests (pytest)
- Scan sécurité (Trivy)
- Lint le code (flake8, black)
- Publish sur GHCR
- Affiche un résumé

✅ **Argo CD** (si preprod) :
- Détecte le nouveau commit (3 min)
- Compare l'état désiré vs actuel
- Synchronise automatiquement
- Vérifie la santé de l'app

---

## 🔧 Commandes Essentielles

### GitHub Actions

```bash
# Voir les workflows
gh workflow list

# Déclencher manuellement
gh workflow run ci.yml

# Voir les images GHCR
gh api /user/packages/container/weather-app/versions
```

### Argo CD

```bash
# Lister les apps
argocd app list

# Sync manuel
argocd app sync weather-app-preprod

# Voir les différences
argocd app diff weather-app-preprod

# Rollback
argocd app history weather-app-preprod
argocd app rollback weather-app-preprod 2
```

### Kubernetes

```bash
# Status
kubectl get pods -n weather-preprod
kubectl get pods -n weather-prod

# Logs
kubectl logs -f deployment/weather-app -n weather-preprod

# Port-forward
kubectl port-forward svc/weather-app -n weather-preprod 8081:80
```

---

## 🐛 Problèmes Courants

### Workflow ne démarre pas

**Solution :**
```bash
# Vérifier que le fichier est au bon endroit
ls -la .github/workflows/ci.yml

# Vérifier la syntaxe
cat .github/workflows/ci.yml | yamllint -
```

### Argo CD ne synchronise pas

**Solution :**
```bash
# Forcer un refresh
argocd app get weather-app-preprod --refresh

# Vérifier la config
argocd app get weather-app-preprod -o yaml | grep -A 10 source
```

### Pods en ImagePullBackOff

**Solution :**
```bash
# Rendre l'image publique
# GitHub → Packages → weather-app
# Settings → Change visibility → Public

# Ou créer un imagePullSecret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=TON-USERNAME \
  --docker-password=TON-GITHUB-TOKEN \
  -n weather-preprod
```

### Pods en CrashLoopBackOff

**Solution :**
```bash
# Vérifier les logs
kubectl logs -f deployment/weather-app -n weather-preprod

# Souvent : secret manquant
kubectl create secret generic weather-app-secret \
  --from-literal=openweather-api-key="VOTRE-CLE" \
  -n weather-preprod
```

---

## 📚 Documentation Complète

- [Architecture Hybride](HYBRID-GITHUB-ARGOCD.md) - Guide complet
- [Argo CD README](../k8s-argocd/README.md) - Config Argo CD
- [Troubleshooting](TROUBLESHOOTING-GITHUB-ACTIONS.md) - Dépannage

---

## ✨ Fonctionnalités

### GitHub Actions (CI)

- ✅ Build automatique
- ✅ Tests unitaires
- ✅ Scan de sécurité (Trivy → GitHub Security)
- ✅ Lint code quality
- ✅ Publish GHCR
- ✅ Tags intelligents
- ✅ Cache Docker
- ✅ Résumé workflow

### Argo CD (CD)

- ✅ Sync automatique (preprod)
- ✅ Sync manuel (prod)
- ✅ Drift detection
- ✅ Self-healing
- ✅ Rollback facile
- ✅ UI dédiée
- ✅ Multi-environnements
- ✅ Health checks

---

## 💡 Prochaines Étapes

Une fois que tout fonctionne :

1. ✅ CI/CD configuré
2. [ ] Configurer Ingress avec TLS
3. [ ] Ajouter monitoring (Prometheus/Grafana)
4. [ ] Configurer alerting (Slack)
5. [ ] Ajouter tests E2E
6. [ ] Configurer Blue/Green deployment
7. [ ] Multi-clusters avec Argo CD

---

## 🎉 C'est Parti !

```bash
# 1. Clone le repo
git clone https://github.com/VOTRE-USERNAME/weather-app.git
cd weather-app

# 2. Suis ce guide (10 min)

# 3. Push du code
git push origin develop

# 4. Regarde la magie opérer ! ✨
# GitHub Actions → Build
# Argo CD → Deploy
# Application → Running
```

**Félicitations !** Tu as une architecture CI/CD professionnelle ! 🚀
