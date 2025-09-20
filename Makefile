format:
		swift-format -ri --configuration .swift-format Sources Tests

build: format
		swift build

run: format
		swift run

test: format
		swift test

docker-build:
		docker build -t my-website .

docker-run:
		docker run --rm -it -p 8080:8080 my-website
