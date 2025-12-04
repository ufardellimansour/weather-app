#!/bin/bash

# Script de diagnostic Argo CD
# Usage: ./diagnose-argocd.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "════════════════════════════════════════════════════════════"
echo "  🔍 Diagnostic Argo CD"
echo "════════════════════════════════════════════════════════════"
echo

# 1. Vérifier que kubectl fonctionne
echo -e "${GREEN}[1/8]${NC} Vérification de kubectl..."
if kubectl version --short &> /dev/null; then
    echo "  ✅ kubectl fonctionne"
else
    echo -e "  ${RED}❌ kubectl ne fonctionne pas${NC}"
    exit 1
fi
echo

# 2. Vérifier le namespace argocd
echo -e "${GREEN}[2/8]${NC} Vérification du namespace argocd..."
if kubectl get namespace argocd &> /dev/null; then
    echo "  ✅ Namespace argocd existe"
else
    echo -e "  ${RED}❌ Namespace argocd n'existe pas${NC}"
    echo "  💡 Installe Argo CD avec:"
    echo "     kubectl create namespace argocd"
    echo "     kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
    exit 1
fi
echo

# 3. Vérifier les pods Argo CD
echo -e "${GREEN}[3/8]${NC} Vérification des pods Argo CD..."
PODS_STATUS=$(kubectl get pods -n argocd --no-headers | awk '{print $3}')
NOT_RUNNING=$(echo "$PODS_STATUS" | grep -v "Running" | wc -l)

if [ "$NOT_RUNNING" -eq 0 ]; then
    echo "  ✅ Tous les pods sont Running"
    kubectl get pods -n argocd
else
    echo -e "  ${YELLOW}⚠️  Certains pods ne sont pas Running${NC}"
    kubectl get pods -n argocd
fi
echo

# 4. Vérifier les projets
echo -e "${GREEN}[4/8]${NC} Vérification des projets AppProject..."
PROJECTS=$(kubectl get appproject -n argocd --no-headers 2>/dev/null | wc -l)

if [ "$PROJECTS" -eq 0 ]; then
    echo -e "  ${RED}❌ Aucun projet trouvé !${NC}"
    echo "  💡 Le projet 'default' devrait exister"
    echo "  🔧 Création du projet default..."
    
    kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: default
  namespace: argocd
spec:
  description: Default project
  sourceRepos:
  - '*'
  destinations:
  - namespace: '*'
    server: '*'
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
EOF
    
    echo "  ✅ Projet 'default' créé"
else
    echo "  ✅ $PROJECTS projet(s) trouvé(s):"
    kubectl get appproject -n argocd -o custom-columns=NAME:.metadata.name,DESCRIPTION:.spec.description
fi
echo

# 5. Vérifier si le projet 'default' existe
echo -e "${GREEN}[5/8]${NC} Vérification du projet 'default'..."
if kubectl get appproject default -n argocd &> /dev/null; then
    echo "  ✅ Projet 'default' existe"
else
    echo -e "  ${RED}❌ Projet 'default' n'existe pas${NC}"
    echo "  🔧 Création du projet default..."
    
    kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: default
  namespace: argocd
spec:
  description: Default project
  sourceRepos:
  - '*'
  destinations:
  - namespace: '*'
    server: '*'
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
EOF
    
    echo "  ✅ Projet 'default' créé"
fi
echo

# 6. Vérifier Argo CD CLI
echo -e "${GREEN}[6/8]${NC} Vérification de la CLI argocd..."
if command -v argocd &> /dev/null; then
    echo "  ✅ CLI argocd installée"
    argocd version --short 2>/dev/null || echo "  (non connecté)"
else
    echo -e "  ${YELLOW}⚠️  CLI argocd non installée${NC}"
    echo "  💡 Installe avec:"
    echo "     brew install argocd  # macOS"
    echo "     # Ou télécharge depuis: https://github.com/argoproj/argo-cd/releases"
fi
echo

# 7. Vérifier les applications existantes
echo -e "${GREEN}[7/8]${NC} Vérification des applications..."
APPS=$(kubectl get application -n argocd --no-headers 2>/dev/null | wc -l)

if [ "$APPS" -eq 0 ]; then
    echo "  📝 Aucune application déployée"
else
    echo "  ✅ $APPS application(s) trouvée(s):"
    kubectl get application -n argocd -o custom-columns=NAME:.metadata.name,PROJECT:.spec.project,SYNC:.status.sync.status
fi
echo

# 8. Vérifier l'accès au serveur Argo CD
echo -e "${GREEN}[8/8]${NC} Vérification de l'accès au serveur Argo CD..."
if kubectl get service argocd-server -n argocd &> /dev/null; then
    echo "  ✅ Service argocd-server existe"
    echo
    echo "  💡 Pour accéder à l'UI:"
    echo "     kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "     Puis ouvre: https://localhost:8080"
    echo
    echo "  🔑 Pour obtenir le mot de passe admin:"
    echo "     kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d && echo"
else
    echo -e "  ${RED}❌ Service argocd-server n'existe pas${NC}"
fi
echo

echo "════════════════════════════════════════════════════════════"
echo "  📊 Résumé"
echo "════════════════════════════════════════════════════════════"
echo

if kubectl get appproject default -n argocd &> /dev/null; then
    echo -e "  ${GREEN}✅ Argo CD est prêt !${NC}"
    echo
    echo "  🚀 Tu peux maintenant créer une application:"
    echo
    echo "  Via kubectl:"
    echo "  ------------"
    echo "  kubectl apply -f k8s-argocd/argocd-app-preprod-simple.yaml"
    echo
    echo "  Via argocd CLI:"
    echo "  ---------------"
    echo "  argocd app create weather-app-preprod \\"
    echo "    --repo https://github.com/TON-USERNAME/weather-app.git \\"
    echo "    --path k8s-argocd/overlays/preprod \\"
    echo "    --dest-server https://kubernetes.default.svc \\"
    echo "    --dest-namespace weather-preprod \\"
    echo "    --revision develop"
    echo
    echo "  Via l'UI:"
    echo "  ---------"
    echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "  Puis ouvre: https://localhost:8080"
else
    echo -e "  ${YELLOW}⚠️  Il y a encore des problèmes${NC}"
    echo "  📝 Consulte les messages ci-dessus"
fi
echo

echo "════════════════════════════════════════════════════════════"
