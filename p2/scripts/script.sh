
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
GREEN='\033[1;32m'
RED='\033[1;31m'
RESET='\033[0m'

CLUSTER_NAME="my-cluster"

print_header() {
  local message="$1"
  local length=${#message}
  local border=$(printf '─%.0s' $(seq 1 $((length + 8))))

  echo -e "${MAGENTA}┌${border}┐${RESET}"
  echo -e "${MAGENTA}│    ${CYAN}${message}${MAGENTA}    │${RESET}"
  echo -e "${MAGENTA}└${border}┘${RESET}"
}

handle_error() {
  echo -e "${RED}✖ ERROR: $1${RESET}"
  exit 1
}

status_msg() {
  echo -e "${GREEN}✔ $1${RESET}"
}



print_header "Updating the system"
sudo apt update -y && sudo apt upgrade -y || handle_error "Failed to update the system"
print_header "Checking if curl is installed"
command -v curl
if [ $? -eq 0 ]; then
  status_msg "curl is already installed"
else
  sudo apt install curl -y || handle_error "Failed to install curl"
fi

print_header "Checking if k3s is installed"
command -v k3s
if [ $? -eq 0 ]; then
  status_msg "k3s is already installed"
else
  curl -sfL https://get.k3s.io | sh -s - --flannel-iface eth1 || handle_error "Failed to install k3s"
fi

print_header "Adding alias for kubectl"
echo "alias k='kubectl'" >> ~/.bashrc
source ~/.bashrc

print_header "Applying deployment manifests"
cd /tmp/deployment || handle_error "Directory /tmp/deployment not found"
sudo kubectl apply -f . || handle_error "Failed to apply deployment manifests"

print_header "Waiting for all pods to be in running state"
sleep 10s ; sudo kubectl wait --for=condition=Ready pods --all --timeout=300s || handle_error "Not all pods are in running state"


print_header "Applying service manifests"
cd /tmp/services || handle_error "Directory /tmp/services not found"
sudo kubectl apply -f . || handle_error "Failed to apply service manifests"

print_header "Waiting for all services to be in running state"
sudo  kubectl wait --for=jsonpath='{.spec.selector.app}' -f /tmp/services/ --timeout=300s || handle_error "Not all services are in running state"


print_header "Applying ingress manifests"
cd /tmp/ingress || handle_error "Directory /tmp/ingress not found"
sudo kubectl apply -f . || handle_error "Failed to apply ingress manifests"

print_header "Script Complete"
var=$(sudo kubectl get svc -n kube-system --kubeconfig /etc/rancher/k3s/k3s.yaml)
echo -e "${GREEN} $var ${RESET}"

