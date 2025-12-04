# 🌤️ Weather App - Application Météo Flask

Application Flask Python pour afficher la météo des villes françaises avec déploiement Kubernetes complet via **GitHub Actions** et **Helm**.

[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Ready-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io)
[![Helm](https://img.shields.io/badge/Helm-Charts-0F1689?logo=helm&logoColor=white)](https://helm.sh)
[![Docker](https://img.shields.io/badge/Docker-GHCR-2496ED?logo=docker&logoColor=white)](https://ghcr.io)

---

## 🚀 Démarrage Ultra-Rapide (5 Minutes)

```bash
# 1. Cloner et pousser sur GitHub
git remote add origin https://github.com/VOTRE-USERNAME/weather-app.git
git checkout -b develop
git push -u origin develop

# 2. Configurer 2 secrets GitHub
# Settings → Secrets and variables → Actions
# - KUBECONFIG (base64 de ~/.kube/config)
# - OPENWEATHER_API_KEY_PREPROD

# 3. Le workflow se lance automatiquement ! 🎉
# GitHub → Actions → CI/CD Pipeline
```

📚 **[Guide de démarrage rapide (5 min)](docs/QUICKSTART-GITHUB-ACTIONS.md)**  
📖 **[Documentation complète](docs/GITHUB-ACTIONS-SETUP.md)**

---

## ✨ Fonctionnalités

### 🎯 Application
- ✅ Flask Python 3.11 avec API OpenWeatherMap
- ✅ 20 villes françaises pré-configurées
- ✅ Interface web responsive et moderne
- ✅ API REST JSON (`/meteo/{ville}`)
- ✅ Health checks (liveness + readiness)

### 🔄 CI/CD GitHub Actions
- ✅ **Build** automatique des images Docker
- ✅ **Tests** de sécurité (Trivy → GitHub Security)
- ✅ **Quality** checks (flake8, pylint, black, pytest)
- ✅ **Publish** sur GitHub Container Registry (GHCR)
- ✅ **Deploy** automatisé avec Helm
- ✅ **Review Apps** pour chaque Pull Request
- ✅ **Environments** avec protection et approbations

### ☸️ Kubernetes + Helm
- ✅ **Multi-environnements** (preprod / production)
- ✅ **Autoscaling** horizontal (HPA 3-10 pods)
- ✅ **High availability** (PDB, 3+ replicas)
- ✅ **Health probes** configurés
- ✅ **Ingress** avec TLS (cert-manager)
- ✅ **Rolling updates** zero-downtime
- ✅ **Secrets** managés proprement

---

## 📦 Architecture du Pipeline

```
┌─────────────────────────────────────────────────────────┐
│              GIT PUSH (develop/main)                    │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
    ┌────────┐       ┌────────┐       ┌────────┐
    │ BUILD  │       │  TEST  │       │  LINT  │
    │ Docker │       │ pytest │       │ flake8 │
    │  GHCR  │       │ Trivy  │       │ black  │
    └────────┘       └────────┘       └────────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          ▼
                   ┌────────────┐
                   │  PUBLISH   │
                   │    GHCR    │
                   │ ghcr.io/   │
                   └────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                                   ▼
  ┌──────────┐                        ┌──────────┐
  │ PREPROD  │                        │   PROD   │
  │  Helm    │                        │   Helm   │
  │  (auto)  │                        │ (manual) │
  └──────────┘                        └──────────┘
     develop                              main
```

---

## 🎯 Environnements

| Environnement | Namespace | Replicas | Resources | Deploy | Approbation |
|---------------|-----------|----------|-----------|--------|-------------|
| **Preprod** | `weather-preprod` | 1 | 50m/64Mi | ✅ Auto | ❌ |
| **Production** | `weather-prod` | 3-10 (HPA) | 200m-1000m/256Mi-512Mi | ❌ Manuel | ✅ Requis |
| **Review Apps** | `weather-review-pr-X` | 1 | 50m/64Mi | ✅ Auto | ❌ |

---

## 🛠️ Structure du Projet

```
weather-app/
├── 📄 app.py                      # Application Flask
├── 📋 requirements.txt            # Dépendances Python
├── 🐳 Dockerfile                  # Image Docker
├── 
├── 🔄 .github/
│   └── workflows/
│       └── ci-cd.yml              # Workflow GitHub Actions ⭐
│
├── 📦 helm/
│   └── weather-app/               # Helm Chart complet ⭐
│       ├── Chart.yaml
│       ├── values.yaml            # Valeurs par défaut
│       ├── values-preprod.yaml    # Config preprod
│       ├── values-prod.yaml       # Config production
│       └── templates/             # Templates K8s
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── hpa.yaml
│           └── ...
│
├── 📚 docs/
│   ├── QUICKSTART-GITHUB-ACTIONS.md  # Démarrage rapide (5 min) ⭐
│   ├── GITHUB-ACTIONS-SETUP.md       # Guide complet ⭐
│   └── GITHUB-VS-GITLAB.md           # Comparaison
│
├── ☸️ k8s/                        # Manifests K8s simples (alternatif)
└── ☸️ k8s-argocd/                 # Config Argo CD (alternatif)
```

---

## 🔄 Workflow GitOps

### Développement → Preprod (Automatique)

```bash
# 1. Créer une feature branch
git checkout -b feature/awesome-feature

# 2. Développer
# ... modifications ...

# 3. Créer une Pull Request vers develop
git push origin feature/awesome-feature
# → Review App déployée automatiquement
# → URL commentée dans la PR

# 4. Merger la PR
# → Workflow déclenché automatiquement
# → Déploiement en preprod ✅
```

### Preprod → Production (Manuel avec Approbation)

```bash
# 1. Créer une PR de develop vers main
# 2. Review et approbation du code
# 3. Merger la PR

# 4. Le workflow démarre automatiquement
# 5. Job "deploy-production" attend une approbation
# 6. Reviewer approuve dans GitHub UI
# 7. Déploiement en production ✅
```

---

## 🐳 Images Docker

Les images sont publiées sur **GitHub Container Registry** :

```bash
# Preprod (branche develop)
ghcr.io/VOTRE-USERNAME/weather-app:develop

# Production (branche main)
ghcr.io/VOTRE-USERNAME/weather-app:main

# Commit spécifique
ghcr.io/VOTRE-USERNAME/weather-app:sha-abc123

# Release tag
ghcr.io/VOTRE-USERNAME/weather-app:v1.0.0
```

---

## 📚 Documentation

### Guides de Démarrage
- 📖 **[Démarrage rapide GitHub Actions (5 min)](docs/QUICKSTART-GITHUB-ACTIONS.md)** ← Commencer ici !
- 📘 **[Configuration complète GitHub Actions](docs/GITHUB-ACTIONS-SETUP.md)**
- 📙 **[Helm Chart README](helm/weather-app/README.md)**

### Comparaisons
- 🔄 **[GitHub Actions vs GitLab CI](docs/GITHUB-VS-GITLAB.md)**

### Alternatives Argo CD
- ⚙️ **[Argo CD avec Kustomize](k8s-argocd/README.md)**
- 🚀 **[Quickstart Argo CD](k8s-argocd/QUICKSTART-ARGOCD.md)**

---

## 🛠️ Développement Local

### Avec Python

```bash
# Cloner le repo
git clone https://github.com/VOTRE-USERNAME/weather-app.git
cd weather-app

# Variables d'environnement
export OPENWEATHER_API_KEY="votre-cle-api"
export PORT=5000

# Installer les dépendances
pip install -r requirements.txt

# Lancer l'application
python app.py
```

Ouvrir http://localhost:5000

### Avec Docker

```bash
# Build
docker build -t weather-app:latest .

# Run
docker run -p 5000:5000 \
  -e OPENWEATHER_API_KEY="votre-cle-api" \
  weather-app:latest
```

### Avec Docker Compose

```bash
# Modifier docker-compose.yaml avec votre clé API
nano docker-compose.yaml

# Lancer
docker-compose up
```

---

## ☸️ Déploiement Manuel (sans CI/CD)

### Avec Helm (Recommandé)

```bash
# Preprod
helm install weather-app-preprod ./helm/weather-app \
  --namespace weather-preprod \
  --create-namespace \
  --values ./helm/weather-app/values-preprod.yaml \
  --set image.repository=ghcr.io/VOTRE-USERNAME/weather-app \
  --set secrets.openweatherApiKey="votre-cle"

# Production
helm install weather-app-prod ./helm/weather-app \
  --namespace weather-prod \
  --create-namespace \
  --values ./helm/weather-app/values-prod.yaml \
  --set image.repository=ghcr.io/VOTRE-USERNAME/weather-app \
  --set secrets.openweatherApiKey="votre-cle"
```

### Avec Kubectl (Simple)

```bash
# Éditer le secret avec votre clé API
nano k8s/secret.yaml

# Déployer
kubectl apply -f k8s/

# Vérifier
kubectl get pods
kubectl port-forward service/weather-app 8080:80
```

---

## 🔐 Secrets GitHub à Configurer

### Obligatoires

1. **KUBECONFIG**
   ```bash
   cat ~/.kube/config | base64 -w 0
   # Copier dans GitHub Secrets
   ```

2. **OPENWEATHER_API_KEY_PREPROD**
   - Clé API OpenWeatherMap pour preprod
   - Obtenir gratuitement sur https://openweathermap.org/api

### Optionnels

3. **OPENWEATHER_API_KEY_PROD**
   - Clé API séparée pour production

---

## 🎯 Fonctionnalités du Workflow

### Build & Publish
- ✅ Build Docker multi-stage optimisé
- ✅ Cache Docker layers (GitHub Cache)
- ✅ Tags automatiques intelligents
- ✅ Push vers GHCR automatique

### Tests & Quality
- ✅ Security scan (Trivy)
- ✅ Upload SARIF → GitHub Security tab
- ✅ Code quality (flake8, pylint, black)
- ✅ Unit tests (pytest)
- ✅ Coverage reports (Codecov)

### Déploiement
- ✅ Helm deploy automatisé
- ✅ Health checks Kubernetes
- ✅ Rollout verification
- ✅ Review apps automatiques
- ✅ Comment PR avec URL
- ✅ Cleanup automatique

### Sécurité
- ✅ GitHub Environments avec protection
- ✅ Required reviewers pour production
- ✅ Secrets chiffrés
- ✅ Vulnerability scanning
- ✅ Dependabot intégré

---

## 🐛 Dépannage Rapide

### Workflow ne démarre pas
```bash
# Vérifier que GitHub Actions est activé
# Settings → Actions → General → Allow all actions
```

### Erreur kubectl
```bash
# KUBECONFIG invalide - Regénérer
cat ~/.kube/config | base64 -w 0
# Mettre à jour dans GitHub Secrets
```

### Pods CrashLoopBackOff
```bash
# Secret manquant
kubectl create secret generic weather-app-preprod-secret \
  --from-literal=openweather-api-key="ta-cle" \
  -n weather-preprod
```

### Images GHCR privées
```bash
# Rendre publiques
# GitHub → Packages → weather-app
# Settings → Change visibility → Public
```

---

## 💰 Quotas Gratuits

### GitHub (Compte Gratuit)
- ✅ **2000 minutes/mois** GitHub Actions
- ✅ **Illimité pour repos publics** 🎉
- ✅ 500 MB storage GHCR
- ✅ 1 GB bandwidth/mois

### Optimisations
- Cache Docker layers activé
- Jobs conditionnels configurés
- Tests parallélisés

---

## 📞 Support & Ressources

### Documentation
- [Démarrage rapide](docs/QUICKSTART-GITHUB-ACTIONS.md)
- [Guide complet](docs/GITHUB-ACTIONS-SETUP.md)
- [Helm Chart](helm/weather-app/README.md)

### Ressources Externes
- [GitHub Actions](https://docs.github.com/en/actions)
- [GHCR](https://docs.github.com/en/packages)
- [Helm](https://helm.sh/docs/)
- [Kubernetes](https://kubernetes.io/docs/)

---

## 🤝 Contribuer

Les contributions sont bienvenues ! Pour contribuer :

1. Fork le projet
2. Créer une branche (`git checkout -b feature/awesome`)
3. Commit les changements (`git commit -m 'Add awesome feature'`)
4. Push la branche (`git push origin feature/awesome`)
5. Ouvrir une Pull Request
   - Review App sera déployée automatiquement
   - URL disponible dans les commentaires

---

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

---

## ⭐ Remerciements

- OpenWeatherMap pour l'API gratuite
- GitHub pour Actions et GHCR
- Helm pour le packaging Kubernetes
- La communauté Kubernetes

---

## 🎉 C'est Parti !

```bash
# Clone ce repo
git clone https://github.com/VOTRE-USERNAME/weather-app.git

# Suis le guide rapide
cat docs/QUICKSTART-GITHUB-ACTIONS.md

# En 5 minutes, ton app sera déployée ! 🚀
```

**Bon déploiement !** 🌤️
