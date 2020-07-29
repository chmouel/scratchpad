#!/bin/bash
SERVICE=el-tknaac-listener-interceptor
HOSTNAME=tektonic.apps.chmouel.devcluster.openshift.com
TARGET_NAMESPACE=prcheck
set -ex

while getopts "rn:" o; do
    case "${o}" in
        n)
            TARGET_NAMESPACE=${OPTARG};
            ;;
        r)
            recreate=yes
            ;;
        *)
            echo "Invalid option"; exit 1;
            ;;
    esac
done
shift $((OPTIND-1))

oc get project ${TARGET_NAMESPACE} >/dev/null 2>/dev/null || oc new-project ${TARGET_NAMESPACE}

function k() {
    for file in $@;do
        [[ -n ${recreate} ]] && {
            kubectl -n ${TARGET_NAMESPACE} delete -f ${file}
        }
        kubectl -n ${TARGET_NAMESPACE} apply -f ${file}
    done
}

function waitfor() {
    local thing=${1}
    local cnt=0
    echo -n "Waiting for ${thing}: "
    while true;do
        [[ ${cnt} == 60 ]] && {
            echo "failed.. cannot wait any longer"
            exit 1
        }
        kubectl -n ${TARGET_NAMESPACE} get ${thing} 2>/dev/null && break
        (( cnt++ ))
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
    kubectl -n ${TARGET_NAMESPACE} get secret ${s} >/dev/null 2>/dev/null || \
        kubectl -n ${TARGET_NAMESPACE} create secret generic ${s} --from-literal ${literal}
}

k pipeline.yaml
k triggers/*yaml
k tasks/*yaml
for i in tasks/*/;do
    [[ -d $i ]] || continue # whateva
    pushd ${i} && {
		# https://blog.chmouel.com/2020/07/28/tekton-yaml-templates-and-script-feature/
		~/GIT/perso/chmouzies/work/tekton-script-template.sh ${i}
    } && popd
done

create_secret github "token=$(git config --get github.oauth-token)"

waitfor service/${SERVICE}
openshift_expose_service ${SERVICE} ${HOSTNAME}
