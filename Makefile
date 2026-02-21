format:
		swift-format -ri --configuration .swift-format Sources Tests

build: format
		swift build

run: format
		swift run

test: format
		swift test

docker-build:
		docker build --no-cache -t my-website .

docker-run:
		docker run --rm -it -p 8080:8080 my-website

docker-clean:
		docker rmi my-website || true

docker-fresh: docker-clean docker-build docker-run

docker-inspect:
		docker run --rm -it --entrypoint /bin/bash my-website

docker-test-css:
		@echo "Testing CSS availability in container..."
		@docker run --rm --entrypoint /bin/bash my-website -c "ls -la /app/public/style.css"

