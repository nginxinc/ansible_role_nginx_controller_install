DOCKER_LINT_IMAGE = ansible-controller-lint:latest

lint:
	docker build -f tests/Dockerfile -t $(DOCKER_LINT_IMAGE) .
	docker run $(DOCKER_LINT_IMAGE) ansible-lint .