# 🚀 Guide de Démarrage Rapide

Ce guide vous permet de lancer l'application météo en 5 minutes.

## Option 1 : Test Local avec Docker (le plus rapide)

### 1. Obtenir une clé API (gratuite)

1. Allez sur https://openweathermap.org/api
2. Créez un compte gratuit
3. Obtenez votre clé API (1000 appels/jour gratuits)

### 2. Lancer l'application

```bash
cd weather-app

# Construction
docker build -t weather-app:latest .

# Démarrage (remplacez YOUR_API_KEY)
docker run -d -p 5000:5000 \
  -e OPENWEATHER_API_KEY="YOUR_API_KEY" \
  weather-app:latest

# Ou avec docker-compose (éditez docker-compose.yaml d'abord)
docker-compose up -d
```

### 3. Accéder à l'application

Ouvrez votre navigateur : http://localhost:5000

### 4. Tester l'API

```bash
# Test de santé
curl http://localhost:5000/health

# Météo de Paris
curl http://localhost:5000/meteo/Paris
```

---

## Option 2 : Déploiement sur Kubernetes

### Prérequis

- Cluster Kubernetes fonctionnel (Minikube, K3s, GKE, EKS, AKS, etc.)
- `kubectl` configuré
- Image Docker disponible

### Déploiement rapide avec Minikube

```bash
# 1. Démarrer Minikube
minikube start

# 2. Construire l'image dans Minikube
eval $(minikube docker-env)
docker build -t weather-app:latest .

# 3. Configurer votre clé API
# Éditez k8s/secret.yaml et remplacez "demo" par votre vraie clé

# 4. Déployer
kubectl apply -f k8s/

# 5. Accéder à l'application
minikube service weather-app-service
```

### Déploiement automatisé

```bash
# Utiliser le script de déploiement
./deploy.sh

# Ou avec Make
make minikube-deploy
```

### Vérifier le déploiement

```bash
# Statut
kubectl get pods,svc

# Logs
kubectl logs -f -l app=weather-app

# Port-forward
kubectl port-forward service/weather-app-service 8080:80
# Puis : http://localhost:8080
```

---

## Option 3 : Déploiement avec Argo CD

### Si vous avez déjà Argo CD installé

```bash
# 1. Forkez le repo ou poussez-le sur votre Git

# 2. Éditez argocd-app.yaml
#    Remplacez l'URL du repo par la vôtre

# 3. Déployez l'application
kubectl apply -f argocd-app.yaml

# 4. Synchronisez
argocd app sync weather-app

# 5. Vérifiez
argocd app get weather-app
```

---

## 📝 Commandes Utiles

### Avec Make

```bash
make help          # Voir toutes les commandes
make build         # Construire l'image
make run           # Lancer localement
make test          # Tester l'application
make deploy        # Déployer sur K8s
make logs          # Voir les logs
make port-forward  # Créer un tunnel
make clean         # Nettoyer
```

### Avec Docker

```bash
# Construction
docker build -t weather-app:latest .

# Démarrage
docker run -d -p 5000:5000 \
  -e OPENWEATHER_API_KEY="YOUR_KEY" \
  weather-app:latest

# Logs
docker logs -f weather-app

# Arrêt
docker stop weather-app
docker rm weather-app
```

### Avec Kubernetes

```bash
# Déploiement
kubectl apply -f k8s/

# Statut
kubectl get all -l app=weather-app

# Logs
kubectl logs -f -l app=weather-app

# Port-forward
kubectl port-forward svc/weather-app-service 8080:80

# Scaling
kubectl scale deployment weather-app --replicas=3

# Nettoyage
kubectl delete -f k8s/
```

---

## 🔧 Configuration Minimale

### 1. Obtenir une clé API

**Gratuit** : https://openweathermap.org/api
- 1000 appels par jour
- Activation en quelques minutes

### 2. Configurer la clé

**Pour Docker :**
```bash
docker run -e OPENWEATHER_API_KEY="VOTRE_CLÉ" ...
```

**Pour Kubernetes :**
Éditez `k8s/secret.yaml` :
```yaml
stringData:
  OPENWEATHER_API_KEY: "VOTRE_CLÉ"
```

---

## 🐛 Problèmes Courants

### "demo API key" ne fonctionne pas
➡️ La clé "demo" est juste un placeholder. Obtenez une vraie clé sur openweathermap.org

### Les pods sont en "ImagePullBackOff"
➡️ Avec Minikube, utilisez : `eval $(minikube docker-env)` avant de build

### "Connection refused" à l'API
➡️ Vérifiez que votre clé API est valide et activée (peut prendre 10-15 minutes)

### Les pods ne démarrent pas
```bash
# Vérifier les logs
kubectl logs -l app=weather-app

# Vérifier les événements
kubectl get events --sort-by=.metadata.creationTimestamp
```

---

## 📚 Prochaines Étapes

1. ✅ Testez l'application localement
2. ✅ Déployez sur Kubernetes
3. 📖 Lisez le [README.md](README.md) complet
4. 🔧 Personnalisez l'application
5. 🚀 Configurez Argo CD pour le CI/CD

---

## 💡 Astuces

**Pour le développement :**
```bash
# Mode développement avec rechargement automatique
docker-compose up

# Ou sans Docker
pip install -r requirements.txt
export OPENWEATHER_API_KEY="YOUR_KEY"
python app.py
```

**Pour la production :**
- Utilisez un registry Docker (Docker Hub, GCR, ECR)
- Configurez un Ingress pour l'accès externe
- Activez l'autoscaling (HPA)
- Ajoutez de la surveillance (Prometheus, Grafana)

---

Besoin d'aide ? Consultez le [README.md](README.md) pour plus de détails !
