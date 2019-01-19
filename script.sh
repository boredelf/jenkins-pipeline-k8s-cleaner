#!/bin/bash

expirationLabel='expiresAt'

echo -n "Looking for namespaces labeled with \"${expirationLabel}\"... "
namespaces=($(kubectl get ns -l ${expirationLabel} 2> /dev/null | tail -n +2 | awk '{print $1}'))
if [[ ${#namespaces[@]} -eq 0 ]];
   then echo 'no labeled namespaces found.'
   else echo "${#namespaces[@]} labeled namespace(s) found."
fi

today=$(date +%Y%m%d)
expiredNamespaces=()
echo -n 'Looking for expired ones... '
for ns in ${namespaces[@]}; do
   expirationDate=$(kubectl get ns ${ns} --template='{{.metadata.labels.expiresAt}}' | tr -d '-')
   if [[ ${expirationDate} -le ${today} ]]; then expiredNamespaces+=(${ns}); fi
done

echo "found ${#expiredNamespaces[@]} expired namespace(s)."
for ens in ${expiredNamespaces[@]}; do
   deleteSuccessful=$(kubectl delete ns ${ens} 2>&1)
   echo -n "Deleting \"${ens}\"... "
   if [[ ! ${deleteSuccessful} =~ ^Error ]];
      then echo 'deleted.'
      else echo "not deleted. Stderr: ${deleteSuccessful}"
   fi
done

# TODO: Delete Docker images (using branch's name, extracted from namespace) from Nexus?
# The namespace should use '--' to separate its name from branch postfix, as follow: namespace--branch-name
