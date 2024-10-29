#!/bin/bash
#!/bin/bash
#
# Pull Charts for an Air-Gapped Kubernetes system.  This will assume you are
# using Helm Charts as the packaging solution.
#
# interesting https://docs.k3s.io/installation/registry-mirrors

set -ebpf

# Helm Chart Versions
export KEYCLOAK_VERSION=18.5.0
export VAULT_VERSION=0.27.0
export METALLB_VERSION=0.14.3

# IronBank / Registry One Links
# - KeyCloak: registry1.dso.mil/ironbank/opensource/keycloak/keycloak:23.0.5
# - Hashicorp Vault: registry1.dso.mil/ironbank/hashicorp/vault:1.13.13

######  NO MOAR EDITS #######
export RED='\x1b[0;31m'
export GREEN='\x1b[32m'
export BLUE='\x1b[34m'
export YELLOW='\x1b[33m'
export NO_COLOR='\x1b[0m'

export PATH=$PATH:/usr/local/bin

# el version
export EL=$(rpm -q --queryformat '%{RELEASE}' rpm | grep -o "el[[:digit:]]")

#better error checking
command -v skopeo >/dev/null 2>&1 || { echo "$RED" " ** skopeo was not found. Please install. ** " "$NORMAL" >&2; exit 1; }

umask 0022

################################# mirror ################################
function mirror() {
  echo - Update Repos
  helm repo update > /dev/null 2>&1

  echo - Get Images
  cd /opt/mirror/images/

  # echo - MetalLB image list
  # helm template /opt/mirror/helm/metallb-$METALLB_VERSION.tgz | awk '$1 ~ /image:/ {print $2}' | sed s/\"//g > metallb/metallb-images.txt
  # echo - keycloak image list
  # helm template /opt/mirror/helm/keycloak-$KEYCLOAK_VERSION.tgz | awk '$1 ~ /image:/ {print $2}' | sed s/\"//g > keycloak/keycloak-images.txt
  # echo - vault image list
  # helm template /opt/mirror/helm/vault-$VAULT_VERSION.tgz | awk '$1 ~ /image:/ {print $2}' | sed s/\"//g > vault/vault-images.txt

  echo - skopeo - MetalLB
  for i in $(cat metallb/metallb-images.txt); do
    skopeo copy --additional-tag $i docker://"$i" docker-archive:metallb/"$(echo "$i"| awk -F/ '{print $3}'|sed 's/:/_/g')".tar:"$(echo "$i"| awk -F/ '{print $3}')" > /dev/null 2>&1
  done

  echo - skopeo - keycloak
  for i in $(cat keycloak/keycloak-images.txt); do 
    skopeo copy --additional-tag $i docker://"$i" docker-archive:keycloak/"$(echo "$i"| awk -F/ '{print $3}'|sed 's/:/_/g')".tar:"$(echo "$i"| awk -F/ '{print $3}')" > /dev/null 2>&1
  done  

  echo - skopeo - vault
  for i in $(cat vault/vault-images.txt); do 
    skopeo copy --additional-tag $i docker://"$i" docker-archive:vault/"$(echo "$i"| awk -F/ '{print $2}'|sed 's/:/_/g')".tar:"$(echo "$i"| awk -F/ '{print $2}')" > /dev/null 2>&1
  done  

  cd /opt/mirror
  echo - compress mirror archive

}

################################# deploy ################################
# function deploy() {

# }

################################# metallb ################################
function metallb () {
  # deploy metallb with local helm/images
  echo - deploying metallb
  helm upgrade -i metallb /opt/rancher/helm/metallb-$LONGHORN_VERSION.tgz --namespace metallb-system --create-namespace --set frr.enabled=false --set controller.image.repository=localhost:5000/ironbank/metallb/controller --set speaker.images.repository=localhost:5000/ironbank/metallb/speaker --set frr.image.repository=localhost:5000/quay.io/frrouting/frr:8.5.2
}

################################# usage #################################
function usage () {
  echo ""
  echo "-------------------------------------------------"
  echo ""
  echo " Usage: $0 mirror"
  echo ""
  echo " $0 mirror # download and create the monster TAR "
  echo " $0 deploy # deploy images to airgap registry"
  echo ""
  echo "-------------------------------------------------"
  echo ""
  echo "Steps:"
  echo " - UNCLASS - $0 mirror"
  echo " - Move the ZST file across the air gap"
  echo " - On 1st control node run cd /opt/rancher; $0 deploy"
  echo " - Wait and watch for errors"
  echo ""
  echo "-------------------------------------------------"
  echo ""
  exit 1
}

case "$1" in
        mirror ) mirror;;
        *) usage;;
esac
