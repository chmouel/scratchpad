#!/usr/bin/env bash
set -eu

TMP=$(mktemp /tmp/.mm.XXXXXX)
clean() { rm -f ${TMP}; }
trap clean EXIT

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

set +e
i=0
while true;do
    randomgif=$(curl -s -L 'https://api.giphy.com/v1/gifs/search?api_key=dc6zaTOxFJmzC&q=happy&rating=g&limit=100'|python -c "import json, random, sys;j = json.loads(sys.stdin.read());print(j['data'][random.randint(0,99)]['images']['fixed_height_downsampled']['url'])")
    [[ -n ${randomgif} ]] && break
    [[ $i == 9 ]] && {
        randomgif="https://media2.giphy.com/media/12PIT4DOj6Tgek/200_d.gif?cid=e1bb72ff0d9684e5c8ec6e185c0c82366e11d9151d141280&rid=200_d.gif"
        break
    }
    (( i+=1 ))
    sleep 1
done
echo ${randomgif}
set -e

cat > ${TMP} <<EOF
[TEST] OpenShift Pipeline CI

![and now for something different](${randomgif})
EOF


git add ci
git commit -F ${TMP} ci

hub pull-request -F ${TMP} -p -b master -l CI

git checkout master
