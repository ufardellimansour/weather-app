# 📊 Comparaison des Environnements

Tableau comparatif détaillé entre Preprod et Production.

## Configuration Résumée

| Aspect | Preprod | Production |
|--------|---------|------------|
| **Namespace** | `weather-preprod` | `weather-prod` |
| **Replicas Min** | 1 | 3 |
| **Replicas Max** | 1 (pas d'HPA) | 10 (avec HPA) |
| **CPU Request** | 50m | 200m |
| **CPU Limit** | 200m | 1000m (1 core) |
| **RAM Request** | 64Mi | 256Mi |
| **RAM Limit** | 128Mi | 512Mi |
| **Branch Git** | `develop` | `main` |
| **Image Tag** | `preprod` | `latest` |
| **Domain** | `weather-preprod.example.com` | `weather.example.com` |
| **TLS Cert** | Let's Encrypt Staging | Let's Encrypt Production |
| **Auto Sync** | ✅ Activé | ❌ Manuel (recommandé) |
| **HPA** | ❌ Non | ✅ Oui (3-10 pods) |
| **PDB** | ❌ Non | ✅ Oui (min 2 pods) |

## Ressources Kubernetes Détaillées

### Preprod

```yaml
# Deployment
replicas: 1
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 128Mi

# Service
type: ClusterIP
port: 80 → 5000

# Ingress
host: weather-preprod.example.com
tls:
  issuer: letsencrypt-staging

# Pas de HPA
# Pas de PDB
```

**Coût estimé**: ~$10-20/mois (selon cloud provider)

### Production

```yaml
# Deployment
replicas: 3 (géré par HPA)
resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 512Mi

# Service
type: ClusterIP
port: 80 → 5000

# Ingress
host: weather.example.com
tls:
  issuer: letsencrypt-prod
annotations:
  nginx.ingress.kubernetes.io/rate-limit: "100"

# HPA
minReplicas: 3
maxReplicas: 10
targetCPU: 70%
targetMemory: 80%

# PDB
minAvailable: 2
```

**Coût estimé**: ~$50-150/mois (selon charge et cloud provider)

## Capacité et Performance

### Preprod

| Métrique | Valeur |
|----------|--------|
| **Pods** | 1 |
| **CPU Total** | 200m max |
| **RAM Total** | 128Mi max |
| **Requêtes/sec** | ~10-20 |
| **Utilisateurs simultanés** | ~50 |
| **Disponibilité SLA** | Aucune garantie |
| **Downtime accepté** | Oui |

**Usage**: Tests, validation, démo

### Production

| Métrique | Valeur |
|----------|--------|
| **Pods Min** | 3 |
| **Pods Max** | 10 |
| **CPU Total** | 3000m-10000m |
| **RAM Total** | 1.5Gi-5Gi |
| **Requêtes/sec** | ~100-500 (avec HPA) |
| **Utilisateurs simultanés** | ~500-2000 |
| **Disponibilité SLA** | 99.9% (avec PDB) |
| **Downtime accepté** | Minimal |

**Usage**: Production, utilisateurs réels

## Stratégie de Déploiement

### Preprod

```yaml
syncPolicy:
  automated:
    prune: true      # Nettoyage automatique
    selfHeal: true   # Correction automatique
```

- ✅ **Sync automatique**: Dès qu'un commit est poussé sur `develop`
- ✅ **Self-heal**: Revient automatiquement à l'état Git
- ✅ **Prune**: Supprime les ressources obsolètes
- ⚡ **Déploiement**: Immédiat après push
- 🎯 **Usage**: Tests rapides, validation continue

### Production

```yaml
syncPolicy:
  # Pas d'automated - sync manuel requis
  syncOptions:
    - CreateNamespace=true
  retry:
    limit: 5
```

- ❌ **Sync manuel**: Contrôle total sur les déploiements
- 🔒 **Validation**: Review obligatoire avant sync
- 📊 **Tests**: Validation en preprod d'abord
- ⏱️ **Timing**: Déploiements planifiés (maintenance windows)
- 🎯 **Usage**: Stabilité, contrôle, audit

## Workflow GitOps

### Flux Preprod

```
Code Change → develop branch → Git Push
  ↓
Argo CD détecte le changement (auto-refresh 3min)
  ↓
Auto-sync activé → Déploiement immédiat
  ↓
Tests automatiques (optionnel)
  ↓
Validation manuelle si OK
```

**Temps de déploiement**: 3-5 minutes

### Flux Production

```
Tests OK en preprod → Merge develop → main
  ↓
Build image production (tag: latest)
  ↓
Push image vers registry
  ↓
Argo CD détecte changement (3min)
  ↓
Sync MANUEL requis par opérateur
  ↓
Review des changements (argocd app diff)
  ↓
Approbation → Sync
  ↓
Rolling update (zero downtime)
  ↓
Validation post-déploiement
  ↓
Monitoring continu
```

**Temps de déploiement**: 10-20 minutes (avec validations)

## Haute Disponibilité (Production)

### HorizontalPodAutoscaler

```yaml
minReplicas: 3
maxReplicas: 10
metrics:
  - CPU: 70%
  - Memory: 80%
```

**Comportement**:
- Scale up: Si CPU > 70% ou RAM > 80%
- Scale down: Après 5 minutes de stabilité
- Max scale up: 2 pods toutes les 30s

### PodDisruptionBudget

```yaml
minAvailable: 2
```

**Protection**:
- Minimum 2 pods toujours disponibles
- Empêche les drains excessifs
- Protège pendant les maintenances cluster

### Stratégie de Rolling Update

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1        # 1 pod supplémentaire pendant update
    maxUnavailable: 0  # 0 pod indisponible (zero downtime)
```

## Sécurité

### Preprod

- 🔓 Secrets: Peut utiliser des valeurs de test
- 🔓 TLS: Certificats staging (non validés)
- 🔓 RBAC: Accès plus large pour les développeurs
- 🔓 Network Policies: Optionnelles
- ⚠️ Données: PAS de données sensibles

### Production

- 🔒 Secrets: Sealed Secrets ou External Secrets **OBLIGATOIRE**
- 🔒 TLS: Certificats production validés
- 🔒 RBAC: Accès strict, audit logs
- 🔒 Network Policies: Recommandées
- 🔒 Données: Chiffrement at-rest et in-transit
- 🔒 Rate limiting: Activé (100 req/s par IP)

## Monitoring et Observabilité

### Preprod

- Logs: Kubectl logs (basique)
- Métriques: Optionnelles
- Alertes: Non
- APM: Non
- Coût monitoring: Gratuit

### Production

- Logs: Agrégés (ELK, Loki)
- Métriques: Prometheus + Grafana
- Alertes: PagerDuty, Slack
- APM: New Relic, Datadog (optionnel)
- Health checks: /health, /ready
- Uptime monitoring: Externe (UptimeRobot, Pingdom)
- Coût monitoring: $50-200/mois

## Coûts Comparatifs

### Infrastructure

| Ressource | Preprod/mois | Prod/mois |
|-----------|-------------|-----------|
| Compute | $10-20 | $50-100 |
| Ingress/LB | $5-10 | $20-30 |
| Storage | $5 | $10-20 |
| Monitoring | $0 | $50-100 |
| **Total** | **$20-35** | **$130-250** |

*Basé sur des estimations cloud provider standards (GCP/AWS/Azure)*

### Temps Opérationnel

| Tâche | Preprod | Production |
|-------|---------|------------|
| Déploiement | 5 min | 20 min |
| Rollback | 2 min | 10 min |
| Debug | 10 min | 30-60 min |
| Incident response | N/A | 2-4h |

## Quand Utiliser Chaque Environnement?

### Preprod 🧪

✅ **Utiliser pour**:
- Tests de nouvelles fonctionnalités
- Validation des PRs
- Tests d'intégration
- Démos clients (non-production)
- Formation développeurs
- Tests de charge légers

❌ **Ne PAS utiliser pour**:
- Données clients réelles
- Tests de charge production-like
- Démonstrations critiques
- SLA garantis

### Production 🚀

✅ **Utiliser pour**:
- Trafic utilisateur réel
- Données de production
- Services avec SLA
- Applications critiques
- APIs publiques

❌ **Ne PAS utiliser pour**:
- Tests expérimentaux
- Code non validé
- Changements ad-hoc
- Debug de nouvelles fonctionnalités

## Checklist de Migration Preprod → Prod

Avant de déployer en production:

- [ ] ✅ Tests complets en preprod
- [ ] ✅ Tests de charge
- [ ] ✅ Validation fonctionnelle
- [ ] ✅ Review du code
- [ ] ✅ Secrets de production configurés
- [ ] ✅ Domaine et DNS configurés
- [ ] ✅ Certificats TLS valides
- [ ] ✅ Monitoring et alertes en place
- [ ] ✅ Plan de rollback préparé
- [ ] ✅ Documentation à jour
- [ ] ✅ Équipe informée
- [ ] ✅ Fenêtre de maintenance planifiée

## Résumé

| Aspect | Preprod | Production |
|--------|---------|------------|
| **Objectif** | Tests & Validation | Service Production |
| **Stabilité** | Instable OK | Haute disponibilité |
| **Coût** | Minimal (~$20-35/mois) | Optimisé (~$130-250/mois) |
| **Sync** | Automatique | Manuel |
| **Données** | Test uniquement | Données réelles |
| **SLA** | Aucun | 99.9% |
| **Scaling** | Non | Oui (HPA) |

---

**Recommandation**: Toujours tester en preprod avant de déployer en production ! 🎯
