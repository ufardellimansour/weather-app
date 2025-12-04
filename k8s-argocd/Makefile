.PHONY: help validate-preprod validate-prod deploy-preprod deploy-prod sync-preprod sync-prod status diff clean

help: ## Afficher cette aide
	@echo "Commandes Argo CD disponibles:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

validate-preprod: ## Valider les manifests preprod
	@echo "Validation des manifests preprod..."
	kustomize build overlays/preprod | kubectl apply --dry-run=client -f -

validate-prod: ## Valider les manifests prod
	@echo "Validation des manifests prod..."
	kustomize build overlays/prod | kubectl apply --dry-run=client -f -

build-preprod: ## Générer les manifests preprod
	kustomize build overlays/preprod

build-prod: ## Générer les manifests prod
	kustomize build overlays/prod

deploy-preprod: ## Déployer l'application Argo CD preprod
	@echo "Déploiement de l'application preprod dans Argo CD..."
	kubectl apply -f argocd-preprod.yaml
	@echo "✓ Application preprod créée"

deploy-prod: ## Déployer l'application Argo CD prod
	@echo "Déploiement de l'application prod dans Argo CD..."
	kubectl apply -f argocd-prod.yaml
	@echo "✓ Application prod créée"

sync-preprod: ## Synchroniser l'application preprod
	@echo "Synchronisation de l'application preprod..."
	argocd app sync weather-app-preprod --prune

sync-prod: ## Synchroniser l'application prod
	@echo "Synchronisation de l'application prod..."
	argocd app sync weather-app-prod --prune

refresh-preprod: ## Rafraîchir l'application preprod
	argocd app get weather-app-preprod --refresh

refresh-prod: ## Rafraîchir l'application prod
	argocd app get weather-app-prod --refresh

status: ## Afficher le statut de toutes les applications
	@echo "=== Statut Argo CD ==="
	@argocd app list | grep weather-app || echo "Aucune application weather-app trouvée"
	@echo "\n=== Preprod ==="
	@kubectl get pods,svc,ingress -n weather-preprod 2>/dev/null || echo "Namespace weather-preprod non trouvé"
	@echo "\n=== Production ==="
	@kubectl get pods,svc,ingress,hpa -n weather-prod 2>/dev/null || echo "Namespace weather-prod non trouvé"

status-preprod: ## Afficher le statut détaillé preprod
	argocd app get weather-app-preprod

status-prod: ## Afficher le statut détaillé prod
	argocd app get weather-app-prod

diff-preprod: ## Voir les différences preprod
	argocd app diff weather-app-preprod

diff-prod: ## Voir les différences prod
	argocd app diff weather-app-prod

history-preprod: ## Voir l'historique des déploiements preprod
	argocd app history weather-app-preprod

history-prod: ## Voir l'historique des déploiements prod
	argocd app history weather-app-prod

rollback-preprod: ## Rollback preprod (usage: make rollback-preprod ID=5)
	argocd app rollback weather-app-preprod $(ID)

rollback-prod: ## Rollback prod (usage: make rollback-prod ID=5)
	argocd app rollback weather-app-prod $(ID)

logs-preprod: ## Afficher les logs preprod
	kubectl logs -f -l app=weather-app -n weather-preprod

logs-prod: ## Afficher les logs prod
	kubectl logs -f -l app=weather-app -n weather-prod

delete-preprod: ## Supprimer l'application preprod
	@echo "⚠️  Suppression de l'application preprod..."
	@read -p "Êtes-vous sûr? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		argocd app delete weather-app-preprod --cascade; \
	fi

delete-prod: ## Supprimer l'application prod
	@echo "⚠️  ATTENTION: Suppression de l'application PRODUCTION..."
	@read -p "Êtes-vous VRAIMENT sûr? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		argocd app delete weather-app-prod --cascade; \
	fi

clean: delete-preprod delete-prod ## Supprimer toutes les applications

scale-preprod: ## Scaler preprod (usage: make scale-preprod REPLICAS=2)
	kubectl scale deployment weather-app --replicas=$(REPLICAS) -n weather-preprod

scale-prod: ## Scaler prod (usage: make scale-prod REPLICAS=5)
	kubectl scale deployment weather-app --replicas=$(REPLICAS) -n weather-prod

watch-preprod: ## Suivre les pods preprod en temps réel
	watch kubectl get pods -n weather-preprod

watch-prod: ## Suivre les pods prod en temps réel
	watch kubectl get pods -n weather-prod

port-forward-preprod: ## Port-forward vers preprod
	kubectl port-forward -n weather-preprod service/weather-app-service 8080:80

port-forward-prod: ## Port-forward vers prod
	kubectl port-forward -n weather-prod service/weather-app-service 8081:80

events-preprod: ## Voir les événements preprod
	kubectl get events -n weather-preprod --sort-by='.lastTimestamp'

events-prod: ## Voir les événements prod
	kubectl get events -n weather-prod --sort-by='.lastTimestamp'

describe-preprod: ## Décrire les ressources preprod
	kubectl describe deployment weather-app -n weather-preprod
	kubectl describe service weather-app-service -n weather-preprod

describe-prod: ## Décrire les ressources prod
	kubectl describe deployment weather-app -n weather-prod
	kubectl describe service weather-app-service -n weather-prod
	kubectl describe hpa weather-app-hpa -n weather-prod

deploy-all: deploy-preprod deploy-prod ## Déployer preprod et prod

sync-all: sync-preprod sync-prod ## Synchroniser preprod et prod

test-preprod: ## Tester l'application preprod
	@echo "Test de santé preprod..."
	@kubectl run -it --rm test-preprod --image=curlimages/curl --restart=Never -n weather-preprod -- \
		curl -s http://weather-app-service/health | grep -q "healthy" && \
		echo "✓ Preprod est en bonne santé" || \
		echo "✗ Preprod n'est pas accessible"

test-prod: ## Tester l'application prod
	@echo "Test de santé prod..."
	@kubectl run -it --rm test-prod --image=curlimages/curl --restart=Never -n weather-prod -- \
		curl -s http://weather-app-service/health | grep -q "healthy" && \
		echo "✓ Prod est en bonne santé" || \
		echo "✗ Prod n'est pas accessible"
