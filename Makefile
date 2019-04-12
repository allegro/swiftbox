DOCKER_TAG = swiftbox-dev:latest
WORKDIR = /opt/swiftbox

update:
	swift package update

xcode:
	swift package generate-xcodeproj  --enable-code-coverage

debug:
	swift build -v -c debug

release:
	swift build -v -c release

test:
	swift test

docker_test:
	docker build . -f docker/Dockerfile-dev -t $(DOCKER_TAG)
	docker run --rm -v `pwd`:$(WORKDIR) $(DOCKER_TAG) make test
	docker run --rm -v `pwd`:$(WORKDIR) $(DOCKER_TAG) make lint

format:
	swiftformat ./Sources

lint:
	swiftformat --lint --verbose ./Sources

