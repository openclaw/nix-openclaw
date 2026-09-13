#!/bin/sh
set -eu
unset OPENCLAW_USER
hello-world > default-greeting.txt
grep -Fx 'Hello, human. I am a very serious assistant.' default-greeting.txt
OPENCLAW_USER='plugin fixture' hello-world > configured-greeting.txt
grep -Fx 'Hello, plugin fixture. I am a very serious assistant.' configured-greeting.txt
printf 'example plugin CLI and host-system contract: PASS\n'
