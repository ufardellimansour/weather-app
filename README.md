# 🌤️ Application Météo France - Kubernetes

Application Flask Python qui affiche la météo des principales villes de France, déployable sur Kubernetes.

## 📋 Fonctionnalités

- ✅ Affichage de la météo pour 20 villes françaises
- ✅ Interface web responsive et moderne
- ✅ API REST pour récupérer les données météo
- ✅ Containerisée avec Docker
- ✅ Prête pour Kubernetes avec health checks
- ✅ Support Argo CD

## 🏗️ Architecture

```
weather-app/
├── app.py                      # Application Flask principale
├── requirements.txt            # Dépendances Python
├── Dockerfile                  # Image Docker
├── templates/
│   └── index.html             # Interface web
├── static/
│   └── css/
│       └── style.css          # Styles CSS
└── k8s/                       # Manifests Kubernetes
    ├── configmap.yaml         # Configuration
    ├── secret.yaml            # Clé API
    ├── deployment.yaml        # Déploiement
    ├── service.yaml           # Service
    ├── ingress.yaml           # Ingress (optionnel)
    └── kustomization.yaml     # Kustomize
```

## 🚀 Déploiement

### Prérequis

1. **Clé API OpenWeatherMap** (gratuite)
   - Créez un compte sur https://openweathermap.org/api
   - Obtenez votre clé API (1000 appels/jour gratuits)

2. **Outils nécessaires**
   - Docker
   - kubectl
   - Cluster Kubernetes

### Étape 1 : Construire l'image Docker

```bash
cd weather-app

# Construction de l'image
docker build -t weather-app:latest .

# Test local (optionnel)
docker run -d -p 5000:5000 \
  -e OPENWEATHER_API_KEY="votre_clé_api" \
  weather-app:latest

# Accès: http://localhost:5000
```

### Étape 2 : Pousser l'image vers un registry

```bash
# Option 1: Docker Hub
docker tag weather-app:latest votre-username/weather-app:latest
docker push votre-username/weather-app:latest

# Option 2: Registry privé
docker tag weather-app:latest registry.example.com/weather-app:latest
docker push registry.example.com/weather-app:latest

# Option 3: Minikube (pour tests locaux)
eval $(minikube docker-env)
docker build -t weather-app:latest .
```

### Étape 3 : Configurer la clé API

Éditez `k8s/secret.yaml` et remplacez `demo` par votre vraie clé API:

```yaml
stringData:
  OPENWEATHER_API_KEY: "VOTRE_VRAIE_CLÉ_API"
```

### Étape 4 : Modifier l'image dans le deployment

Éditez `k8s/deployment.yaml` et mettez à jour l'image:

```yaml
spec:
  containers:
  - name: weather-app
    image: votre-username/weather-app:latest  # Votre image
```

### Étape 5 : Déployer sur Kubernetes

```bash
# Déploiement avec kubectl
kubectl apply -f k8s/

# OU avec kustomize
kubectl apply -k k8s/

# Vérifier le déploiement
kubectl get pods
kubectl get services
kubectl get ingress
```

### Étape 6 : Accéder à l'application

**Option A : Port-forward (test rapide)**
```bash
kubectl port-forward service/weather-app-service 8080:80
# Accès: http://localhost:8080
```

**Option B : NodePort**
```bash
# Modifier le service en NodePort
kubectl patch service weather-app-service -p '{"spec":{"type":"NodePort"}}'
kubectl get service weather-app-service

# Pour Minikube
minikube service weather-app-service
```

**Option C : LoadBalancer (cloud providers)**
```bash
kubectl patch service weather-app-service -p '{"spec":{"type":"LoadBalancer"}}'
kubectl get service weather-app-service
# Attendre l'IP externe
```

**Option D : Ingress (production)**
```bash
# Configurer votre domaine dans k8s/ingress.yaml
# Installer un ingress controller (nginx, traefik, etc.)
kubectl apply -f k8s/ingress.yaml
```

## 🔄 Déploiement avec Argo CD

### Méthode 1 : Application Argo CD

Créez un fichier `argocd-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: weather-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/votre-username/weather-app.git
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Appliquez:
```bash
kubectl apply -f argocd-app.yaml
```

### Méthode 2 : CLI Argo CD

```bash
argocd app create weather-app \
  --repo https://github.com/votre-username/weather-app.git \
  --path k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated \
  --auto-prune \
  --self-heal

argocd app sync weather-app
```

## 📊 Monitoring

### Vérifier la santé de l'application

```bash
# Logs des pods
kubectl logs -l app=weather-app -f

# Statut des pods
kubectl get pods -l app=weather-app

# Description du deployment
kubectl describe deployment weather-app

# Événements
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Endpoints de santé

- **Health check**: `GET /health`
- **Readiness check**: `GET /ready`
- **API météo**: `GET /meteo/{ville}`

### Tests de charge

```bash
# Test avec curl
for i in {1..10}; do
  curl http://localhost:8080/meteo/Paris
done

# Test de santé
curl http://localhost:8080/health
```

## 🔧 Configuration

### Variables d'environnement

| Variable | Description | Défaut |
|----------|-------------|--------|
| `OPENWEATHER_API_KEY` | Clé API OpenWeatherMap | `demo` |
| `PORT` | Port de l'application | `5000` |

### Ressources Kubernetes

- **Requests**: 100m CPU, 128Mi RAM
- **Limits**: 500m CPU, 256Mi RAM
- **Replicas**: 2 (haute disponibilité)

## 🛠️ Personnalisation

### Ajouter des villes

Éditez `app.py` et modifiez la liste `VILLES_FRANCE`:

```python
VILLES_FRANCE = [
    "Paris", "Marseille", "Lyon", "Toulouse",
    "Votre-Ville-Ici"
]
```

### Changer le namespace

```bash
# Dans tous les fichiers k8s/*.yaml, remplacez:
namespace: default
# par:
namespace: votre-namespace

# Créez le namespace
kubectl create namespace votre-namespace
```

### Scaling

```bash
# Scaler manuellement
kubectl scale deployment weather-app --replicas=5

# Autoscaling (HPA)
kubectl autoscale deployment weather-app \
  --cpu-percent=70 \
  --min=2 \
  --max=10
```

## 🐛 Dépannage

### L'application ne démarre pas

```bash
# Vérifier les logs
kubectl logs -l app=weather-app --tail=100

# Vérifier les secrets
kubectl get secret weather-app-secret -o yaml

# Vérifier la configuration
kubectl describe configmap weather-app-config
```

### Erreur "API key invalid"

1. Vérifiez que votre clé API est valide sur openweathermap.org
2. Mettez à jour le secret:
   ```bash
   kubectl delete secret weather-app-secret
   # Éditez k8s/secret.yaml avec la bonne clé
   kubectl apply -f k8s/secret.yaml
   kubectl rollout restart deployment weather-app
   ```

### Les pods sont en "ImagePullBackOff"

```bash
# Vérifier que l'image existe
docker images | grep weather-app

# Pousser l'image vers le registry
docker push votre-username/weather-app:latest

# Pour Minikube, reconstruire avec le bon context
eval $(minikube docker-env)
docker build -t weather-app:latest .
```

## 📝 API Documentation

### GET /
Interface web principale

### GET /meteo/{ville}
Récupère la météo pour une ville

**Réponse:**
```json
{
  "ville": "Paris",
  "temperature": 15.5,
  "ressenti": 14.2,
  "description": "Ciel dégagé",
  "humidite": 65,
  "vent": 12.5,
  "icon": "01d",
  "timestamp": "14:30:25"
}
```

## 📦 Technologies utilisées

- **Backend**: Python 3.11, Flask, Gunicorn
- **Frontend**: HTML5, CSS3, JavaScript vanilla
- **API**: OpenWeatherMap API
- **Container**: Docker
- **Orchestration**: Kubernetes
- **CI/CD**: Compatible Argo CD

## 🤝 Support

Pour obtenir de l'aide:
1. Vérifiez les logs: `kubectl logs -l app=weather-app`
2. Consultez la documentation OpenWeatherMap
3. Vérifiez votre configuration Kubernetes

## 📄 Licence

Ce projet est fourni à titre éducatif et de démonstration.

---

**Note**: N'oubliez pas de remplacer `demo` par votre vraie clé API OpenWeatherMap dans `k8s/secret.yaml` !
