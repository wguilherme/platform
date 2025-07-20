.PHONY: up
dev: setup
	@sudo bundle _2.2.34_; bundle; bundle exec jekyll serve;

.PHONY: setup
setup:
	@gem install bundler:2.2.34


.PHONYN: up
up:
	@docker-compose up --build


.PHONY: build
build:
	@docker buildx build --platform linux/amd64,linux/arm64 -t phantom-blog:latest --load .

.PHONY: push
push:
	@docker push wguilherme/phantom-blog:latest

.PHONY: ci
ci: build push


.PHONY: troubleshoot
troubleshoot: 
	@rm -rf ~/.asdf/shims