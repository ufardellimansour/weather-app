# 🚀 Guide de Configuration GitHub Actions

Guide complet pour configurer le pipeline CI/CD GitHub Actions pour l'application Weather App.

## 📋 Prérequis

- [x] Repository GitHub avec le code
- [x] Cluster Kubernetes accessible
- [x] Helm 3 installé
- [x] Clé API OpenWeatherMap
- [x] Compte GitHub avec accès au Container Registry

---

## 🔧 Configuration GitHub

### 1. Activer GitHub Actions

GitHub Actions est activé par défaut. Vérifie dans **Settings → Actions → General** :
- ✅ Allow all actions and reusable workflows

### 2. Configurer les Secrets

Allez dans **Settings → Secrets and variables → Actions** et cliquez sur **New repository secret**.

#### Secrets Obligatoires

| Secret | Description | Type |
|--------|-------------|------|
| `KUBECONFIG` | Kubeconfig en base64 | Secret |
| `OPENWEATHER_API_KEY_PREPROD` | Clé API preprod | Secret |
| `OPENWEATHER_API_KEY_PROD` | Clé API production | Secret |

### 3. Créer KUBECONFIG Secret

Sur votre machine avec accès kubectl :

```bash
# Encoder votre kubeconfig en base64
cat ~/.kube/config | base64 -w 0

# Ou sur macOS
cat ~/.kube/config | base64

# Copier la sortie et créer le secret dans GitHub
# Settings → Secrets and variables → Actions → New repository secret
# Name: KUBECONFIG
# Secret: [coller ici]
```

### 4. Créer les Secrets API

```
Name: OPENWEATHER_API_KEY_PREPROD
Secret: votre-cle-api-preprod

Name: OPENWEATHER_API_KEY_PROD
Secret: votre-cle-api-production
```

---

## 🐳 GitHub Container Registry (GHCR)

### Activation Automatique

Le Container Registry est activé automatiquement. Les images seront publiées sur :
```
ghcr.io/VOTRE-USERNAME/weather-app
```

### Visibilité des Images

Par défaut, les images sont **privées**. Pour les rendre publiques :

1. Allez sur https://github.com/users/VOTRE-USERNAME/packages
2. Sélectionnez votre package `weather-app`
3. **Package settings** → **Change visibility** → Public

### Authentification

Le workflow utilise `GITHUB_TOKEN` automatiquement (aucune configuration nécessaire).

---

## 🌿 Configuration des Branches

### Structure Recommandée

```
main (production)
  └── Déploiement manuel en production
  
develop (preprod)
  └── Déploiement automatique en preprod

feature/* (développement)
  └── Review apps automatiques (Pull Requests)
```

### Protection des Branches

**Settings → Branches → Add branch protection rule**

#### Pour `main` :
- [x] Require a pull request before merging
- [x] Require approvals (1-2)
- [x] Require status checks to pass
  - [x] build
  - [x] security-scan
  - [x] lint
  - [x] test
- [x] Require branches to be up to date

#### Pour `develop` :
- [x] Require status checks to pass
  - [x] build
  - [x] lint
  - [x] test

---

## 🎯 Environnements GitHub

### Créer les Environnements

**Settings → Environments → New environment**

#### Environment: `preprod`
- **Deployment branches** : `develop` uniquement
- **Environment secrets** : Aucun (utilise les secrets du repo)
- **Protection rules** : Aucune (déploiement auto)

#### Environment: `production`
- **Deployment branches** : `main` uniquement
- **Environment secrets** : Peut overrider les secrets si besoin
- **Protection rules** :
  - [x] Required reviewers (1-2 personnes)
  - [x] Wait timer: 5 minutes (optionnel)

#### Environment: `review-pr-*` (automatique)
- Créé automatiquement pour chaque PR
- Supprimé automatiquement à la fermeture de la PR

---

## 🔄 Workflow GitOps

### Développement → Preprod (Automatique)

```bash
# 1. Créer une branche
git checkout -b feature/ma-fonctionnalite

# 2. Développer
# ... modifications ...

# 3. Commit et push
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin feature/ma-fonctionnalite

# 4. Créer une Pull Request vers develop
# → Review App déployée automatiquement
# → URL commentée dans la PR

# 5. Merge la PR dans develop
# → Workflow déclenché automatiquement
# → Déploiement en preprod ✅
```

### Preprod → Production (Manuel avec Approbation)

```bash
# 1. Tests OK en preprod
# 2. Créer une PR de develop vers main
# 3. Review et approbation requise
# 4. Merge dans main

# 5. Workflow déclenché automatiquement
# 6. Job "deploy-production" attend approbation
# 7. Reviewer approuve dans GitHub UI
# 8. Déploiement en production ✅
```

### Release avec Tag

```bash
# Créer un tag
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0

# Le workflow build les images avec le tag v1.0.0
# Images disponibles sur ghcr.io/username/weather-app:v1.0.0
```

---

## 📊 Visualisation du Pipeline

### Actions Tab

Allez dans **Actions** pour voir :
- ✅ Workflows en cours et terminés
- ✅ Logs détaillés de chaque job
- ✅ Artefacts (si configurés)
- ✅ Temps d'exécution

### Environments Tab

Allez dans **Settings → Environments** pour voir :
- ✅ Historique des déploiements
- ✅ URLs des environnements
- ✅ Statut des environnements

### Packages Tab

Allez dans **Packages** pour voir :
- ✅ Images Docker publiées
- ✅ Tags disponibles
- ✅ Statistiques de téléchargement

---

## 🎨 Fonctionnalités du Workflow

### Build & Publish
- ✅ Build Docker multi-stage
- ✅ Cache Docker layers (GitHub Cache)
- ✅ Publish sur GitHub Container Registry
- ✅ Tags automatiques (branch, sha, semver)

### Tests
- ✅ Security scan (Trivy)
- ✅ Upload results vers GitHub Security
- ✅ Code quality (flake8, pylint, black)
- ✅ Unit tests (pytest)
- ✅ Coverage reports (Codecov)

### Déploiement
- ✅ Helm deploy automatisé
- ✅ Health checks Kubernetes
- ✅ Rollout verification
- ✅ Review apps automatiques
- ✅ Cleanup automatique des review apps

### Sécurité
- ✅ GITHUB_TOKEN automatique
- ✅ Secrets chiffrés
- ✅ Environment protection rules
- ✅ Required approvals
- ✅ SARIF upload vers GitHub Security

---

## 🔐 Sécurité des Secrets

### Bonnes Pratiques

1. **Secrets séparés par environnement**
   ```
   OPENWEATHER_API_KEY_PREPROD
   OPENWEATHER_API_KEY_PROD
   ```

2. **Rotation régulière**
   - Changer les secrets tous les 90 jours
   - Mettre à jour dans GitHub Secrets

3. **Accès limité**
   - Configurer les environment protection rules
   - Required reviewers pour production

4. **Audit**
   - Vérifier les logs dans Settings → Actions
   - Surveiller l'utilisation des secrets

---

## 🧪 Tester le Workflow

### 1. Premier Push

```bash
# Initialiser Git si pas déjà fait
git init
git add .
git commit -m "Initial commit with GitHub Actions"

# Ajouter le remote GitHub
git remote add origin https://github.com/VOTRE-USERNAME/weather-app.git

# Créer la branche develop
git checkout -b develop
git push -u origin develop
```

### 2. Vérifier dans GitHub

1. Allez dans **Actions**
2. Vous verrez le workflow "CI/CD Pipeline" en cours
3. Cliquez dessus pour voir les détails

### 3. Voir les Logs

Cliquez sur chaque job pour voir les logs détaillés.

### 4. Accéder à l'Application

```bash
# Une fois déployé
kubectl get pods -n weather-preprod

# Port-forward si pas d'Ingress
kubectl port-forward service/weather-app-preprod 8080:80 -n weather-preprod
# Ouvre: http://localhost:8080
```

---

## 🐛 Dépannage

### Workflow ne Démarre Pas

**Problème** : Le workflow n'apparaît pas dans Actions

**Solutions** :
1. Vérifier que le fichier est dans `.github/workflows/`
2. Vérifier la syntaxe YAML
3. GitHub Actions activé (Settings → Actions)

### Erreur "kubectl: connection refused"

**Problème** : KUBECONFIG invalide

**Solution** :
```bash
# Re-générer le kubeconfig en base64
cat ~/.kube/config | base64 -w 0

# Mettre à jour le secret dans GitHub
# Settings → Secrets and variables → Actions → KUBECONFIG
```

### Erreur "permission denied" sur GHCR

**Problème** : Pas de permission pour push sur GHCR

**Solutions** :
1. Vérifier que `packages: write` est dans les permissions du job
2. Le workflow utilise bien `GITHUB_TOKEN`
3. L'image est publique ou accessible

### Helm Install Failed

**Problème** : Chart invalide ou ressources manquantes

**Solution** :
```bash
# Valider le chart localement
helm lint ./helm/weather-app

# Test dry-run
helm install weather-app ./helm/weather-app --dry-run --debug

# Voir les erreurs Kubernetes
kubectl get events -n weather-preprod --sort-by='.lastTimestamp'
```

### Review App non Créée

**Problème** : PR créée mais pas de review app

**Solutions** :
1. Vérifier que la PR est vers `develop` ou `main`
2. Vérifier les logs du job `deploy-review`
3. Le secret KUBECONFIG est accessible

---

## 📈 Optimisations

### Cache Docker

Le workflow utilise déjà le cache GitHub Actions :
```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

### Jobs Conditionnels

Les jobs sont optimisés pour ne s'exécuter que si nécessaire :
- `deploy-preprod` : uniquement sur `develop`
- `deploy-production` : uniquement sur `main`
- `deploy-review` : uniquement sur Pull Requests

### Matrix Strategy (Optionnel)

Pour tester plusieurs versions :
```yaml
strategy:
  matrix:
    python-version: [3.9, 3.10, 3.11]
```

---

## 📊 Monitoring

### GitHub Actions Monitoring

**Settings → Actions → General → Workflow permissions**
- Activer "Read and write permissions"
- Activer "Allow GitHub Actions to create and approve pull requests"

### Notifications

**Settings → Notifications → Actions**
- Configurer les notifications par email
- Intégration Slack (via webhooks)

---

## 💰 Quotas et Limites

### GitHub Actions (Compte Gratuit)

- ✅ 2000 minutes/mois
- ✅ Illimité pour repos publics
- ✅ 500 MB storage

### GitHub Container Registry

- ✅ 500 MB storage gratuit
- ✅ 1 GB bandwidth/mois
- ✅ Illimité pour images publiques

### Optimisation des Minutes

1. Utiliser le cache Docker
2. Jobs conditionnels
3. Parallélisation des tests

---

## ✅ Checklist Complète

### Avant le Premier Déploiement

Configuration GitHub :
- [ ] Repository créé
- [ ] Code poussé sur GitHub
- [ ] Workflow dans `.github/workflows/`
- [ ] GitHub Actions activé
- [ ] Secrets configurés :
  - [ ] KUBECONFIG
  - [ ] OPENWEATHER_API_KEY_PREPROD
  - [ ] OPENWEATHER_API_KEY_PROD
- [ ] Environments créés (preprod, production)
- [ ] Branch protection rules configurées

Configuration Kubernetes :
- [ ] Cluster Kubernetes accessible
- [ ] kubectl configuré
- [ ] Helm 3 installé
- [ ] Namespaces peuvent être créés
- [ ] Ingress Controller (optionnel)

Configuration Application :
- [ ] Clé API OpenWeatherMap obtenue
- [ ] Domaines DNS configurés (optionnel)
- [ ] Images GHCR accessibles

### Après Configuration

- [ ] Premier workflow exécuté avec succès
- [ ] Images publiées sur GHCR
- [ ] Application déployée en preprod
- [ ] Tests fonctionnels OK
- [ ] Review app testée (créer une PR)
- [ ] Déploiement production testé

---

## 🎯 Prochaines Étapes

1. ✅ Configuration GitHub Actions
2. [ ] Premier workflow réussi
3. [ ] Application en preprod accessible
4. [ ] Tests automatisés ajoutés
5. [ ] Configuration production
6. [ ] Monitoring (Prometheus/Grafana)
7. [ ] Alerting (Slack/PagerDuty)
8. [ ] Backup et disaster recovery

---

## 📚 Ressources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

**Prêt à déployer !** 🚀

Chaque push sur `develop` déploie en preprod automatiquement.
Pour la production, merge dans `main` et approuve le déploiement.
