#!/bin/bash
while getopts "r" o; do
    case "${o}" in
        r)
            recreate=yes
            ;;
        *)
            echo "Invalid option"; exit 1;
            ;;
    esac
done
shift $((OPTIND-1))

function k() {
    for file in $@;do
        [[ -n ${recreate} ]] && {
            kubectl delete -f ${file}
        }
        kubectl apply -f ${file}
    done
}

function waitfor() {
    local thing=${1}
    local cnt=0
    echo -n "Waiting for ${thing}: "
    while true;do
        [[ ${i} == 60 ]] && {
            echo "failed.. cannot wait any longer"
            exit 1
        }
        kubectl get ${thing} 2>/dev/null && break
        (( i++ ))
        echo -n "."
        sleep 10
    done
    echo "done."
}

function openshift_expose_service () {
	local s=${1}
    local n=${2}
    [[ -n ${recreate} ]] && oc delete route ${s} >/dev/null
    [[ -n ${n} ]] && n="--hostname=${n}"
	oc expose service ${s} ${n} && \
        oc apply -f <(oc get route ${s}  -o json |jq -r '.spec |= . + {tls: {"insecureEdgeTerminationPolicy": "Redirect", "termination": "edge"}}') >/dev/null && \
        echo "https://$(oc get route ${s} -o jsonpath='{.spec.host}')"
}

function create_secret() {
    local s=${1}
    local literal=${2}
    [[ -n ${recreate} ]] && kubectl delete secret ${s}
    kubectl get secret ${s} >/dev/null 2>/dev/null || kubectl create secret generic ${s} --from-literal ${literal}
}

service=el-scratchpad-listener-interceptor
hostname=webhook-scratchpad.apps.chmouel.devcluster.openshift.com

k pipeline.yaml
k triggers/*yaml
k tasks/*yaml
waitfor service/${service}
openshift_expose_service ${service} ${hostname}
create_secret github "token=$(git config --get github.oauth-token)"
