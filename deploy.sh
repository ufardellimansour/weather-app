#!/bin/bash

# Script de déploiement automatisé pour l'application météo
# Usage: ./deploy.sh [options]

set -e

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration par défaut
NAMESPACE="default"
IMAGE_NAME="weather-app"
IMAGE_TAG="latest"
DOCKER_REGISTRY=""

# Fonctions utilitaires
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 n'est pas installé. Veuillez l'installer."
        exit 1
    fi
}

# Vérifier les prérequis
check_prerequisites() {
    print_info "Vérification des prérequis..."
    check_command docker
    check_command kubectl
    print_info "Tous les prérequis sont installés ✓"
}

# Construire l'image Docker
build_image() {
    print_info "Construction de l'image Docker..."
    
    if [ -n "$DOCKER_REGISTRY" ]; then
        FULL_IMAGE_NAME="${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    else
        FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
    fi
    
    docker build -t $FULL_IMAGE_NAME .
    
    if [ $? -eq 0 ]; then
        print_info "Image construite avec succès: $FULL_IMAGE_NAME ✓"
    else
        print_error "Échec de la construction de l'image"
        exit 1
    fi
}

# Pousser l'image vers le registry
push_image() {
    if [ -n "$DOCKER_REGISTRY" ]; then
        print_info "Push de l'image vers le registry..."
        docker push $FULL_IMAGE_NAME
        
        if [ $? -eq 0 ]; then
            print_info "Image poussée avec succès ✓"
        else
            print_error "Échec du push de l'image"
            exit 1
        fi
    else
        print_warn "Aucun registry configuré, skip du push"
    fi
}

# Vérifier la clé API
check_api_key() {
    print_info "Vérification de la clé API..."
    
    if grep -q "OPENWEATHER_API_KEY: \"demo\"" k8s/secret.yaml; then
        print_warn "⚠️  Vous utilisez toujours la clé API 'demo'"
        print_warn "⚠️  Veuillez mettre à jour k8s/secret.yaml avec votre vraie clé API"
        print_warn "⚠️  Obtenez une clé gratuite sur: https://openweathermap.org/api"
        read -p "Voulez-vous continuer quand même ? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_info "Clé API configurée ✓"
    fi
}

# Mettre à jour l'image dans le deployment
update_deployment_image() {
    print_info "Mise à jour de l'image dans le deployment..."
    
    # Créer un fichier temporaire avec l'image mise à jour
    sed "s|image: .*|image: $FULL_IMAGE_NAME|g" k8s/deployment.yaml > k8s/deployment.yaml.tmp
    mv k8s/deployment.yaml.tmp k8s/deployment.yaml
    
    print_info "Deployment mis à jour avec l'image: $FULL_IMAGE_NAME ✓"
}

# Déployer sur Kubernetes
deploy_k8s() {
    print_info "Déploiement sur Kubernetes..."
    
    # Créer le namespace si nécessaire
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Appliquer les manifests
    kubectl apply -f k8s/ -n $NAMESPACE
    
    if [ $? -eq 0 ]; then
        print_info "Déploiement réussi ✓"
    else
        print_error "Échec du déploiement"
        exit 1
    fi
}

# Attendre que les pods soient prêts
wait_for_pods() {
    print_info "Attente que les pods soient prêts..."
    kubectl wait --for=condition=ready pod -l app=weather-app -n $NAMESPACE --timeout=120s
    
    if [ $? -eq 0 ]; then
        print_info "Tous les pods sont prêts ✓"
    else
        print_error "Timeout en attendant les pods"
        kubectl get pods -n $NAMESPACE -l app=weather-app
        exit 1
    fi
}

# Afficher le statut
show_status() {
    print_info "Statut de l'application:"
    echo
    kubectl get pods,svc,ingress -n $NAMESPACE -l app=weather-app
    echo
    
    print_info "Pour accéder à l'application:"
    echo "  kubectl port-forward service/weather-app-service 8080:80 -n $NAMESPACE"
    echo "  Puis ouvrez: http://localhost:8080"
    echo
    
    print_info "Pour voir les logs:"
    echo "  kubectl logs -f -l app=weather-app -n $NAMESPACE"
}

# Fonction de nettoyage
cleanup() {
    print_warn "Nettoyage des ressources..."
    kubectl delete -f k8s/ -n $NAMESPACE
    print_info "Nettoyage terminé ✓"
}

# Afficher l'aide
show_help() {
    cat << EOF
Usage: $0 [options]

Options:
    -h, --help              Afficher cette aide
    -n, --namespace NAME    Namespace Kubernetes (défaut: default)
    -r, --registry URL      URL du Docker registry
    -t, --tag TAG           Tag de l'image Docker (défaut: latest)
    -s, --skip-build        Skip la construction de l'image
    -c, --cleanup           Nettoyer les ressources déployées
    --no-push               Ne pas pousser l'image vers le registry

Exemples:
    # Déploiement simple
    $0

    # Déploiement avec registry privé
    $0 -r registry.example.com -t v1.0.0

    # Déploiement dans un namespace spécifique
    $0 -n production -t v1.0.0

    # Nettoyage
    $0 --cleanup
EOF
}

# Parse des arguments
SKIP_BUILD=false
NO_PUSH=false
CLEANUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--registry)
            DOCKER_REGISTRY="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -s|--skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --no-push)
            NO_PUSH=true
            shift
            ;;
        -c|--cleanup)
            CLEANUP=true
            shift
            ;;
        *)
            print_error "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main
main() {
    echo "=========================================="
    echo "  Déploiement Weather App - Kubernetes"
    echo "=========================================="
    echo
    
    if [ "$CLEANUP" = true ]; then
        cleanup
        exit 0
    fi
    
    check_prerequisites
    check_api_key
    
    if [ "$SKIP_BUILD" = false ]; then
        build_image
        
        if [ "$NO_PUSH" = false ]; then
            push_image
        fi
        
        update_deployment_image
    fi
    
    deploy_k8s
    wait_for_pods
    show_status
    
    echo
    print_info "🎉 Déploiement terminé avec succès!"
}

# Exécuter le script
main
