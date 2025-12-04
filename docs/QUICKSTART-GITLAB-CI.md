# 🚀 Démarrage Rapide GitLab CI/CD (5 Minutes)

Guide ultra-rapide pour lancer ton premier pipeline GitLab CI/CD.

## ⚡ Configuration Express

### 1. Pousser le Code sur GitLab

```bash
# Si pas encore fait
git init
git remote add origin https://gitlab.com/VOTRE-NAMESPACE/weather-app.git
git add .
git commit -m "Initial commit with CI/CD"
git push -u origin develop
```

### 2. Configurer les Variables (2 minutes)

Dans GitLab : **Settings → CI/CD → Variables**

Ajoute ces 2 variables MINIMUM :

#### KUBECONFIG_CONTENT

```bash
# Sur ta machine
cat ~/.kube/config | base64 -w 0

# Copie le résultat
# Dans GitLab :
# - Nom: KUBECONFIG_CONTENT
# - Valeur: [colle ici]
# - Type: Variable
# - Protected: ✅ Oui
# - Masked: ❌ Non
```

#### OPENWEATHER_API_KEY_PREPROD

```
# Dans GitLab :
# - Nom: OPENWEATHER_API_KEY_PREPROD
# - Valeur: ta-cle-api-openweathermap
# - Type: Variable
# - Protected: ✅ Oui
# - Masked: ✅ Oui
```

### 3. Modifier .gitlab-ci.yml

Édite `.gitlab-ci.yml` ligne 48-49 :

```yaml
# Avant
--set ingress.hosts[0].host=weather-preprod.example.com

# Après
--set ingress.hosts[0].host=weather-preprod.TON-DOMAINE.com
```

Ou désactive l'Ingress si pas de domaine :

```yaml
--set ingress.enabled=false
```

### 4. Premier Push

```bash
git add .
git commit -m "ci: configure pipeline"
git push origin develop
```

### 5. Vérifier le Pipeline

1. Va sur GitLab : **CI/CD → Pipelines**
2. Attends que le pipeline se termine (5-10 min)
3. Vérifie que tous les jobs sont verts ✅

### 6. Accéder à l'Application

```bash
# Si Ingress activé
curl https://weather-preprod.ton-domaine.com

# Sinon, port-forward
kubectl port-forward service/weather-app-preprod 8080:80 -n weather-preprod
# Ouvre: http://localhost:8080
```

---

## 🎯 C'est Tout !

Ton pipeline CI/CD est maintenant actif :

- ✅ **Build automatique** sur chaque push
- ✅ **Tests** de sécurité et qualité
- ✅ **Publish** vers GitLab Registry
- ✅ **Deploy automatique** en preprod (branche develop)
- ✅ **Deploy manuel** en production (branche main)

---

## 📊 Workflow Simplifié

```
Développement:
  git push origin develop
    ↓
  Pipeline auto → Déploiement preprod ✅

Production:
  git push origin main
    ↓
  Pipeline auto → Job manuel (cliquer "Play") → Production ✅
```

---

## 🔧 Configuration Minimale vs Complète

### Tu viens de faire la config **MINIMALE** :

- ✅ KUBECONFIG_CONTENT
- ✅ OPENWEATHER_API_KEY_PREPROD
- ✅ Ingress désactivé ou domaine configuré

### Pour la **PRODUCTION** complète, ajoute :

- [ ] OPENWEATHER_API_KEY_PROD
- [ ] Domaine production configuré
- [ ] Certificats TLS (cert-manager)
- [ ] Monitoring (Prometheus, Grafana)

📚 Voir [docs/GITLAB-CI-SETUP.md](GITLAB-CI-SETUP.md) pour la config complète.

---

## 🐛 Problèmes Fréquents

### Pipeline ne démarre pas

**→ Pas de runner disponible**
- Utilise les runners partagés GitLab.com
- Ou installe un runner : [Guide](https://docs.gitlab.com/runner/install/)

### Erreur "kubectl: connection refused"

**→ KUBECONFIG_CONTENT invalide**
- Re-génère : `cat ~/.kube/config | base64 -w 0`
- Re-colle dans GitLab

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

---

## 🎓 Prochaines Étapes

1. ✅ Pipeline preprod qui fonctionne
2. [ ] Tester une Merge Request (Review App)
3. [ ] Configurer la production
4. [ ] Ajouter des tests automatisés
5. [ ] Monitoring et alertes

---

**Besoin d'aide ?** Consulte [GITLAB-CI-SETUP.md](GITLAB-CI-SETUP.md) pour le guide complet ! 📚
