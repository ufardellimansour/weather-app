# 🚀 Démarrage Rapide GitHub Actions (5 Minutes)

Guide ultra-rapide pour lancer ton premier workflow GitHub Actions.

## ⚡ Configuration Express

### 1. Pousser le Code sur GitHub

```bash
# Si pas encore fait
git init
git remote add origin https://github.com/VOTRE-USERNAME/weather-app.git
git add .
git commit -m "Initial commit with GitHub Actions"

# Créer et pousser develop
git checkout -b develop
git push -u origin develop

# Créer et pousser main
git checkout -b main
git push -u origin main
```

### 2. Configurer les Secrets (2 minutes)

Dans GitHub : **Settings → Secrets and variables → Actions → New repository secret**

#### KUBECONFIG (obligatoire)

```bash
# Sur ta machine
cat ~/.kube/config | base64 -w 0

# Copie le résultat
# Dans GitHub :
# - Name: KUBECONFIG
# - Secret: [colle ici]
```

#### OPENWEATHER_API_KEY_PREPROD (obligatoire)

```
# Dans GitHub :
# - Name: OPENWEATHER_API_KEY_PREPROD
# - Secret: ta-cle-api-openweathermap
```

### 3. Le Workflow se Lance Automatiquement !

1. Va sur GitHub : **Actions**
2. Tu verras "CI/CD Pipeline" en cours
3. Attends que le workflow se termine (5-10 min)
4. Vérifie que tous les jobs sont verts ✅

### 4. Accéder à l'Application

```bash
# Si Ingress activé
curl https://weather-preprod.ton-domaine.com

# Sinon, port-forward
kubectl port-forward service/weather-app-preprod 8080:80 -n weather-preprod
# Ouvre: http://localhost:8080
```

---

## 🎯 C'est Tout !

Ton workflow GitHub Actions est maintenant actif :

- ✅ **Build automatique** sur chaque push
- ✅ **Tests** de sécurité et qualité
- ✅ **Publish** vers GitHub Container Registry
- ✅ **Deploy automatique** en preprod (branche develop)
- ✅ **Deploy manuel** en production (branche main avec approbation)
- ✅ **Review apps** pour les Pull Requests

---

## 📊 Workflow Simplifié

```
Développement:
  git push origin develop
    ↓
  Workflow auto → Déploiement preprod ✅

Production:
  git push origin main
    ↓
  Workflow auto → Approbation requise → Production ✅

Pull Request:
  Créer une PR
    ↓
  Review app automatique → URL dans les commentaires ✅
```

---

## 🔧 Configuration Minimale vs Complète

### Tu viens de faire la config **MINIMALE** :

- ✅ KUBECONFIG
- ✅ OPENWEATHER_API_KEY_PREPROD
- ✅ Workflow fonctionnel

### Pour la **PRODUCTION** complète, ajoute :

- [ ] OPENWEATHER_API_KEY_PROD
- [ ] Environnement "production" avec protection rules
- [ ] Required reviewers (1-2 personnes)
- [ ] Domaines DNS configurés
- [ ] Certificats TLS (cert-manager)

📚 Voir [docs/GITHUB-ACTIONS-SETUP.md](GITHUB-ACTIONS-SETUP.md) pour la config complète.

---

## 🐛 Problèmes Fréquents

### Workflow ne démarre pas

**→ GitHub Actions désactivé**
- Settings → Actions → General → Allow all actions

### Erreur "kubectl: connection refused"

**→ KUBECONFIG invalide**
- Re-génère : `cat ~/.kube/config | base64 -w 0`
- Re-colle dans GitHub Secrets

### Image build failed

**→ Dockerfile introuvable**
- Vérifie que `Dockerfile` est à la racine
- Vérifie que tu as bien push le code

### Pods en CrashLoopBackOff

**→ Secret manquant**
```bash
kubectl create secret generic weather-app-preprod-secret \
  --from-literal=openweather-api-key="ta-cle" \
  -n weather-preprod
```

### Images GHCR privées

**→ Rendre publiques**
- Va sur https://github.com/users/TON-USERNAME/packages
- Sélectionne `weather-app`
- Package settings → Change visibility → Public

---

## 🎓 Prochaines Étapes

1. ✅ Workflow preprod qui fonctionne
2. [ ] Tester une Pull Request (Review App)
3. [ ] Configurer la production
4. [ ] Ajouter des tests automatisés
5. [ ] Monitoring et alertes

---

## 📦 Images Docker

Tes images sont publiées sur GitHub Container Registry :

```
ghcr.io/VOTRE-USERNAME/weather-app:develop
ghcr.io/VOTRE-USERNAME/weather-app:main
ghcr.io/VOTRE-USERNAME/weather-app:sha-abc123
```

Voir dans : **Packages** (sur ta page GitHub)

---

## 🌐 Environnements

Voir les déploiements dans : **Settings → Environments**

- **preprod** : Déployé automatiquement sur develop
- **production** : Approbation requise sur main
- **review-pr-X** : Créé automatiquement pour chaque PR

---

## 🔄 Workflow GitOps Complet

### Feature → Preprod

```bash
# 1. Créer une feature branch
git checkout develop
git checkout -b feature/awesome

# 2. Développer
# ... modifications ...

# 3. Créer une PR vers develop
git push origin feature/awesome
# → Review App déployée automatiquement

# 4. Merge la PR
# → Déploiement automatique en preprod
```

### Preprod → Production

```bash
# 1. Créer une PR de develop vers main
# 2. Review code
# 3. Merge la PR
# → Workflow déclenché
# → Approbation requise
# 4. Approver dans GitHub UI
# → Déploiement en production
```

---

## ✨ Fonctionnalités Disponibles

Ton workflow inclut :

✅ Build Docker avec cache  
✅ Security scan (Trivy + GitHub Security)  
✅ Code quality (flake8, pylint, black)  
✅ Tests unitaires (pytest)  
✅ Coverage reports (Codecov)  
✅ GitHub Container Registry  
✅ Déploiement Helm automatisé  
✅ Review apps automatiques  
✅ Comment PR avec URL  
✅ Cleanup automatique  
✅ Environments avec protection  
✅ Required approvals  
✅ Multi-environnements  

---

**Besoin d'aide ?** Consulte [GITHUB-ACTIONS-SETUP.md](GITHUB-ACTIONS-SETUP.md) pour le guide complet ! 📚

**Prêt à déployer !** 🎉
