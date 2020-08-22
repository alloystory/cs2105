#!/bin/bash

d0="$(dirname "$(readlink -f -- "$0")")"

source "$d0/common.sh"

run() {
  local cid="$1"
  inf="$cdir/$cid.in"
  #
  evalRun "$cid" "$evalcmd" "$inf"
  diff "$tmpdir/$cid.stdout" "$cdir/$cid.out" \
    | awk '{if (NR == 1) print "Failed: your output differs from the reference answer."; print $0}'
  if [[ ${PIPESTATUS[0]} == "0" ]]; then
    echo "Passed!"
    let pcases++
  fi
}

launchTest run
