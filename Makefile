.PHONY: help build run test deploy clean logs status port-forward

# Variables
IMAGE_NAME=weather-app
IMAGE_TAG=latest
NAMESPACE=default
PORT=8080

help: ## Afficher cette aide
	@echo "Commandes disponibles:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Construire l'image Docker
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

run: ## Lancer l'application localement avec Docker
	docker run -d -p 5000:5000 \
		-e OPENWEATHER_API_KEY="demo" \
		--name weather-app-local \
		$(IMAGE_NAME):$(IMAGE_TAG)
	@echo "Application accessible sur http://localhost:5000"

stop: ## Arrêter le conteneur local
	docker stop weather-app-local || true
	docker rm weather-app-local || true

test: ## Tester l'application localement
	@echo "Test de l'endpoint de santé..."
	curl -s http://localhost:5000/health | jq .
	@echo "\nTest de l'API météo..."
	curl -s http://localhost:5000/meteo/Paris | jq .

deploy: ## Déployer sur Kubernetes
	./deploy.sh

deploy-prod: ## Déployer en production avec tag de version
	./deploy.sh -n production -t $(IMAGE_TAG)

clean: ## Nettoyer les ressources Kubernetes
	kubectl delete -f k8s/ -n $(NAMESPACE) || true

logs: ## Afficher les logs de l'application
	kubectl logs -f -l app=weather-app -n $(NAMESPACE)

status: ## Afficher le statut de l'application
	@echo "=== Pods ==="
	kubectl get pods -l app=weather-app -n $(NAMESPACE)
	@echo "\n=== Services ==="
	kubectl get svc -l app=weather-app -n $(NAMESPACE)
	@echo "\n=== Ingress ==="
	kubectl get ingress -l app=weather-app -n $(NAMESPACE)

port-forward: ## Créer un port-forward vers l'application
	@echo "Application accessible sur http://localhost:$(PORT)"
	kubectl port-forward service/weather-app-service $(PORT):80 -n $(NAMESPACE)

describe: ## Décrire les ressources déployées
	kubectl describe deployment weather-app -n $(NAMESPACE)
	kubectl describe service weather-app-service -n $(NAMESPACE)

scale: ## Scaler l'application (usage: make scale REPLICAS=3)
	kubectl scale deployment weather-app --replicas=$(REPLICAS) -n $(NAMESPACE)

restart: ## Redémarrer l'application
	kubectl rollout restart deployment weather-app -n $(NAMESPACE)

watch: ## Suivre le déploiement en temps réel
	watch kubectl get pods -l app=weather-app -n $(NAMESPACE)

shell: ## Ouvrir un shell dans un pod
	kubectl exec -it $$(kubectl get pod -l app=weather-app -n $(NAMESPACE) -o jsonpath='{.items[0].metadata.name}') -n $(NAMESPACE) -- /bin/bash

argocd-deploy: ## Déployer avec Argo CD
	kubectl apply -f argocd-app.yaml

argocd-sync: ## Synchroniser avec Argo CD
	argocd app sync weather-app

argocd-status: ## Voir le statut Argo CD
	argocd app get weather-app

push: ## Pousser l'image vers Docker Hub (usage: make push REGISTRY=username)
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

minikube-build: ## Construire l'image pour Minikube
	eval $$(minikube docker-env) && docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

minikube-deploy: minikube-build ## Construire et déployer sur Minikube
	kubectl apply -f k8s/ -n $(NAMESPACE)
	@echo "\nPour accéder à l'application:"
	@echo "  minikube service weather-app-service -n $(NAMESPACE)"
