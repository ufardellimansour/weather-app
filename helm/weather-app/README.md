# Weather App Helm Chart

Chart Helm pour déployer l'application météo sur Kubernetes.

## Installation

### Avec les valeurs par défaut

```bash
helm install weather-app ./helm/weather-app
```

### Avec des valeurs spécifiques

```bash
# Preprod
helm install weather-app-preprod ./helm/weather-app \
  --namespace weather-preprod \
  --create-namespace \
  --values ./helm/weather-app/values-preprod.yaml

# Production
helm install weather-app-prod ./helm/weather-app \
  --namespace weather-prod \
  --create-namespace \
  --values ./helm/weather-app/values-prod.yaml
```

### Override des valeurs via CLI

```bash
helm install weather-app ./helm/weather-app \
  --set image.tag=v1.2.3 \
  --set replicaCount=5 \
  --set ingress.hosts[0].host=myapp.example.com
```

## Mise à Jour

```bash
helm upgrade weather-app ./helm/weather-app \
  --namespace weather-preprod \
  --values ./helm/weather-app/values-preprod.yaml
```

## Désinstallation

```bash
helm uninstall weather-app --namespace weather-preprod
```

## Configuration

### Paramètres Principaux

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `replicaCount` | Nombre de réplicas | `2` |
| `environment` | Environnement (dev, preprod, prod) | `production` |
| `image.repository` | Repository de l'image Docker | `registry.gitlab.com/...` |
| `image.tag` | Tag de l'image | `latest` |
| `image.pullPolicy` | Pull policy | `IfNotPresent` |
| `resources.limits.cpu` | Limite CPU | `500m` |
| `resources.limits.memory` | Limite RAM | `512Mi` |
| `resources.requests.cpu` | Request CPU | `100m` |
| `resources.requests.memory` | Request RAM | `128Mi` |
| `autoscaling.enabled` | Activer l'autoscaling | `false` |
| `autoscaling.minReplicas` | Min replicas HPA | `2` |
| `autoscaling.maxReplicas` | Max replicas HPA | `10` |
| `ingress.enabled` | Activer l'Ingress | `true` |
| `ingress.hosts[0].host` | Hostname | `weather.example.com` |

### Secrets

Par défaut, le chart crée un Secret avec la clé API. En production, il est recommandé d'utiliser un secret existant :

```yaml
secrets:
  existingSecret: "weather-app-secret"
```

Créer le secret manuellement :

```bash
kubectl create secret generic weather-app-secret \
  --from-literal=openweather-api-key="VOTRE_CLE_API" \
  -n weather-prod
```

## Exemples d'Usage

### Développement Local avec Minikube

```bash
# Installer
helm install weather-app ./helm/weather-app \
  --set image.repository=weather-app \
  --set image.tag=latest \
  --set image.pullPolicy=IfNotPresent \
  --set ingress.enabled=false

# Port-forward
kubectl port-forward service/weather-app 8080:80
```

### CI/CD avec GitLab

Le pipeline GitLab CI/CD déploie automatiquement avec Helm :

```yaml
deploy:
  script:
    - helm upgrade --install weather-app ./helm/weather-app
        --set image.tag=$CI_COMMIT_SHORT_SHA
```

### Avec Argo CD

Créer une Application Argo CD pointant vers le chart :

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: weather-app
spec:
  source:
    repoURL: https://gitlab.com/votre-namespace/weather-app
    path: helm/weather-app
    helm:
      valueFiles:
        - values-prod.yaml
```

## Validation

```bash
# Valider la syntaxe
helm lint ./helm/weather-app

# Générer les manifests sans installer
helm template weather-app ./helm/weather-app

# Dry-run
helm install weather-app ./helm/weather-app --dry-run --debug
```

## Dépannage

### Voir les valeurs effectives

```bash
helm get values weather-app --namespace weather-preprod
```

### Voir les manifests déployés

```bash
helm get manifest weather-app --namespace weather-preprod
```

### Rollback

```bash
# Voir l'historique
helm history weather-app --namespace weather-preprod

# Rollback vers une version précédente
helm rollback weather-app 1 --namespace weather-preprod
```

## Structure

```
helm/weather-app/
├── Chart.yaml              # Métadonnées du chart
├── values.yaml             # Valeurs par défaut
├── values-preprod.yaml     # Valeurs preprod
├── values-prod.yaml        # Valeurs production
└── templates/              # Templates Kubernetes
    ├── _helpers.tpl        # Fonctions helper
    ├── deployment.yaml     # Deployment
    ├── service.yaml        # Service
    ├── ingress.yaml        # Ingress
    ├── configmap.yaml      # ConfigMap
    ├── secret.yaml         # Secret
    ├── serviceaccount.yaml # ServiceAccount
    ├── hpa.yaml            # HorizontalPodAutoscaler
    └── pdb.yaml            # PodDisruptionBudget
```
