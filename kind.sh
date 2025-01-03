#!/bin/bash
#
# Helper script to start KinD
#
# Also adds a docker-registry and an ingress to aid local development
#
# See https://kind.sigs.k8s.io/docs/user/quick-start/ 
#
set -o errexit

[ "$TRACE" ] && set -x

VERBOSE=1
[ "$TRACE" ] && VERBOSE=3


KIND_K8S_IMAGE=${KIND_K8S_IMAGE:-"kindest/node:v1.30.0"}
KIND_CLUSTER_NAME=${KIND_CLUSTER_NAME:-"k8s-home"}
KIND_DOCKER_HOST_ALIAS=${KIND_DOCKER_HOST_ALIAS:-"docker"}
KIND_FIX_KUBECONFIG="${KIND_FIX_KUBECONFIG:-"false"}"
KIND_NGINX_INGRESS_VERSION=${KIND_NGINX_INGRESS_VERSION:-"master"}
KIND_INSTALL_DOCKER_REGISTRY=${KIND_INSTALL_DOCKER_REGISTRY:-"0"}
KIND_WAIT=${KIND_WAIT:-"120s"}
KIND_API_SERVER_ADDRESS=${KIND_API_SERVER_ADDRESS:-"0.0.0.0"}
KIND_API_SERVER_PORT=${KIND_API_SERVER_PORT:-6443}

## Create a cluster with the local registry enabled in container
create() {

cat <<EOF | kind create -v ${VERBOSE}  cluster --name="${KIND_CLUSTER_NAME}" --image="${KIND_K8S_IMAGE}" --wait="${KIND_WAIT}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: ${KIND_API_SERVER_ADDRESS}
  apiServerPort: ${KIND_API_SERVER_PORT}
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  - |
    kind: ClusterConfiguration
  extraPortMappings:
  - containerPort: 80
    hostPort: 4080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
EOF




 if [ "$KIND_FIX_KUBECONFIG" = "true" ]; then
    sed -i -e "s/server: https:\/\/0\.0\.0\.0/server: https:\/\/$KIND_DOCKER_HOST_ALIAS/" "${HOME}/.kube/config"
  fi

  # https://docs.tilt.dev/choosing_clusters.html#discovering-the-registry
  for node in $(kind get nodes --name "${KIND_CLUSTER_NAME}"); do
    kubectl annotate node "${node}" "kind.x-k8s.io/registry=localhost:${KIND_DOCKER_REGISTRY_PORT}";
  done

  # Add nginx ingress
  if [ "${KIND_INSTALL_NGINX_INGRESS}" = '1' ]; then
    kubectl apply -f "https://raw.githubusercontent.com/kubernetes/ingress-nginx/${KIND_NGINX_INGRESS_VERSION}/deploy/static/provider/kind/deploy.yaml"
    kubectl wait --namespace ingress-nginx \
      --for=condition=available \
      --timeout=90s \
      deploy/ingress-nginx-controller
  fi

  if [ "${KIND_INSTALL_DOCKER_REGISTRY}" = '1' ]; then
    docker_registry_start
  fi
}

## Delete the cluster
delete() {
  kind delete cluster --name "${KIND_CLUSTER_NAME}"
}

## Display usage
usage()
{
    echo "usage: $0 [create|delete]"
}

## Argument parsing
if [ "$#" = "0" ]; then
  usage
  exit 1
fi
    
while [ "$1" != "" ]; do
    case $1 in
        create )                create
                                ;;
        delete )                delete
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done
