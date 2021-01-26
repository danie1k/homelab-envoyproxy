NAME = homelab-envoyproxy

build:
	@docker build -t $(NAME) .

build-nocache:
	@docker build -t $(NAME) --no-cache .

run:
	@docker rm -f $(NAME) || true
	@docker run --rm --name $(NAME) $(NAME)
