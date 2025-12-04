# 🔄 Architecture Hybride : GitHub Actions + Argo CD

Guide pour utiliser **GitHub Actions** pour le CI (Build/Test/Publish) et **Argo CD** pour le CD (Déploiement).

---

## 🎯 Pourquoi cette Architecture ?

### ✅ Avantages

**Séparation des Responsabilités :**
- 🏗️ **GitHub Actions** = CI (Build, Test, Security Scan, Publish)
- 🚀 **Argo CD** = CD (Déploiement, Sync, GitOps)

**Meilleur des Deux Mondes :**
- GitHub Actions : Excellent pour CI/CD classique
- Argo CD : Excellent pour GitOps et gestion d'état

**Flexibilité :**
- Déploiements indépendants du build
- Rollback facile avec Argo CD
- Drift detection automatique

---

## 📊 Architecture du Pipeline

```
┌──────────────────────────────────────────────────────────────┐
│                       GIT PUSH                               │
│                    (develop / main)                          │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                   GITHUB ACTIONS (CI)                        │
│  ┌────────┐   ┌────────┐   ┌──────────┐   ┌────────────┐  │
│  │ BUILD  │ → │  TEST  │ → │ SECURITY │ → │  PUBLISH   │  │
│  │ Docker │   │ pytest │   │  Trivy   │   │    GHCR    │  │
│  └────────┘   └────────┘   └──────────┘   └────────────┘  │
│                                                   │          │
│                              (optionnel)          ▼          │
│                           ┌────────────────────────────┐    │
│                           │  UPDATE KUSTOMIZATION.YAML │    │
│                           │  avec nouveau tag image    │    │
│                           └────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
                            │
                            │ Git commit (nouveau tag)
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                        ARGO CD (CD)                          │
│  ┌────────┐   ┌────────┐   ┌────────┐   ┌─────────────┐   │
│  │ DETECT │ → │  SYNC  │ → │ DEPLOY │ → │   MONITOR   │   │
│  │ Change │   │  Diff  │   │  Apply │   │    Health   │   │
│  └────────┘   └────────┘   └────────┘   └─────────────┘   │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
                  ☸️  KUBERNETES CLUSTER
```

---

## 🚀 Workflow GitHub Actions (CI uniquement)

### Jobs Inclus

✅ **build** - Build et push image vers GHCR  
✅ **security-scan** - Scan Trivy + GitHub Security  
✅ **lint** - Qualité du code (flake8, pylint, black)  
✅ **test** - Tests unitaires (pytest)  
✅ **update-manifests** - Update Kustomize (optionnel)  
✅ **summary** - Résumé du workflow  

### Ce que GitHub Actions FAIT

- ✅ Build l'image Docker
- ✅ Run les tests
- ✅ Scan de sécurité
- ✅ Publish vers GHCR
- ✅ (Optionnel) Update le tag d'image dans Git

### Ce que GitHub Actions NE FAIT PAS

- ❌ Déployer sur Kubernetes
- ❌ Gérer les environnements
- ❌ Rollback
- ❌ Health checks Kubernetes

---

## ⚙️ Configuration Argo CD

### Applications Argo CD

Tu dois avoir ces applications configurées :

```yaml
# k8s-argocd/argocd-preprod.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: weather-app-preprod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/TON-USERNAME/weather-app.git
    targetRevision: develop
    path: k8s-argocd/overlays/preprod
  destination:
    server: https://kubernetes.default.svc
    namespace: weather-preprod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Synchronisation Automatique

Argo CD va :
1. **Détecter** le changement dans Git (poll 3 min)
2. **Comparer** l'état désiré vs état actuel
3. **Synchroniser** automatiquement (si auto-sync activé)
4. **Monitorer** la santé de l'application

---

## 🔄 Workflow Complet

### Option 1 : Update Automatique (Recommandé)

**Avec le job `update-manifests` activé dans le workflow :**

```
1. Developer push code
   ↓
2. GitHub Actions:
   - Build image → ghcr.io/user/app:sha-abc123
   - Scan sécurité
   - Update k8s-argocd/overlays/preprod/kustomization.yaml
   - Commit + push
   ↓
3. Argo CD détecte le nouveau commit
   ↓
4. Argo CD sync automatiquement
   ↓
5. Application déployée ✅
```

### Option 2 : Update Manuel

**Sans le job `update-manifests` (pour plus de contrôle) :**

```bash
# 1. GitHub Actions build et push l'image
# ghcr.io/user/weather-app:sha-abc123 disponible

# 2. Manuellement, update le kustomization.yaml
cd k8s-argocd/overlays/preprod
nano kustomization.yaml
# Changer newTag: sha-abc123

# 3. Commit et push
git commit -am "deploy: update to sha-abc123"
git push

# 4. Argo CD détecte et sync
# Ou sync manuellement :
argocd app sync weather-app-preprod
```

---

## 📝 Configuration Requise

### 1. Secrets GitHub (pour CI)

**Settings → Secrets and variables → Actions**

Aucun secret Kubernetes nécessaire ! Juste :
- (Optionnel) `DOCKERHUB_TOKEN` si tu pull des images privées

`GITHUB_TOKEN` est fourni automatiquement.

### 2. Argo CD (pour CD)

```bash
# Installer Argo CD
kubectl create namespace argocd
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Créer les applications
kubectl apply -f k8s-argocd/argocd-preprod.yaml
kubectl apply -f k8s-argocd/argocd-prod.yaml

# Accéder à l'UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Password admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

---

## 🎯 Environnements

### Preprod (develop)

**GitHub Actions :**
- Build sur push vers `develop`
- Tag : `ghcr.io/user/app:develop` et `sha-abc123`

**Argo CD :**
- Auto-sync : ✅ Activé
- Source : branch `develop`
- Path : `k8s-argocd/overlays/preprod`

### Production (main)

**GitHub Actions :**
- Build sur push vers `main`
- Tag : `ghcr.io/user/app:main`, `latest` et `sha-abc123`

**Argo CD :**
- Auto-sync : ❌ Manuel (recommandé)
- Source : branch `main`
- Path : `k8s-argocd/overlays/prod`
- Sync manuel requis

---

## 🔧 Commandes Utiles

### GitHub Actions

```bash
# Voir les workflows
gh workflow list

# Voir les runs
gh run list

# Logs d'un run
gh run view <run-id> --log
```

### Argo CD

```bash
# Lister les applications
argocd app list

# Statut d'une app
argocd app get weather-app-preprod

# Synchroniser manuellement
argocd app sync weather-app-preprod

# Voir les différences
argocd app diff weather-app-preprod

# Rollback
argocd app rollback weather-app-preprod <revision-id>

# Historique
argocd app history weather-app-preprod
```

### Vérifier Images GHCR

```bash
# Lister les images
gh api /user/packages/container/weather-app/versions | jq '.[].metadata.container.tags'

# Pull une image
docker pull ghcr.io/TON-USERNAME/weather-app:sha-abc123
```

---

## 🎨 Tags d'Images

GitHub Actions génère automatiquement ces tags :

| Événement | Tags Générés |
|-----------|--------------|
| **Push develop** | `develop`, `sha-abc123` |
| **Push main** | `main`, `latest`, `sha-abc123` |
| **Pull Request** | `pr-123`, `sha-abc123` |
| **Tag v1.0.0** | `v1.0.0`, `1.0`, `sha-abc123` |

**Recommandation :** Utilise les tags `sha-` pour le déploiement (immutable).

---

## ✅ Avantages de cette Architecture

### 🏗️ Pour le CI (GitHub Actions)

- ✅ Intégré nativement avec GitHub
- ✅ GHCR automatique
- ✅ GitHub Security pour les vulnérabilités
- ✅ Facile à configurer
- ✅ Pas besoin de KUBECONFIG

### 🚀 Pour le CD (Argo CD)

- ✅ GitOps pur
- ✅ Drift detection automatique
- ✅ Self-healing
- ✅ Rollback facile
- ✅ UI dédiée pour les déploiements
- ✅ Multi-clusters supporté
- ✅ State déclaré dans Git

### 🎯 Global

- ✅ Séparation des responsabilités
- ✅ Chaque outil fait ce qu'il fait de mieux
- ✅ Flexibilité maximale
- ✅ Audit trail complet
- ✅ Scalabilité

---

## 🐛 Dépannage

### Image buildée mais pas déployée

**Vérifier Argo CD :**
```bash
argocd app get weather-app-preprod
# Regarde le status et les conditions
```

**Forcer un refresh :**
```bash
argocd app get weather-app-preprod --refresh
```

### Argo CD ne détecte pas les changements

**Vérifier la configuration :**
```bash
argocd app get weather-app-preprod -o yaml | grep -A 10 source
```

**Vérifier que le path est correct :**
```bash
# Dans le repo Git, vérifier que ce chemin existe :
# k8s-argocd/overlays/preprod/
```

### Images GHCR privées

**Créer un imagePullSecret :**
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=TON-USERNAME \
  --docker-password=TON-GITHUB-TOKEN \
  -n weather-preprod
```

**Référencer dans kustomization.yaml :**
```yaml
patches:
  - patch: |-
      - op: add
        path: /spec/template/spec/imagePullSecrets
        value:
          - name: ghcr-secret
    target:
      kind: Deployment
```

---

## 📚 Documentation

- [GitHub Actions Workflow](../.github/workflows/ci.yml)
- [Argo CD Applications](../k8s-argocd/)
- [Kustomize Overlays](../k8s-argocd/overlays/)
- [Troubleshooting Argo CD](../k8s-argocd/TROUBLESHOOTING.md)

---

## 🎯 Résumé

Cette architecture hybride te donne :

**GitHub Actions** gère :
- ✅ Build
- ✅ Test
- ✅ Scan
- ✅ Publish

**Argo CD** gère :
- ✅ Deploy
- ✅ Sync
- ✅ Monitor
- ✅ Rollback

**= Architecture professionnelle et scalable !** 🚀

---

## 🚀 Démarrage Rapide

```bash
# 1. Push code sur GitHub
git push origin develop

# 2. GitHub Actions build automatiquement
# Voir: Actions → CI - Build & Publish

# 3. Argo CD détecte et déploie
# Voir: Argo CD UI → weather-app-preprod

# 4. Vérifier le déploiement
kubectl get pods -n weather-preprod
```

**C'est tout !** Le reste est automatique. 🎉
