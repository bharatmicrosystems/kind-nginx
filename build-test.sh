#! /bin/bash
docker_username=$1
set -xe

curl -sL https://kind.sigs.k8s.io/dl/v0.9.0/kind-linux-amd64 -o /usr/local/bin/kind
chmod 755 /usr/local/bin//kind

curl -sL https://storage.googleapis.com/kubernetes-release/release/v1.17.4/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
chmod 755 /usr/local/bin//kubectl

curl -LO https://get.helm.sh/helm-v3.1.2-linux-amd64.tar.gz
tar -xzf helm-v3.1.2-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/
rm -rf helm-v3.1.2-linux-amd64.tar.gz

kind version
kubectl version --client=true
helm version

kind create cluster --wait 10m --config kind-config.yaml

kubectl get nodes

docker build -t $docker_username/nginx:dev .
kind load docker-image $docker_username/nginx:dev

kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml

NODE_IP=$(kubectl get node -o wide|tail -1|awk {'print $6'})
NODE_PORT=$(kubectl get svc nginx-service -o go-template='{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{"\n"}}{{end}}{{end}}')
sleep 60
SUCCESS=$(curl $NODE_IP:$NODE_PORT)
if [[ "${SUCCESS}" != "Hello World" ]]; 
then
 kind -q delete cluster
 exit 1;
else
 kind -q delete cluster
 echo "Component test succesful"
fi
