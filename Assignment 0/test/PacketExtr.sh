#!/bin/bash

d0="$(dirname "$(readlink -f -- "$0")")"

source "$d0/common.sh"

mkdirTmp
findPy3

run() {
  local cid="$1"
  inf="$cdir/$cid.in"
  "$py3" "$d0/iserv.py" "$cdir/$cid" >(evalRun "$cid" "$evalcmd") "$tmpdir/$cid.stdout"
  rtn="$?"
  #
  cmp "$tmpdir/$cid.stdout" "$cdir/$cid.out" \
    | awk '{if (NR == 1) print "Failed: your output differs from the reference answer."; print $0}'
  if [[ "${PIPESTATUS[0]}" == 0 ]]; then
    if [[ "$rtn" == 0 ]]; then
      echo "Passed!"
      let pcases++
    else
      echo "Info: timed out, but the final output is correct."
    fi
  fi
}

launchTest run
