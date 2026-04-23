SHELL := /bin/bash

.PHONY: setup-namespaces deploy-tenants show-tenants kafka-up kafka-consume kafka-event

setup-namespaces:
	kubectl apply -f k8s/cluster/namespaces.yaml

deploy-tenants:
	bash scripts/deploy_all_tenants.sh

show-tenants:
	kubectl get all -n user1 && kubectl get all -n user2 && kubectl get all -n user3

kafka-up:
	docker compose -f docker-compose.kafka.yml up -d

kafka-consume:
	python events/consume_events.py

kafka-event:
	python events/publish_event.py
