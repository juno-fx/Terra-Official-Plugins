helm repo add rocketchat https://rocketchat.github.io/helm-charts

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cat 'image:
  pullPolicy: IfNotPresent
  repository: registry.rocket.chat/rocketchat/rocket.chat
  tag: latest

mongodb:
  enabled: true  #For test purposes, a single mongodb pod is deployed, consider an external MongoDB cluster for production environments
  auth:
    passwords:
      - rocketchat
    rootPassword: rocketchatroot

microservices:
  enabled: false  #This must be set to false for a monolithic deployment
host: rocket-chat
ingress:
  enabled: true
  ingressClassName: nginx  # State the ingress controller that is installed in the K8s cluster

' > /tmp/rocketchat-values.yaml


helm install rocketchat -f /tmp/rocketchat-values.yaml rocketchat/rocketchat
curl localhost:3000
echo "rocketchat server installed"
