#!/usr/bin/env bash
set -eu

TMP=$(mktemp /tmp/.mm.XXXXXX)
clean() { rm -f ${TMP}; }
trap clean EXIT

git checkout master
git branch -l|grep pull-branch|xargs -n1 git branch -D

randomword () {
	set -x
	local total randomn
	total=$(wc -l /usr/share/dict/words|cut -d " " -f1)
	randomn=$(jot -r 1 1 ${total})
	sed "${randomn}q;d" /usr/share/dict/words
}

word=$(randomword)
branch=pull-branch-${word}
git checkout -b $branch master

echo $word > ci

GIF_KEYWORDS=work
set +e
i=0
while true;do
    randomgif=$(curl -s -L "https://api.giphy.com/v1/gifs/search?api_key=dc6zaTOxFJmzC&q=${GIF_KEYWORDS}&rating=g&limit=100"|python -c "import json, random, sys;j = json.loads(sys.stdin.read());print(j['data'][random.randint(0,99)]['images']['fixed_height_downsampled']['url'])")
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


git add ci
git commit -F ${TMP} ci

hub pull-request -F ${TMP} -p -b master -l CI

git checkout master
