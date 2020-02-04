#!/usr/bin/env bash
set -eux
TMP=$(mktemp /tmp/.mm.XXXXXX)
clean() { rm -f ${TMP}; }
trap clean EXIT
dt=$(date "+%Y%m%d-%Hh%MS%S")
PR_AUTO_CLOSE=${PR_AUTO_CLOSE:-}

[[ -n ${PR_AUTO_CLOSE} && -x ./close-all-pr.py ]] && ./close-all-pr.py

python=python3
[[ -x /usr/libexec/platform-python ]] && python=/usr/libexec/platform-python

git checkout master
git branch -l|grep pull-branch|xargs -n1 git branch -D

branch=pull-branch-${dt}
git checkout -b $branch master

echo $dt > CI

GIF_KEYWORDS=work
set +e
i=0
while true;do
    randomgif=$(curl -s -L "https://api.giphy.com/v1/gifs/search?api_key=dc6zaTOxFJmzC&q=${GIF_KEYWORDS}&rating=g&limit=100"|${python} -c "import json, random, sys;j = json.loads(sys.stdin.read());print(j['data'][random.randint(0,len(j['data']))]['images']['fixed_height_downsampled']['url'])")
    [[ -n ${randomgif} ]] && break
    [[ $i == 9 ]] && {
        randomgif="https://i.giphy.com/media/hOzfvZynn9AK4/200_d.gif"
        break
    }
    (( i+=1 ))
    sleep 1
done
set -e

cat > ${TMP} <<EOF
[TEST] OpenShift Pipeline CI

![a funny gif, while you wait](${randomgif})

EOF


git add CI
git commit -F ${TMP} CI

hub pull-request -F ${TMP} -p -b master -l CI

git checkout master
