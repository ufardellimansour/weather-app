# 🔄 GitHub Actions vs GitLab CI/CD - Comparaison

Ce document compare GitHub Actions et GitLab CI/CD pour l'application Weather App.

## 📊 Tableau Comparatif Rapide

| Aspect | GitHub Actions | GitLab CI/CD |
|--------|----------------|--------------|
| **Fichier config** | `.github/workflows/*.yml` | `.gitlab-ci.yml` |
| **Triggers** | `on:` events | `only:` branches |
| **Jobs** | `jobs:` | `stages:` + jobs |
| **Container Registry** | GHCR (ghcr.io) | GitLab Registry |
| **Secrets** | GitHub Secrets | GitLab Variables |
| **Environments** | GitHub Environments | GitLab Environments |
| **Review Apps** | Manual setup | Built-in |
| **Minutes gratuites** | 2000/mois (public: ∞) | 400/mois |
| **Storage** | 500 MB | Inclus |
| **Security scan** | GitHub Security tab | GitLab Security Dashboard |

---

## 🎯 Syntaxe Côte à Côte

### Triggers

**GitHub Actions:**
```yaml
on:
  push:
    branches:
      - develop
      - main
  pull_request:
    branches:
      - develop
```

**GitLab CI/CD:**
```yaml
only:
  - develop
  - main
```

### Jobs

**GitHub Actions:**
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: docker build .
```

**GitLab CI/CD:**
```yaml
stages:
  - build

build:
  stage: build
  image: docker:latest
  script:
    - docker build .
```

### Secrets

**GitHub Actions:**
```yaml
env:
  API_KEY: ${{ secrets.API_KEY }}
```

**GitLab CI/CD:**
```yaml
script:
  - echo $API_KEY  # Variable CI/CD
```

---

## 🐳 Container Registry

### GitHub Container Registry (GHCR)

**URL des images:**
```
ghcr.io/username/repo-name:tag
```

**Authentication:**
- Automatique avec `GITHUB_TOKEN`
- Pas de configuration

**Visibilité:**
- Privé par défaut
- Peut être rendu public

### GitLab Container Registry

**URL des images:**
```
registry.gitlab.com/namespace/project/image:tag
```

**Authentication:**
- Automatique avec `CI_REGISTRY_PASSWORD`
- Pas de configuration

**Visibilité:**
- Suit la visibilité du repo

---

## 🔐 Gestion des Secrets

### GitHub

**Configuration:**
1. Settings → Secrets and variables → Actions
2. New repository secret
3. Name + Secret

**Dans le workflow:**
```yaml
env:
  MY_SECRET: ${{ secrets.MY_SECRET }}
```

**Environment secrets:**
- Secrets spécifiques par environnement
- Override des secrets du repo

### GitLab

**Configuration:**
1. Settings → CI/CD → Variables
2. Add variable
3. Key + Value + Options

**Dans le pipeline:**
```yaml
script:
  - echo $MY_SECRET
```

**Options:**
- Protected (branches protégées)
- Masked (caché dans les logs)

---

## 🌐 Environnements

### GitHub Environments

**Création:**
- Settings → Environments → New environment

**Features:**
- Required reviewers (1-6)
- Wait timer
- Branch restrictions
- Environment secrets
- Deployment history

**Dans le workflow:**
```yaml
environment:
  name: production
  url: https://example.com
```

### GitLab Environments

**Création:**
- Automatique à la première utilisation

**Features:**
- Manual actions
- Auto stop
- Protected environments
- Deployment history

**Dans le pipeline:**
```yaml
environment:
  name: production
  url: https://example.com
  on_stop: stop_production
```

---

## 🔄 Review Apps

### GitHub Actions

**Nécessite configuration manuelle:**

```yaml
deploy-review:
  if: github.event_name == 'pull_request'
  steps:
    - name: Deploy
      run: |
        helm install review-pr-${{ github.event.pull_request.number }}
    - name: Comment PR
      uses: actions/github-script@v7
```

**Cleanup:**
```yaml
cleanup-review:
  if: github.event.action == 'closed'
```

### GitLab CI/CD

**Built-in:**

```yaml
deploy:review:
  environment:
    name: review/$CI_COMMIT_REF_NAME
    on_stop: stop_review
    auto_stop_in: 1 week
  only:
    - merge_requests
```

**Cleanup automatique** avec `on_stop` et `auto_stop_in`.

---

## 📊 Visualisation

### GitHub

**Actions Tab:**
- ✅ Workflows list
- ✅ Logs colorés
- ✅ Job graphs
- ✅ Re-run jobs

**Security Tab:**
- ✅ Trivy results (SARIF)
- ✅ Dependabot
- ✅ Code scanning

**Packages Tab:**
- ✅ Container images
- ✅ Download stats

### GitLab

**CI/CD → Pipelines:**
- ✅ Pipeline list
- ✅ DAG visualization
- ✅ Job artifacts
- ✅ Retry jobs

**Security Dashboard:**
- ✅ Vulnerability reports
- ✅ Dependency scanning
- ✅ SAST/DAST

**Packages & Registries:**
- ✅ Container registry
- ✅ Package registry

---

## 💰 Coûts

### GitHub (Compte Gratuit)

**Actions:**
- ✅ 2000 minutes/mois
- ✅ **Illimité pour repos publics**
- ✅ 500 MB storage

**Container Registry:**
- ✅ 500 MB storage
- ✅ 1 GB bandwidth/mois
- ✅ **Illimité pour packages publics**

### GitLab (Compte Gratuit)

**CI/CD:**
- ✅ 400 minutes/mois
- ✅ Runners partagés
- ✅ Storage inclus

**Container Registry:**
- ✅ 10 GB storage
- ✅ Bandwidth illimité

---

## 🚀 Points Forts

### GitHub Actions

✅ **Intégration GitHub native**
- Actions marketplace (milliers d'actions)
- GitHub Security intégré
- Dependabot natif
- Discussions et issues

✅ **Simplicité**
- Workflow YAML simple
- Bonne documentation
- Communauté active

✅ **Gratuité pour projets publics**
- Minutes illimitées
- Storage illimité

### GitLab CI/CD

✅ **Tout-en-un**
- Git + CI/CD + Registry dans un outil
- GitOps natif
- Auto DevOps

✅ **Review Apps natives**
- Configuration simple
- Cleanup automatique
- Preview URL automatique

✅ **DAG Visualization**
- Visualisation des dépendances
- Meilleure compréhension du pipeline

---

## ⚠️ Limitations

### GitHub Actions

❌ Review Apps nécessitent configuration manuelle
❌ Moins de minutes gratuites (sauf public)
❌ Pas de DAG visualization native
❌ Secrets management moins flexible

### GitLab CI/CD

❌ Marketplace d'actions moins fourni
❌ Interface parfois complexe
❌ Moins de minutes gratuites
❌ Communauté plus petite

---

## 🎯 Quel Outil Choisir ?

### Choisis GitHub Actions Si :

✅ Tu héberges déjà sur GitHub
✅ Projet open source (minutes illimitées)
✅ Tu veux simplicité et intégration native
✅ Marketplace d'actions important pour toi
✅ GitHub Security est un plus

### Choisis GitLab CI/CD Si :

✅ Tu héberges déjà sur GitLab
✅ Review Apps critiques pour ton workflow
✅ Tu veux un outil tout-en-un
✅ DAG visualization important
✅ Plus de storage registry nécessaire

---

## 🔄 Migration

### GitLab → GitHub

**Ce qui change:**
- `.gitlab-ci.yml` → `.github/workflows/*.yml`
- `CI_*` variables → `GITHUB_*` variables
- `registry.gitlab.com` → `ghcr.io`

**Migration Weather App:**
1. Copier le code
2. Remplacer `.gitlab-ci.yml` par `.github/workflows/ci-cd.yml`
3. Configurer GitHub Secrets
4. Mettre à jour les références registry

### GitHub → GitLab

**Ce qui change:**
- `.github/workflows/*.yml` → `.gitlab-ci.yml`
- `${{ }}` → `$` variables
- `ghcr.io` → `registry.gitlab.com`

**Migration Weather App:**
1. Copier le code
2. Créer `.gitlab-ci.yml`
3. Configurer GitLab Variables
4. Mettre à jour les références registry

---

## 🎓 Complexité d'Apprentissage

### GitHub Actions

**Difficulté:** ⭐⭐☆☆☆ (Facile-Moyen)

**Temps d'apprentissage:** 1-2 jours
- Syntaxe YAML intuitive
- Documentation claire
- Exemples nombreux

### GitLab CI/CD

**Difficulté:** ⭐⭐⭐☆☆ (Moyen)

**Temps d'apprentissage:** 2-4 jours
- Plus de concepts (stages, etc.)
- Documentation complète mais dense
- Moins d'exemples communautaires

---

## 📚 Ressources

### GitHub Actions
- [Documentation officielle](https://docs.github.com/en/actions)
- [Actions Marketplace](https://github.com/marketplace?type=actions)
- [Awesome Actions](https://github.com/sdras/awesome-actions)

### GitLab CI/CD
- [Documentation officielle](https://docs.gitlab.com/ee/ci/)
- [CI/CD Examples](https://docs.gitlab.com/ee/ci/examples/)
- [GitLab CI Templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)

---

## ✅ Conclusion

**Pour ce projet (Weather App) :**

Avec **GitHub**, tu as :
- ✅ Workflow fonctionnel immédiat
- ✅ Configuration simple (2 secrets)
- ✅ GHCR intégré automatiquement
- ✅ Security scanning natif
- ✅ Minutes gratuites suffisantes

**Notre recommandation :** Utilise l'outil où ton code est hébergé.
- Code sur GitHub → GitHub Actions ✅
- Code sur GitLab → GitLab CI/CD ✅

Les deux solutions sont excellentes et fonctionnelles pour cette application ! 🎉
