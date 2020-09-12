#!/bin/bash

d0="$(dirname "$(readlink -f -- "$0")")"

source "$d0/common.sh"

mkdirTmp
findPy3

d1="/home/course/cs2105/autotest/a1-ay2021s1"
py37="/usr/local/Python-3.7/bin/python3"

genRandPorts() {
  gawk 'BEGIN{ srand(); print int(rand()*(65534-1025))+1025; print int(rand()*(65534-1025))+1025; print int(rand()*(65534-1025))+1025 }'
}

nCases=$(PYTHONPATH="$d1" "$py37" -c "from cases1 import *; print(len(casegrps))")

#nCases=$(cat "$d1/cases1.py" <(echo 'print(len(casegrps))') | "$py3")

caseA() {
  local i="$1"
  let i=i
  [[ "$i" -le 0 ]] && i=1
  #
  echo
  tput smul; tput bold; echo "   Test Case ${i}a -- one connection per request   "; tput sgr0
  let i--
	nreqs=$(PYTHONPATH="$d1" "$py37" -c "from cases1 import *; print(len(casegrps[$i])//2)")
	#echo "$nreqs"
  #nreqs=$(nCases=$(cat "$d1/cases1.py" <(echo "print(len(casegrps[$i])//2)") | "$py3"))
  isPassed=1
  # try to launch server
  for p0 in $(genRandPorts); do
    port="$p0"
    rm -f "$tmpdir/s-err"
    (eval exec "$evalcmd" $port 2> "$tmpdir/s-err") &
    spid="$!"
    echo $spid >> "$tmpdir/pids"
    #
    "$py3" -c 'import time; time.sleep(0.3)'
    if ! kill -0 $spid 2>/dev/null; then
      port=""
      continue
    fi
    #
    rm -f "$tmpdir/c0-err"
    PYTHONPATH="$d1" "$py37" -c "import client" "$port" "$i" 0 0 2> "$tmpdir/c0-err"
    rtn="$?"
    if [[ "$rtn" == 1 ]]; then
      port=""
      kill -9 $spid 2>/dev/null
      continue
    else
      break
    fi
  done
  if [[ -z "$port" ]]; then
    tput rev; echo "Error: cannot allocate a port number for your server. Try again later?"; tput sgr0
    cat "$tmpdir/s-err"
    exit 1
  fi
  if [[ "$rtn" -gt 1 ]]; then
    isPassed=0
    kill -9 $spid 2>/dev/null
    tput rev
    printf "%s" "Failed: "
    cat "$tmpdir/c0-err"
    tput sgr0
    cat "$tmpdir/s-err"
    continue
  fi
  for j in $( seq 1 $((nreqs-1)) ); do
		echo 'seq' $j
    clog="$tmpdir/c$j-err"
    rm -f "$clog"
    PYTHONPATH="$d1" "$py37" -c "import client" "$port" "$i" "$j" 0 2> "$clog"
    rtn="$?"
    if ! kill -0 $spid 2>/dev/null || [[ "$rtn" -gt 1 ]]; then
      isPassed=0
      kill -9 $spid 2>/dev/null
      tput rev
      printf "%s" "Failed: "
      cat "$clog"
      tput sgr0
      cat "$tmpdir/s-err"
      continue
    fi
  done
  if [[ "$isPassed" == 1 ]]; then
    tput rev; echo "Passed!"; tput sgr0
  fi
}

caseBCD() {
  local i="$1"
  let i=i
  [[ "$i" -le 0 ]] && i=1
  local ver="$2"
  if [[ "$ver" == b ]]; then
    local cver=''
    casedescr='persistent connection, batched'
  elif [[ "$ver" == c ]]; then
    local cver='3'
    casedescr='persistent connection, ping-pong'
  else
    local cver='2'
    i=$(( nCases+1 ))
    casedescr='intermittent connection'
  fi
  #
  echo
  tput smul; tput bold; echo "   Test Case ${i}$ver -- $casedescr   "; tput sgr0
  let i--
  # try to launch server
  for p0 in $(genRandPorts); do
    port="$p0"
    rm -f "$tmpdir/s-err"
    (eval exec "$evalcmd" $port 2> "$tmpdir/s-err") &
    spid="$!"
    echo $spid >> "$tmpdir/pids"
    #
    "$py3" -c 'import time; time.sleep(0.3)'
    if ! kill -0 $spid 2>/dev/null; then
      port=""
      continue
    fi
    #
    rm -f "$tmpdir/c-err"
    PYTHONPATH="$d1" "$py37" -c "import client${cver}" "$port" "$i" -1 0 2> "$tmpdir/c-err"
    rtn="$?"
    if [[ "$rtn" == 1 ]]; then
      port=""
      kill -9 $spid 2>/dev/null
      continue
    else
      break
    fi
  done
  if [[ -z "$port" ]]; then
    tput rev; echo "Error: cannot allocate a port number for your server. Try again later?"; tput sgr0
    cat "$tmpdir/s-err"
    exit 1
  fi
  if [[ "$rtn" == 0 ]]; then
    tput rev; echo "Passed!"; tput sgr0
  else
    tput rev
    printf "%s" "Failed: "
    cat "$tmpdir/c-err"
    tput sgr0
    cat "$tmpdir/s-err"
#     echo
#     tput bold; echo "Please try to pass this test case first before proceeding, as later ones are more difficult."; tput sgr0
#     exit 2
  fi
}


######################3

if [[ -z "$arg1" ]]; then
  for ii in $(seq 1 "$nCases"); do
    caseA $ii
    caseBCD $ii b
    caseBCD $ii c
  done
  caseBCD
else
  slen=${#arg1}
  tid=${arg1::((slen-1))}
  lastc=${arg1:((slen-1))}
  if [[ "$arg1" == $(( nCases+1 )) ]]; then
    caseBCD
  elif [[ "$lastc" == a ]]; then
    caseA $tid
  elif [[ "$lastc" == b ]]; then
    caseBCD $tid b
  elif [[ "$lastc" == c ]]; then
    caseBCD $tid c
  elif grep '[0-9]' <(echo $lastc) >/dev/null; then
    caseA $arg1
    caseBCD $arg1 b
    caseBCD $arg1 c
  else
    echo "Unknown test case: \"$arg1\""
  fi
fi
