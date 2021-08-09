.PHONY : default local-up local-down local-cluster-up setup-mac upgrade-mac local-tidy aws-up aws-tidy

default: local-up

local-up: local-cluster-up
	tilt up

local-down:
	tilt down

local-cluster-up:
	ctlptl apply -f ./infra/k8s/kind.ctlptl.yaml

setup-mac:
	brew install kind tilt-dev/tap/ctlptl tilt-dev/tap/tilt

upgrade-mac:
	brew upgrade kind tilt-dev/tap/ctlptl tilt-dev/tap/tilt

local-tidy:
	ctlptl delete -f ./infra/k8s/kind.ctlptl.yaml

aws-up:
	./script/cluster_up.sh

aws-tidy:
	./script/cluster_down.sh
