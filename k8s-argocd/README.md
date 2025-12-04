# 🚀 Déploiement Multi-Environnements avec Argo CD

Structure Kustomize pour déployer l'application Weather App sur plusieurs environnements (preprod et prod).

## 📁 Structure des Dossiers

```
k8s-argocd/
├── base/                          # Ressources communes à tous les environnements
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
│
├── overlays/
│   ├── preprod/                   # Configuration preprod
│   │   ├── namespace.yaml
│   │   ├── configmap.yaml
│   │   ├── deployment-patch.yaml  # 1 replica, ressources réduites
│   │   ├── ingress.yaml
│   │   └── kustomization.yaml
│   │
│   └── prod/                      # Configuration production
│       ├── namespace.yaml
│       ├── configmap.yaml
│       ├── deployment-patch.yaml  # 3 replicas, ressources augmentées
│       ├── ingress.yaml
│       ├── hpa.yaml               # Autoscaling (3-10 pods)
│       ├── pdb.yaml               # PodDisruptionBudget
│       └── kustomization.yaml
│
├── argocd-preprod.yaml            # Application Argo CD pour preprod
└── argocd-prod.yaml               # Application Argo CD pour prod
```

## 🔧 Différences entre Environnements

### Preprod
- **Namespace**: `weather-preprod`
- **Replicas**: 1
- **Resources**: 64Mi-128Mi RAM, 50m-200m CPU
- **Domain**: `weather-preprod.example.com`
- **TLS**: Let's Encrypt Staging
- **Image Tag**: `preprod`
- **Branch Git**: `develop`
- **Sync**: Automatique

### Production
- **Namespace**: `weather-prod`
- **Replicas**: 3 (min) - 10 (max avec HPA)
- **Resources**: 256Mi-512Mi RAM, 200m-1000m CPU
- **Domain**: `weather.example.com`
- **TLS**: Let's Encrypt Production
- **Image Tag**: `latest`
- **Branch Git**: `main`
- **Sync**: Manuel (à activer si souhaité)
- **Extras**: HPA, PodDisruptionBudget

## 📋 Prérequis

1. **Cluster Kubernetes** avec Argo CD installé
2. **Repository Git** avec le code de l'application
3. **Docker Registry** (Docker Hub, GCR, ECR, Harbor, etc.)
4. **Clé API OpenWeatherMap** pour chaque environnement
5. **(Optionnel)** Cert-manager pour les certificats TLS

## 🚀 Déploiement Initial

### Étape 1 : Préparer le Repository Git

```bash
# Cloner ou initialiser votre repo
git clone https://github.com/votre-username/weather-app.git
cd weather-app

# Créer les branches
git checkout -b develop
git push origin develop

git checkout -b main
git push origin main
```

### Étape 2 : Configurer les Images Docker

Éditez les fichiers `kustomization.yaml` de chaque environnement :

**Preprod** (`overlays/preprod/kustomization.yaml`):
```yaml
images:
  - name: weather-app
    newName: votre-registry/weather-app
    newTag: preprod
```

**Prod** (`overlays/prod/kustomization.yaml`):
```yaml
images:
  - name: weather-app
    newName: votre-registry/weather-app
    newTag: latest
```

### Étape 3 : Gérer les Secrets

⚠️ **IMPORTANT**: Ne commitez JAMAIS les secrets en clair dans Git !

**Option 1: Sealed Secrets (Recommandé)**

```bash
# Installer Sealed Secrets
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Créer un secret scellé
echo -n "your-api-key" | kubectl create secret generic weather-app-secret \
  --dry-run=client \
  --from-file=OPENWEATHER_API_KEY=/dev/stdin \
  -o yaml | \
kubeseal -o yaml > overlays/preprod/sealed-secret.yaml

# Commiter le sealed-secret.yaml (c'est sûr)
git add overlays/preprod/sealed-secret.yaml
git commit -m "Add sealed secret for preprod"
```

**Option 2: External Secrets Operator**

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: weather-app-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: weather-app-secret
  data:
  - secretKey: OPENWEATHER_API_KEY
    remoteRef:
      key: weather-app/openweather-api-key
```

**Option 3: Création manuelle (Dev/Test)**

```bash
# Preprod
kubectl create secret generic weather-app-secret \
  --from-literal=OPENWEATHER_API_KEY="votre-cle-preprod" \
  -n weather-preprod

# Prod
kubectl create secret generic weather-app-secret \
  --from-literal=OPENWEATHER_API_KEY="votre-cle-prod" \
  -n weather-prod
```

### Étape 4 : Configurer les Applications Argo CD

Éditez `argocd-preprod.yaml` et `argocd-prod.yaml` :

```yaml
source:
  repoURL: https://github.com/VOTRE-USERNAME/weather-app.git  # Votre repo
```

### Étape 5 : Déployer avec Argo CD

```bash
# Déployer l'application preprod
kubectl apply -f k8s-argocd/argocd-preprod.yaml

# Déployer l'application prod
kubectl apply -f k8s-argocd/argocd-prod.yaml

# Vérifier le statut
argocd app list
argocd app get weather-app-preprod
argocd app get weather-app-prod
```

### Étape 6 : Synchroniser les Applications

**Preprod** (automatique par défaut):
```bash
# Devrait se synchroniser automatiquement
# Sinon, forcer la sync:
argocd app sync weather-app-preprod
```

**Prod** (manuel par défaut):
```bash
# Synchroniser manuellement
argocd app sync weather-app-prod

# Ou activer l'auto-sync en décommentant dans argocd-prod.yaml:
# syncPolicy:
#   automated:
#     prune: true
#     selfHeal: true
```

## 🔄 Workflow GitOps

### 1. Développement → Preprod

```bash
# Faire des changements
git checkout develop
# ... modifications ...

# Build et push de l'image
docker build -t votre-registry/weather-app:preprod .
docker push votre-registry/weather-app:preprod

# Commit et push
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin develop

# Argo CD détecte et déploie automatiquement en preprod
```

### 2. Preprod → Production

```bash
# Merge develop dans main
git checkout main
git merge develop
git push origin main

# Build et push de l'image production
docker build -t votre-registry/weather-app:latest .
docker push votre-registry/weather-app:latest

# Argo CD détecte le changement
# Sync manuel en production (si activé)
argocd app sync weather-app-prod
```

## 📊 Commandes de Gestion

### Argo CD CLI

```bash
# Lister les applications
argocd app list

# Voir les détails
argocd app get weather-app-preprod
argocd app get weather-app-prod

# Synchroniser
argocd app sync weather-app-preprod
argocd app sync weather-app-prod

# Voir les différences
argocd app diff weather-app-preprod
argocd app diff weather-app-prod

# Historique des déploiements
argocd app history weather-app-prod

# Rollback
argocd app rollback weather-app-prod <revision-id>

# Supprimer une application
argocd app delete weather-app-preprod
```

### Kubectl

```bash
# Vérifier les pods
kubectl get pods -n weather-preprod
kubectl get pods -n weather-prod

# Logs
kubectl logs -f -l app=weather-app -n weather-preprod
kubectl logs -f -l app=weather-app -n weather-prod

# Statut du HPA (prod uniquement)
kubectl get hpa -n weather-prod

# Événements
kubectl get events -n weather-preprod --sort-by='.lastTimestamp'
kubectl get events -n weather-prod --sort-by='.lastTimestamp'
```

### Test en Local avec Kustomize

```bash
# Générer les manifests sans appliquer
kustomize build k8s-argocd/overlays/preprod
kustomize build k8s-argocd/overlays/prod

# Appliquer directement
kubectl apply -k k8s-argocd/overlays/preprod
kubectl apply -k k8s-argocd/overlays/prod
```

## 🔐 Sécurité des Secrets

### Best Practices

1. **Sealed Secrets** ou **External Secrets Operator** pour les secrets
2. **RBAC** approprié pour limiter l'accès
3. **Secrets séparés** par environnement
4. **Rotation régulière** des clés API
5. **Ne JAMAIS commiter** de secrets en clair

### Exemple Sealed Secret

```bash
# Créer un sealed secret
kubectl create secret generic weather-app-secret \
  --from-literal=OPENWEATHER_API_KEY="ma-cle-secrete" \
  --dry-run=client -o yaml | \
kubeseal --controller-name=sealed-secrets-controller \
  --controller-namespace=kube-system \
  --format yaml > sealed-secret.yaml

# Ce fichier peut être commité en toute sécurité
git add sealed-secret.yaml
git commit -m "Add sealed secret"
```

## 🎯 Stratégies de Déploiement

### Rolling Update (par défaut)
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```

### Blue/Green Deployment
```bash
# Créer une nouvelle version
kubectl apply -k overlays/prod

# Tester la nouvelle version
# Basculer le trafic via le Service
```

### Canary Deployment
Utilisez **Argo Rollouts** pour des déploiements canary avancés:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
# ... configuration canary
```

## 📈 Monitoring et Observabilité

### Prometheus Metrics
```bash
# Ajouter des annotations pour Prometheus
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "5000"
  prometheus.io/path: "/metrics"
```

### Logs
```bash
# Logs en temps réel
kubectl logs -f -l app=weather-app -n weather-prod

# Logs agrégés avec Stern
stern weather-app -n weather-prod
```

### Argo CD UI
Accédez à l'interface Argo CD pour voir:
- État des applications
- Historique des syncs
- Différences entre Git et le cluster
- Logs des déploiements

## 🐛 Dépannage

### Application ne se synchronise pas

```bash
# Vérifier les logs Argo CD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Forcer une refresh
argocd app sync weather-app-preprod --force

# Vérifier les différences
argocd app diff weather-app-preprod
```

### Pods ne démarrent pas

```bash
# Vérifier les événements
kubectl describe pod <pod-name> -n weather-preprod

# Vérifier les secrets
kubectl get secret weather-app-secret -n weather-preprod -o yaml

# Vérifier les logs
kubectl logs <pod-name> -n weather-preprod
```

### Image non trouvée

```bash
# Vérifier que l'image existe dans le registry
docker pull votre-registry/weather-app:preprod

# Vérifier les imagePullSecrets si registry privé
kubectl get secret -n weather-preprod
```

## 📚 Ressources Utiles

- [Documentation Argo CD](https://argo-cd.readthedocs.io/)
- [Kustomize Documentation](https://kustomize.io/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [External Secrets Operator](https://external-secrets.io/)

## 🔄 Checklist de Déploiement

### Preprod
- [ ] Repository Git configuré (branche `develop`)
- [ ] Image Docker taguée `preprod` et poussée
- [ ] Secret créé dans le namespace `weather-preprod`
- [ ] Application Argo CD créée (`argocd-preprod.yaml`)
- [ ] Domaine `weather-preprod.example.com` configuré
- [ ] Application synchronisée et fonctionnelle

### Production
- [ ] Repository Git configuré (branche `main`)
- [ ] Image Docker taguée `latest` et poussée
- [ ] Secret créé dans le namespace `weather-prod`
- [ ] Application Argo CD créée (`argocd-prod.yaml`)
- [ ] Domaine `weather.example.com` configuré
- [ ] PodDisruptionBudget vérifié
- [ ] HPA configuré et fonctionnel
- [ ] Monitoring en place
- [ ] Tests de charge effectués
- [ ] Plan de rollback préparé

---

**Note**: Adaptez les domaines, registry, et configurations selon votre infrastructure !
