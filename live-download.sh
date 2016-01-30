#!/usr/bin/env bash -eu

cd `dirname $0`
find . -not -path './.git/*' -not -path './node_modules/*' | entr -r rsync -aiz --exclude .git --exclude node_modules . xmas-pi:ha
