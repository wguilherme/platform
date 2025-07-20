.PHONY: up down stop setup

SHELL := /bin/bash

.DEFAULT_GOAL := up

up: down
	@docker compose up --build

down:
	@docker compose down --rmi local

stop:
	@docker compose stop

logs:
	@docker compose logs -f

setup:
	@pip install --upgrade pip && pip install -r requirements.txt