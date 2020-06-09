#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Author: Chmouel Boudjnah <chmouel@chmouel.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
import http.client
import json
import subprocess
import sys
ALLOWED_REPOS = ["chmouel/scratchpad"]


def reqit(url, method, data=None, successmsg=None):
    conn = http.client.HTTPSConnection("api.github.com")
    token = subprocess.Popen(
        ["git", "config", "--get", "github.oauth-token"],
        stdout=subprocess.PIPE).communicate()[0].strip().decode()

    if data:
        data = json.dumps(data)

    conn.request(
        method,
        url,
        body=data,
        headers={
            "User-Agent": "OpenShift CI Pipeline Commenter",
            "Authorization": "Bearer " + token,
        })

    resp = conn.getresponse()
    if not str(resp.status).startswith("2"):
        print("Error: %d" % (resp.status))
        print(resp.read())
        raise Exception("Error running GitHUB URL")
    else:
        return resp.read()


cmdline = ""
repo = subprocess.Popen(
    ["/bin/sh", "-c", "git remote get-url origin"],
    stdout=subprocess.PIPE).communicate()[0].strip().decode()
repo = repo.replace("git@github.com:", "")
repo = repo.replace("https://github.com/", "")

if repo not in ALLOWED_REPOS:
    print(f"{repo} not in {ALLOWED_REPOS}")
    sys.exit(1)

pullreqs = json.loads(
    reqit(
        "https://api.github.com/repos/chmouel/scratchpad/pulls",
        "GET",
    ))

if not pullreqs:
    print("no pullreq open for " + repo)
    sys.exit(0)

for pull in pullreqs:
    print("Closing: " + pull['url'])
    reqit(pull['url'], "PATCH", data={"state": "closed"})

# conn = http.client.HTTPSConnection("api.github.com")
# data = {"state": "closed"}
# r = conn.request(
#     "PATCH",
#     comment_url,
#     body=json.dumps(data),
#     headers={
#         "User-Agent": "OpenShift CI Pipeline Commenter",
#         "Authorization": "Bearer " + os.environ["GITHUBTOKEN"],
#     })
# r1 = conn.getresponse()
# if not str(resp.status).startswith("2"):
#     print("Error: %d" % (resp.status))
#     print(resp.read())
# else:
#     print("GIthub PR #" + os.environ["PR"] + " has been closed!")
