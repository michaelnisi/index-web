format:
		swift-format -ri --configuration .swift-format Sources Tests

build: format
		swift build

run: format
		swift run
