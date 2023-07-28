APP := coco-cart
APP_MODULE := coco-cart
PYTHON := python

POETRY_VERSION := 1.5.1
POETRY_ARGS ?=
POETRY_HOME ?= $(CURDIR)/poetry
POETRY := poetry $(POETRY_ARGS)
PACKAGE_RUNNER := $(POETRY) run

IMAGE_VERSION ?= $(shell git rev-parse --short HEAD)
FLAKE8_OPTS ?=
MYPY_OPTS ?= --no-namespace-packages
IMAGE_NAME := $(APP)-backend

PORT ?= 8888
CONTAINER_CMD ?= docker

DOCKER_PROJECT_NAME ?= $(IMAGE_VERSION)-$(BUILD_NUMBER)

DOCKER_BUILD_ARGS_BASE = --build-arg USER_NAME=ty-app
DOCKER_BUILD_ARGS_BASE += --build-arg GROUP_NAME=ty-app

DOCKER_BUILD_ARGS_DEV = $(DOCKER_BUILD_ARGS_BASE)
DOCKER_BUILD_ARGS_DEV += --build-arg USER_ID=$(shell id -u $(USER))
DOCKER_BUILD_ARGS_DEV += --build-arg GROUP_ID=$(shell id -g $(USER))

DOCKER_BUILD_ARGS_RUNTIME = $(DOCKER_BUILD_ARGS_BASE)
DOCKER_BUILD_ARGS_RUNTIME += --build-arg USER_ID=1000
DOCKER_BUILD_ARGS_RUNTIME += --build-arg GROUP_ID=1000

DOCKER_CMP_RUN_DEV := docker-compose -p $(DOCKER_PROJECT_NAME) run --rm backend

PATH := $(POETRY_HOME)/bin:$(PATH)

.DEFAULT: help
.PHONY: test

help:	## Show this help menu.
	@echo "Usage: make [TARGET ...]"
	@echo ""
	@@egrep -h "#[#]" $(MAKEFILE_LIST) | sed -e 's/\\$$//' | awk 'BEGIN {FS = "[:=].*?#[#] "}; \
		{printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

clean: clean-logs	## clean project from any build output
	rm -rf $(VENV_BASE)
	rm -f poetry.lock

clean-logs:	## clean all logs files
	rm -rf flake8.log .converage mypy.log coverage.xml junit.xml htmlcov
	find . -name "*.pyc" -delete

lock-deps:	# creates a poetry.lock file based on the dependecies of pyproject.toml
lock-deps: image-base
	@echo Locking dependencies ...
	docker-compose run --no-deps --rm coco-cart poetry lock --no-update

deps:	## install dependencies
deps: lock-deps
	@echo Installing dependencies ...
	@$(POETRY) install --without dev

deps-dev:	## install development dependencies
deps-dev: lock-deps
	@echo Installing development dependencies ...
	@$(POETRY) install

format:	## format code style
format:
	@echo Running code formatters:
	@echo Running black ...
	@$(DOCKER_RUN_MODULE_PYTHON_DEV) black ra_kafka_handlers service_schemas
	@echo Running isort ...
	@$(DOCKER_RUN_MODULE_PYTHON_DEV) isort ra_kafka_handlers service_schemas

format-check:
	@echo Running code formatters, check only:
	@echo Running black check...
	@$(DOCKER_RUN_MODULE_PYTHON_DEV) black --check ra_kafka_handlers service_schemas
	@echo Running isort check ...
	@$(DOCKER_RUN_MODULE_PYTHON_DEV) isort -c ra_kafka_handlers service_schemas

lint:	## run pycodestyle, flake8, mypy...
lint: FLAKE8_OPTS := --output-file=flake8.log --tee
lint: MYPY_OPTS := > mypy.log
lint:
	@echo Running linters:
	@echo Running flake8 ...
	@$(DOCKER_RUN_MODULE_PYTHON_DEV) flake8 $(FLAKE8_OPTS) $(APP_MODULE)
	@echo Running mypy ...
	@$(DOCKER_RUN_MODULE_PYTHON_DEV) mypy $(APP_MODULE) tests $(MYPY_OPTS)

test:	## run tests and show report
test: PYTEST_OPTS := -v --junit-xml=junit.xml
test: test-unit

test-unit:
	@echo Running tests
	$(DOCKER_CMP_RUN_DEV) python -m pytest $(PYTEST_OPTS) $(PYTEST_ARGS) tests/

build-all: image-all 	## build all docker images
image-all:	## build all docker images
	$(MAKE) image-dev
	$(MAKE) image
image: DOCKER_BUILD_ARGS=$(DOCKER_BUILD_ARGS_RUNTIME)
image: image_runtime	    ## build docker image
image-base: image_base	## build base docker image
image-builder: image_builder	## build base docker image

image-dev: DOCKER_BUILD_ARGS=$(DOCKER_BUILD_ARGS_DEV)
image-dev: image_dev	    ## build dev docker image
image_%:
	$(CONTAINER_CMD) build $(DOCKER_BUILD_ARGS) \
	 	-t $(IMAGE_NAME):latest$(subst -runtime,,-$*) \
	 	-t $(IMAGE_NAME):$(IMAGE_VERSION)$(subst -runtime,,-$*) \
	 	--target $*-image \
	 	backend/

dev: image-dev	## Check code before add new git commit
	make lint
	make format
	make test
	make down
	@echo "Done!"

up:
	@echo Bring up containers for project $(DOCKER_PROJECT_NAME) and detach
	docker-compose -f docker-compose.yaml -p $(DOCKER_PROJECT_NAME) up -d
down:
	@echo Bring down containers for project $(DOCKER_PROJECT_NAME) remove them
	docker-compose -f docker-compose.yaml -p $(DOCKER_PROJECT_NAME) down

compose-project:
	@echo $(DOCKER_PROJECT_NAME)

