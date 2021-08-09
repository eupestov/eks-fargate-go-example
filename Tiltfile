
docker_build("epestov/replacer", ".")
k8s_yaml(kustomize('infra/k8s/application'))
k8s_resource('replacer', port_forwards=8080)