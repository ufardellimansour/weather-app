# 🏗️ Architecture Weather App - Multi-Environnements

## Vue d'Ensemble

```
┌─────────────────────────────────────────────────────────────────┐
│                         Git Repository                          │
│  ┌──────────────────────┐      ┌──────────────────────┐        │
│  │   Branch: develop    │      │    Branch: main      │        │
│  │  (Preprod source)    │      │  (Production source) │        │
│  └──────────────────────┘      └──────────────────────┘        │
└─────────────────────────────────────────────────────────────────┘
                 │                            │
                 │ Auto-sync (3min)           │ Manual sync
                 ▼                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Argo CD                                │
│  ┌────────────────────┐      ┌─────────────────────┐           │
│  │ weather-app-preprod│      │ weather-app-prod    │           │
│  │  Auto Sync: ON     │      │  Auto Sync: OFF     │           │
│  └────────────────────┘      └─────────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
                 │                            │
                 ▼                            ▼
┌─────────────────────────────┐  ┌─────────────────────────────┐
│  Namespace: weather-preprod │  │   Namespace: weather-prod   │
│  ┌─────────────────────┐    │  │  ┌─────────────────────┐   │
│  │   Deployment        │    │  │  │   Deployment        │   │
│  │   Replicas: 1       │    │  │  │   Replicas: 3-10    │   │
│  │   CPU: 50m-200m     │    │  │  │   CPU: 200m-1000m   │   │
│  │   RAM: 64Mi-128Mi   │    │  │  │   RAM: 256Mi-512Mi  │   │
│  └─────────────────────┘    │  │  └─────────────────────┘   │
│  ┌─────────────────────┐    │  │  ┌─────────────────────┐   │
│  │   Service           │    │  │  │   Service           │   │
│  │   ClusterIP:80      │    │  │  │   ClusterIP:80      │   │
│  └─────────────────────┘    │  │  └─────────────────────┘   │
│  ┌─────────────────────┐    │  │  ┌─────────────────────┐   │
│  │   Ingress           │    │  │  │   Ingress           │   │
│  │   preprod.domain    │    │  │  │   weather.domain    │   │
│  │   TLS: Staging      │    │  │  │   TLS: Production   │   │
│  └─────────────────────┘    │  │  └─────────────────────┘   │
│                              │  │  ┌─────────────────────┐   │
│                              │  │  │   HPA               │   │
│                              │  │  │   3-10 pods         │   │
│                              │  │  └─────────────────────┘   │
│                              │  │  ┌─────────────────────┐   │
│                              │  │  │   PDB               │   │
│                              │  │  │   minAvailable: 2   │   │
│                              │  │  └─────────────────────┘   │
└─────────────────────────────┘  └─────────────────────────────┘
```

## Structure des Fichiers

```
weather-app/
│
├── app.py                           # Application Flask
├── requirements.txt                 # Dépendances Python
├── Dockerfile                       # Image Docker
├── docker-compose.yaml              # Test local
│
├── templates/
│   └── index.html                   # Interface web
│
├── static/
│   └── css/
│       └── style.css                # Styles
│
├── k8s/                             # Déploiement simple (legacy)
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
│
└── k8s-argocd/                      # Multi-environnements GitOps
    │
    ├── base/                        # Ressources communes
    │   ├── configmap.yaml           #   Config de base
    │   ├── secret.yaml              #   Secret template
    │   ├── deployment.yaml          #   Deployment de base
    │   ├── service.yaml             #   Service
    │   └── kustomization.yaml       #   Kustomize base
    │
    ├── overlays/
    │   ├── preprod/                 # Configuration preprod
    │   │   ├── namespace.yaml       #   NS: weather-preprod
    │   │   ├── configmap.yaml       #   Env: preprod
    │   │   ├── deployment-patch.yaml#   1 replica, 50m CPU
    │   │   ├── ingress.yaml         #   preprod.domain
    │   │   └── kustomization.yaml   #   Overlay preprod
    │   │
    │   └── prod/                    # Configuration production
    │       ├── namespace.yaml       #   NS: weather-prod
    │       ├── configmap.yaml       #   Env: production
    │       ├── deployment-patch.yaml#   3 replicas, 200m CPU
    │       ├── ingress.yaml         #   weather.domain
    │       ├── hpa.yaml             #   Autoscaling 3-10
    │       ├── pdb.yaml             #   HA protection
    │       └── kustomization.yaml   #   Overlay prod
    │
    ├── argocd-preprod.yaml          # App Argo CD preprod
    ├── argocd-prod.yaml             # App Argo CD prod
    │
    ├── Makefile                     # Commandes simplifiées
    ├── README.md                    # Documentation complète
    ├── QUICKSTART-ARGOCD.md         # Guide rapide
    └── ENVIRONMENTS-COMPARISON.md   # Comparaison envs
```

## Flux de Données

### Requête Utilisateur

```
┌─────────────┐
│  Utilisateur│
└──────┬──────┘
       │
       │ HTTPS
       ▼
┌─────────────────┐
│  Ingress        │  weather-preprod.example.com
│  (Nginx/Traefik)│  weather.example.com
└────────┬────────┘
         │
         │ HTTP
         ▼
┌─────────────────┐
│  Service        │  ClusterIP:80
│  weather-app-svc│
└────────┬────────┘
         │
         │ Load Balance
         ▼
┌─────────────────────────────────┐
│         Pods (1-10)             │
│  ┌──────┐ ┌──────┐ ┌──────┐    │
│  │Flask │ │Flask │ │Flask │    │
│  │:5000 │ │:5000 │ │:5000 │    │
│  └──┬───┘ └──┬───┘ └──┬───┘    │
│     │        │        │         │
└─────┼────────┼────────┼─────────┘
      │        │        │
      │ API Call
      ▼
┌─────────────────┐
│ OpenWeatherMap  │
│     API         │
└─────────────────┘
```

## Workflow GitOps Complet

### 1. Développement Local

```
Developer Machine
  │
  ├─ Code changes
  ├─ docker build -t weather-app:preprod
  ├─ docker run (test local)
  │
  └─ git add . && git commit
```

### 2. Push vers Preprod

```
git push origin develop
  │
  ├─ GitHub/GitLab receives push
  │
  ├─ CI/CD Pipeline (optional)
  │   ├─ docker build
  │   ├─ docker push registry/weather-app:preprod
  │   └─ tests
  │
  ├─ Argo CD detects change (3min poll)
  │
  ├─ Auto-sync triggered
  │   ├─ kustomize build overlays/preprod
  │   ├─ kubectl apply
  │   └─ rolling update
  │
  └─ Deployment in weather-preprod namespace
      └─ Tests & Validation
```

### 3. Promotion vers Production

```
Tests OK in preprod
  │
  ├─ git checkout main
  ├─ git merge develop
  ├─ git push origin main
  │
  ├─ CI/CD Pipeline
  │   ├─ docker build
  │   └─ docker push registry/weather-app:latest
  │
  ├─ Argo CD detects change
  │   └─ Status: OutOfSync
  │
  ├─ Manual review required
  │   ├─ argocd app diff weather-app-prod
  │   ├─ Team approval
  │   └─ argocd app sync weather-app-prod
  │
  └─ Rolling update in weather-prod
      ├─ Zero downtime (maxUnavailable: 0)
      ├─ PDB enforced (min 2 pods)
      └─ Health checks validated
```

## Composants Kubernetes

### Preprod

```yaml
Namespace: weather-preprod
  │
  ├── Deployment: weather-app
  │   ├── Replicas: 1
  │   ├── Image: registry/weather-app:preprod
  │   ├── Resources:
  │   │   ├── Requests: 50m CPU, 64Mi RAM
  │   │   └── Limits: 200m CPU, 128Mi RAM
  │   ├── Env:
  │   │   ├── PORT=5000
  │   │   ├── ENVIRONMENT=preprod
  │   │   └── OPENWEATHER_API_KEY (from Secret)
  │   └── Probes:
  │       ├── Liveness: /health
  │       └── Readiness: /ready
  │
  ├── Service: weather-app-service
  │   ├── Type: ClusterIP
  │   ├── Port: 80 → 5000
  │   └── Selector: app=weather-app
  │
  ├── Ingress: weather-app-ingress
  │   ├── Host: weather-preprod.example.com
  │   ├── TLS: letsencrypt-staging
  │   └── Backend: weather-app-service:80
  │
  ├── ConfigMap: weather-app-config
  │   └── PORT, ENVIRONMENT
  │
  └── Secret: weather-app-secret
      └── OPENWEATHER_API_KEY
```

### Production

```yaml
Namespace: weather-prod
  │
  ├── Deployment: weather-app
  │   ├── Replicas: 3 (managed by HPA)
  │   ├── Image: registry/weather-app:latest
  │   ├── Resources:
  │   │   ├── Requests: 200m CPU, 256Mi RAM
  │   │   └── Limits: 1000m CPU, 512Mi RAM
  │   ├── Strategy:
  │   │   ├── Type: RollingUpdate
  │   │   ├── MaxSurge: 1
  │   │   └── MaxUnavailable: 0
  │   └── Probes: /health, /ready
  │
  ├── Service: weather-app-service
  │   └── Type: ClusterIP
  │
  ├── Ingress: weather-app-ingress
  │   ├── Host: weather.example.com
  │   ├── TLS: letsencrypt-prod
  │   └── Rate-limit: 100 req/s
  │
  ├── HorizontalPodAutoscaler
  │   ├── Min: 3 pods
  │   ├── Max: 10 pods
  │   ├── Target CPU: 70%
  │   └── Target Memory: 80%
  │
  ├── PodDisruptionBudget
  │   └── MinAvailable: 2 pods
  │
  ├── ConfigMap: weather-app-config
  │   └── PORT, ENVIRONMENT=production
  │
  └── Secret: weather-app-secret
      └── OPENWEATHER_API_KEY (Sealed Secret)
```

## Scaling Behavior (Production)

```
Load Increase:
  │
  ├─ CPU/Memory > threshold
  │   └─ Metrics Server detects
  │
  ├─ HPA evaluates
  │   ├─ Current: 3 pods @ 75% CPU
  │   ├─ Target: 70% CPU
  │   └─ Decision: Scale up
  │
  ├─ New pods created
  │   ├─ Pod 4: Pending → Running
  │   ├─ Pod 5: Pending → Running
  │   └─ Health checks pass
  │
  └─ Load distributed
      └─ CPU normalizes to ~60%

Load Decrease:
  │
  ├─ CPU/Memory < threshold (5min)
  │
  ├─ HPA evaluates
  │   └─ Decision: Scale down to 4 pods
  │
  ├─ PDB enforced
  │   └─ Ensures min 2 pods always available
  │
  └─ Graceful termination
      ├─ Stop accepting new requests
      ├─ Finish existing requests
      └─ Pod removed
```

## Monitoring Flow

```
Application Metrics
  │
  ├─ Kubernetes Metrics
  │   ├─ CPU usage
  │   ├─ Memory usage
  │   ├─ Pod status
  │   └─ Network I/O
  │
  ├─ Application Logs
  │   ├─ Flask logs
  │   ├─ Gunicorn access logs
  │   └─ Error logs
  │
  └─ Health Checks
      ├─ /health → Liveness
      └─ /ready  → Readiness

         │
         ▼
    Prometheus
         │
         ├─ Scrape metrics
         ├─ Store time series
         └─ Evaluate alerts
         │
         ▼
    Grafana
         │
         └─ Dashboards
             ├─ Pod status
             ├─ Request rate
             ├─ Response time
             └─ Error rate

         │
         ▼
    Alerting
         │
         ├─ High CPU/Memory
         ├─ Pod crashes
         ├─ High error rate
         └─ Slow response time
         │
         └─ Notifications
             ├─ Slack
             ├─ PagerDuty
             └─ Email
```

## Security Layers

```
External Request
  │
  ├─ DNS Resolution
  │   └─ weather.example.com → Load Balancer IP
  │
  ├─ TLS Termination (Ingress)
  │   ├─ Certificate validation
  │   ├─ HTTPS enforcement
  │   └─ TLS 1.2+
  │
  ├─ Ingress Controller
  │   ├─ Rate limiting
  │   ├─ WAF rules (optional)
  │   └─ IP whitelisting (optional)
  │
  ├─ Network Policies
  │   ├─ Allow from Ingress
  │   └─ Deny by default
  │
  ├─ Service (ClusterIP)
  │   └─ Internal only
  │
  └─ Pod Security
      ├─ Non-root user
      ├─ Read-only filesystem
      ├─ Secrets mounted as volumes
      └─ Resource limits enforced
```

## Disaster Recovery

```
Failure Scenario: Pod Crash
  │
  ├─ Liveness probe fails
  │
  ├─ Kubernetes kills pod
  │
  ├─ Deployment controller detects
  │
  ├─ New pod scheduled
  │   ├─ Pull image
  │   ├─ Start container
  │   └─ Run health checks
  │
  └─ Service routes traffic
      └─ No downtime (multiple replicas)

Failure Scenario: Bad Deployment
  │
  ├─ New pods fail readiness
  │
  ├─ Rolling update paused
  │   └─ Old pods still running
  │
  ├─ Monitoring detects issue
  │
  └─ Rollback options:
      ├─ Argo CD: Rollback to previous revision
      ├─ Kubectl: rollout undo
      └─ Git: Revert commit + resync
```

---

Cette architecture assure:
- ✅ **Haute disponibilité** (99.9% SLA en prod)
- ✅ **Zero-downtime deployments**
- ✅ **Auto-scaling** selon la charge
- ✅ **GitOps** avec traçabilité complète
- ✅ **Multi-environnements** isolés
- ✅ **Rollback** rapide en cas de problème
