SWIFT_FORMAT := $(shell which swift-format 2>/dev/null || echo /opt/homebrew/bin/swift-format)

format:
		$(SWIFT_FORMAT) -ri --configuration .swift-format Sources Tests

build: format
		swift build

run: format
		swift run

test: format
		swift test

docker-build:
		docker build --no-cache -t my-website .

docker-build-cached:
		docker build -t my-website .

docker-run:
		docker run --rm -it -p 8080:8080 my-website

docker-dev: docker-build-cached docker-run

docker-clean:
		docker rmi my-website || true

docker-fresh: docker-clean docker-build docker-run

docker-inspect:
		docker run --rm -it --entrypoint /bin/bash my-website

docker-test-css:
		@echo "Testing CSS availability in container..."
		@docker run --rm --entrypoint /bin/bash my-website -c "ls -la /app/public/style.css"

