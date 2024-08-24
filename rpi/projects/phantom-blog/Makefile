.PHONY: up
dev: setup
	@bundle _2.2.34_; bundle; bundle exec jekyll serve;

.PHONY: setup
setup:
	@gem install bundler:2.2.34


.PHONYN: up
up:
	@docker-compose up --build


.PHONY: build
build:
	@docker buildx build --platform linux/arm64 -t phantom-blog:d1349bd752998c63542255368246e663f113bb8f --load .

.PHONY: push
push:
	@docker push wguilherme/phantom-blog:d1349bd752998c63542255368246e663f113bb8f

.PHONY: ci
ci: build push