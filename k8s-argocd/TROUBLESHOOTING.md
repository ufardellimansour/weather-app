# 🚨 Guide de Dépannage Argo CD

## Erreur : "application destination does not match allowed destinations"

### ❌ Symptôme
```
Unable to create application: application spec is invalid: 
InvalidSpecError: application destination server 'https://kubernetes.default.svc' 
and namespace 'XXX' do not match any of the allowed destinations in project 'YYY'
```

### ✅ Solutions

#### Solution 1 : Utiliser le Projet "default" (Le Plus Simple)

1. **Modifier les fichiers d'application** :
   ```yaml
   spec:
     project: default  # ⬅️ Au lieu de ton projet custom
   ```

2. **Appliquer** :
   ```bash
   kubectl apply -f argocd-preprod.yaml
   kubectl apply -f argocd-prod.yaml
   ```

#### Solution 2 : Configurer le Projet Custom

1. **Créer/Modifier le projet** (`argocd-project.yaml`) :
   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: AppProject
   metadata:
     name: weather-app
     namespace: argocd
   spec:
     destinations:
       - namespace: weather-preprod
         server: https://kubernetes.default.svc
       - namespace: weather-prod
         server: https://kubernetes.default.svc
       - namespace: '*'  # Wildcard (moins sécurisé)
         server: https://kubernetes.default.svc
   ```

2. **Appliquer le projet** :
   ```bash
   kubectl apply -f argocd-project.yaml
   ```

3. **Recréer les applications** :
   ```bash
   kubectl delete -f argocd-preprod.yaml
   kubectl apply -f argocd-preprod.yaml
   ```

#### Solution 3 : Via l'UI Argo CD

1. Supprime l'application qui échoue
2. Crée une nouvelle application
3. Dans **"Project"**, sélectionne **"default"**
4. Configure le reste normalement

---

## Erreur : "ImagePullBackOff"

### ❌ Symptôme
```bash
kubectl get pods -n weather-preprod
NAME                           READY   STATUS             RESTARTS   AGE
weather-app-xxx-yyy           0/1     ImagePullBackOff   0          2m
```

### ✅ Solutions

#### Vérifier l'Image

```bash
# Vérifier que l'image existe
docker pull ton-registry/weather-app:preprod

# Vérifier l'image configurée dans Kubernetes
kubectl get deployment weather-app -n weather-preprod -o yaml | grep image:
```

#### Registry Privé - Créer un Secret

```bash
# Docker Hub
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=ton-username \
  --docker-password=ton-password \
  --docker-email=ton-email@example.com \
  -n weather-preprod

# GCR
kubectl create secret docker-registry gcr-json-key \
  --docker-server=gcr.io \
  --docker-username=_json_key \
  --docker-password="$(cat ~/key.json)" \
  --docker-email=ton-email@example.com \
  -n weather-preprod
```

#### Ajouter le Secret au Deployment

Éditer `base/deployment.yaml` :
```yaml
spec:
  template:
    spec:
      imagePullSecrets:
        - name: regcred  # ⬅️ Nom du secret créé
      containers:
        - name: weather-app
```

---

## Erreur : "OutOfSync"

### ❌ Symptôme
L'application reste en statut "OutOfSync" dans Argo CD

### ✅ Solutions

```bash
# Voir les différences
argocd app diff weather-app-preprod

# Refresh l'état
argocd app get weather-app-preprod --refresh

# Sync avec force
argocd app sync weather-app-preprod --force --prune

# Hard refresh (si bloqué)
argocd app get weather-app-preprod --hard-refresh
```

---

## Erreur : Namespace n'Existe Pas

### ❌ Symptôme
```
namespace "weather-preprod" not found
```

### ✅ Solutions

#### Option 1 : Auto-création (dans Argo CD)

Ajouter dans `argocd-preprod.yaml` :
```yaml
spec:
  syncPolicy:
    syncOptions:
      - CreateNamespace=true  # ⬅️ Crée automatiquement le namespace
```

#### Option 2 : Création Manuelle

```bash
kubectl create namespace weather-preprod
kubectl create namespace weather-prod
```

---

## Erreur : Secret Not Found

### ❌ Symptôme
```
Error: secret "weather-app-secret" not found
```

### ✅ Solution

```bash
# Créer le secret
kubectl create secret generic weather-app-secret \
  --from-literal=OPENWEATHER_API_KEY="ta-cle-api" \
  -n weather-preprod

kubectl create secret generic weather-app-secret \
  --from-literal=OPENWEATHER_API_KEY="ta-cle-api" \
  -n weather-prod
```

**IMPORTANT** : Les secrets doivent être créés AVANT de synchroniser l'application.

---

## Erreur : "repository not found"

### ❌ Symptôme
```
rpc error: code = Unknown desc = error getting repository: 
repository not found
```

### ✅ Solutions

#### Repository Privé

1. **Via UI Argo CD** :
   - Settings → Repositories → Connect Repo
   - Ajouter les credentials

2. **Via CLI** :
   ```bash
   argocd repo add https://github.com/ton-username/weather-app.git \
     --username ton-username \
     --password ton-token
   ```

#### Repository Public

Vérifier que l'URL est correcte :
```yaml
repoURL: https://github.com/ton-username/weather-app.git  # Pas de .git à la fin parfois
```

---

## Erreur : "path does not exist"

### ❌ Symptôme
```
path 'k8s-argocd/overlays/preprod' does not exist in repository
```

### ✅ Solutions

1. **Vérifier que le chemin existe dans Git** :
   ```bash
   git ls-tree -r develop --name-only | grep k8s-argocd
   ```

2. **Vérifier la branche** :
   ```yaml
   spec:
     source:
       targetRevision: develop  # ⬅️ Bonne branche ?
       path: k8s-argocd/overlays/preprod  # ⬅️ Bon chemin ?
   ```

3. **Push le code si manquant** :
   ```bash
   git add k8s-argocd/
   git commit -m "Add Argo CD config"
   git push origin develop
   ```

---

## Commandes de Diagnostic

### Voir les Logs Argo CD

```bash
# Application Controller (gère les syncs)
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Server (API)
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Repo Server (accès Git)
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server
```

### Inspecter une Application

```bash
# Vue complète
argocd app get weather-app-preprod

# Voir les ressources
kubectl get application weather-app-preprod -n argocd -o yaml

# Voir les événements
kubectl get events -n weather-preprod --sort-by='.lastTimestamp'
```

### Tester Kustomize en Local

```bash
# Générer les manifests sans appliquer
kustomize build k8s-argocd/overlays/preprod

# Valider les manifests
kustomize build k8s-argocd/overlays/preprod | kubectl apply --dry-run=client -f -
```

---

## Workflow de Debug Complet

```bash
# 1. Vérifier l'état de l'application
argocd app get weather-app-preprod

# 2. Voir les différences
argocd app diff weather-app-preprod

# 3. Vérifier les logs des pods
kubectl logs -f -l app=weather-app -n weather-preprod

# 4. Vérifier les événements
kubectl get events -n weather-preprod --sort-by='.lastTimestamp' | tail -20

# 5. Décrire les ressources
kubectl describe deployment weather-app -n weather-preprod
kubectl describe pod -l app=weather-app -n weather-preprod

# 6. Forcer un refresh
argocd app get weather-app-preprod --refresh

# 7. Sync avec force si nécessaire
argocd app sync weather-app-preprod --force --prune
```

---

## Checklist de Vérification

Avant de créer une application Argo CD :

- [ ] ✅ Code poussé sur Git (bonne branche)
- [ ] ✅ Chemin `k8s-argocd/overlays/preprod` existe dans Git
- [ ] ✅ Image Docker poussée sur le registry
- [ ] ✅ Image configurée dans `kustomization.yaml`
- [ ] ✅ Secrets créés dans les namespaces
- [ ] ✅ Repository accessible par Argo CD
- [ ] ✅ Projet Argo CD configuré (ou utiliser "default")
- [ ] ✅ Namespace existe ou auto-création activée

---

## Reset Complet (Dernier Recours)

Si rien ne fonctionne :

```bash
# 1. Supprimer l'application
argocd app delete weather-app-preprod --cascade

# 2. Nettoyer le namespace
kubectl delete namespace weather-preprod

# 3. Recréer de zéro
kubectl create namespace weather-preprod

kubectl create secret generic weather-app-secret \
  --from-literal=OPENWEATHER_API_KEY="ta-cle" \
  -n weather-preprod

kubectl apply -f argocd-preprod.yaml

argocd app sync weather-app-preprod
```

---

## Support Supplémentaire

- Documentation Argo CD : https://argo-cd.readthedocs.io/
- Vérifier les logs : `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller`
- Forum Argo CD : https://github.com/argoproj/argo-cd/discussions
