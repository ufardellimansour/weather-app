# 🚀 Guide de Configuration GitLab CI/CD

Guide complet pour configurer le pipeline CI/CD GitLab pour l'application Weather App.

## 📋 Prérequis

- [x] Repository GitLab avec le code
- [x] GitLab Runner configuré
- [x] Cluster Kubernetes accessible
- [x] Helm 3 installé sur le runner
- [x] Clé API OpenWeatherMap

---

## 🔧 Configuration GitLab

### 1. Variables CI/CD

Allez dans **Settings → CI/CD → Variables** et ajoutez :

#### Variables Obligatoires

| Variable | Valeur | Protected | Masked | Description |
|----------|--------|-----------|--------|-------------|
| `KUBECONFIG_CONTENT` | (contenu en base64) | ✅ | ❌ | Config Kubernetes en base64 |
| `OPENWEATHER_API_KEY_PREPROD` | `votre-cle-api` | ✅ | ✅ | Clé API preprod |
| `OPENWEATHER_API_KEY_PROD` | `votre-cle-api` | ✅ | ✅ | Clé API production |

#### Variables Optionnelles

| Variable | Valeur | Description |
|----------|--------|-------------|
| `CI_REGISTRY` | `registry.gitlab.com` | Registry Docker (auto) |
| `CI_REGISTRY_USER` | `$CI_REGISTRY_USER` | Username registry (auto) |
| `CI_REGISTRY_PASSWORD` | `$CI_REGISTRY_PASSWORD` | Password registry (auto) |
| `CI_REGISTRY_IMAGE` | `registry.gitlab.com/namespace/project` | Image path (auto) |

### 2. Créer KUBECONFIG_CONTENT

Sur votre machine avec accès kubectl :

```bash
# Encoder votre kubeconfig en base64
cat ~/.kube/config | base64 -w 0

# Ou sur macOS
cat ~/.kube/config | base64

# Copier la sortie et la coller dans GitLab
```

**⚠️ Important** : Le fichier kubeconfig doit contenir les certificats et tokens nécessaires.

---

## 🐳 Configuration du Registry GitLab

### Activer le Container Registry

1. Allez dans **Settings → General → Visibility**
2. Activez **Container Registry**

### Tester l'Accès au Registry

```bash
# Login
docker login registry.gitlab.com

# Tagger une image
docker tag weather-app:latest registry.gitlab.com/votre-namespace/weather-app/backend:latest

# Pousser
docker push registry.gitlab.com/votre-namespace/weather-app/backend:latest
```

---

## 🏃 Configuration du GitLab Runner

### Option 1 : Runner Partagé GitLab.com

Utilisez les runners partagés de GitLab (déjà configurés).

### Option 2 : Runner Dédié

#### Installation du Runner

```bash
# Sur une VM ou serveur
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
sudo apt-get install gitlab-runner

# Enregistrer le runner
sudo gitlab-runner register
```

Paramètres d'enregistrement :
- **GitLab URL** : `https://gitlab.com/`
- **Token** : (trouvé dans Settings → CI/CD → Runners)
- **Description** : `kubernetes-runner`
- **Tags** : `docker,kubernetes`
- **Executor** : `docker`
- **Default image** : `alpine:latest`

#### Configuration pour Docker-in-Docker

Éditez `/etc/gitlab-runner/config.toml` :

```toml
[[runners]]
  name = "kubernetes-runner"
  url = "https://gitlab.com/"
  token = "YOUR_TOKEN"
  executor = "docker"
  [runners.docker]
    image = "alpine:latest"
    privileged = true
    volumes = ["/certs/client", "/cache"]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
```

Redémarrer :
```bash
sudo gitlab-runner restart
```

---

## 🔐 Secrets Kubernetes

### Créer les Secrets Manuellement

Avant le premier déploiement :

```bash
# Preprod
kubectl create secret generic weather-app-preprod-secret \
  --from-literal=openweather-api-key="VOTRE_CLE_PREPROD" \
  -n weather-preprod

# Production
kubectl create secret generic weather-app-prod-secret \
  --from-literal=openweather-api-key="VOTRE_CLE_PROD" \
  -n weather-prod
```

### OU : Utiliser des Sealed Secrets (Recommandé)

```bash
# Installer Sealed Secrets Controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Créer un sealed secret
echo -n "ma-cle-api" | kubectl create secret generic weather-app-secret \
  --dry-run=client \
  --from-file=openweather-api-key=/dev/stdin \
  -o yaml | \
kubeseal -o yaml > sealed-secret.yaml

# Commiter (c'est sûr)
git add sealed-secret.yaml
git commit -m "Add sealed secret"
git push
```

---

## 📝 Structure du Pipeline

### Stages du Pipeline

```
┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
│  BUILD  │ → │  TEST   │ → │ PUBLISH │ → │ DEPLOY  │
└─────────┘   └─────────┘   └─────────┘   └─────────┘
```

### Jobs Détaillés

#### BUILD Stage
- `build:backend` - Build de l'image backend
- `build:frontend` - Build de l'image frontend

#### TEST Stage
- `test:security-scan` - Scan de sécurité avec Trivy
- `test:lint` - Vérification du code
- `test:unit` - Tests unitaires

#### PUBLISH Stage
- `publish:backend` - Push backend vers registry
- `publish:frontend` - Push frontend vers registry
- `publish:release` - Publier un tag de release

#### DEPLOY Stage
- `deploy:preprod` - Déploiement automatique en preprod
- `deploy:production` - Déploiement manuel en production
- `deploy:review` - Review apps pour les MR

---

## 🚀 Workflow GitOps

### Développement → Preprod

```bash
# 1. Créer une branche
git checkout -b feature/ma-fonctionnalite

# 2. Coder
# ... modifications ...

# 3. Commit et push
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin feature/ma-fonctionnalite

# 4. Créer une Merge Request
# → Review App déployée automatiquement

# 5. Merge dans develop
# → Déploiement automatique en preprod
```

### Preprod → Production

```bash
# 1. Tests OK en preprod
# 2. Merge develop → main
git checkout main
git merge develop
git push origin main

# 3. Le pipeline détecte le push sur main
# 4. Build et publish des images
# 5. Job "deploy:production" apparaît (manuel)
# 6. Cliquer sur "Play" dans GitLab UI
# 7. Déploiement en production
```

### Release avec Tag

```bash
# Créer un tag
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0

# Le job "publish:release" s'exécute
# Images taguées avec v1.0.0
```

---

## 🔄 Commandes Helm via Pipeline

Le pipeline exécute automatiquement :

### Preprod (Automatique sur develop)

```bash
helm upgrade --install weather-app-preprod ./helm/weather-app \
  --namespace weather-preprod \
  --create-namespace \
  --set image.repository=$CI_REGISTRY_IMAGE/backend \
  --set image.tag=$CI_COMMIT_SHORT_SHA \
  --set environment=preprod \
  --values ./helm/weather-app/values-preprod.yaml \
  --wait --timeout 5m
```

### Production (Manuel sur main)

```bash
helm upgrade --install weather-app-prod ./helm/weather-app \
  --namespace weather-prod \
  --create-namespace \
  --set image.repository=$CI_REGISTRY_IMAGE/backend \
  --set image.tag=$CI_COMMIT_SHORT_SHA \
  --set environment=production \
  --values ./helm/weather-app/values-prod.yaml \
  --wait --timeout 10m
```

---

## 📊 Environnements GitLab

Le pipeline crée automatiquement ces environnements dans GitLab :

- **preprod** : `https://weather-preprod.example.com`
- **production** : `https://weather.example.com`
- **review/mr-X** : `https://mr-X.weather-review.example.com`

Visible dans : **Deployments → Environments**

---

## 🧪 Tester le Pipeline

### 1. Premier Push

```bash
git add .
git commit -m "ci: add GitLab CI/CD pipeline"
git push origin develop
```

### 2. Vérifier dans GitLab

Allez dans **CI/CD → Pipelines** pour voir l'exécution.

### 3. Voir les Logs

Cliquez sur un job pour voir les logs détaillés.

### 4. Accéder à l'Application

Une fois déployé :
```bash
# Trouver l'URL de l'Ingress
kubectl get ingress -n weather-preprod

# Ou port-forward
kubectl port-forward service/weather-app-preprod 8080:80 -n weather-preprod
```

---

## 🐛 Dépannage

### Pipeline Bloqué à "Build"

**Problème** : Pas de runner disponible

**Solution** :
```bash
# Vérifier les runners
# Dans GitLab : Settings → CI/CD → Runners

# Si runner dédié, vérifier qu'il tourne
sudo gitlab-runner status
sudo gitlab-runner verify
```

### Erreur "docker: command not found"

**Problème** : Runner mal configuré

**Solution** : Utiliser l'image `docker:24-dind` et le service `docker:24-dind`

### Erreur "kubectl: connection refused"

**Problème** : KUBECONFIG_CONTENT invalide

**Solution** :
```bash
# Re-générer le kubeconfig en base64
cat ~/.kube/config | base64 -w 0

# Mettre à jour dans GitLab
# Settings → CI/CD → Variables → KUBECONFIG_CONTENT
```

### Helm Install Failed

**Problème** : Chart invalide ou ressources manquantes

**Solution** :
```bash
# Valider le chart localement
helm lint ./helm/weather-app

# Tester en dry-run
helm install weather-app ./helm/weather-app --dry-run --debug

# Voir les erreurs Kubernetes
kubectl get events -n weather-preprod --sort-by='.lastTimestamp'
```

---

## 📚 Ressources

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [GitLab Container Registry](https://docs.gitlab.com/ee/user/packages/container_registry/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

## ✅ Checklist Complète

### Avant le Premier Déploiement

- [ ] Repository GitLab créé
- [ ] Code poussé sur GitLab
- [ ] `.gitlab-ci.yml` présent à la racine
- [ ] Chart Helm créé dans `helm/weather-app/`
- [ ] Variables CI/CD configurées
  - [ ] `KUBECONFIG_CONTENT`
  - [ ] `OPENWEATHER_API_KEY_PREPROD`
  - [ ] `OPENWEATHER_API_KEY_PROD`
- [ ] GitLab Runner configuré (ou utiliser runners partagés)
- [ ] Container Registry activé
- [ ] Cluster Kubernetes accessible

### Après Configuration

- [ ] Premier pipeline exécuté avec succès
- [ ] Images publiées dans le registry
- [ ] Application déployée en preprod
- [ ] Ingress configuré et accessible
- [ ] Tests fonctionnels OK
- [ ] Déploiement en production testé

---

**Prêt à déployer !** 🚀

Tout commit sur `develop` déclenchera un déploiement automatique en preprod.
Pour la production, merge dans `main` et cliquez sur le job manuel.
