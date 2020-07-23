cd $(dirname $(readlink -f ${0}))
curl -k -H 'content-type: application/json' -H 'User-Agent: GitHub-Hookshot/eab82ad' -H 'X-GitHub-Event: pull_request' -H 'X-GitHub-Delivery: c005e900-ccd3-11ea-895a-26e77176b05c' -X POST -d@propen.json	$(echo https://$(oc get route $(oc get service -o name|fzf -1|cut -d/ -f2) -o jsonpath='{.spec.host}'))
