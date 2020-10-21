#!/bin/bash

d0="$(dirname "$(readlink -f -- "$0")")"

source "$d0/common.sh"

mkdirTmp
findPy3

genRandPorts() {
  gawk 'BEGIN{ srand(); print int(rand()*(65534-1025))+1025; print int(rand()*(65534-1025))+1025; print int(rand()*(65534-1025))+1025 }'
}


run() {
  local cid="$1"
  local ver="$2"
  inf="$cdir/$cid.in"
  port=""
  port2=""
  
  if [[ "$ver" == a ]]; then
    params="0 0 0 0"
    casedesc="No corruption/loss"
  fi
  if [[ "$ver" == b ]]; then
    params="0.3 0 0.3 0"
    casedesc="Corruption only"
  fi
  
  if [[ "$ver" == c ]]; then
    params="0 0.3 0 0.3"
    casedesc="Loss only"
  fi
  
  if [[ "$ver" == d ]]; then
    params="0.2 0.2 0.2 0.2"
    casedesc="Corruption and loss"
  fi
  
	export TERM=xterm
  tput smul; tput bold;
  echo "-- Test Case $cid$ver - $casedesc --"
  tput sgr0;
  
  for p0 in $(genRandPorts); do
    port="$p0"
    rm -f "$tmpdir/$cid.stdout" 2>/dev/null
    
    (eval exec "$bcmd" $port > "$tmpdir/$cid.stdout" 2> "$tmpdir/$cid.stderr") &
    bpid="$!"
    echo $bpid >> "$tmpdir/pids"
    #
    sleep 1
    if ! kill -0 $bpid 2>/dev/null; then
      port=""
      continue
    fi
    echo "Bob running"
    #
    tries=0
    port2=$port
    inc=1
    while [[ $tries -lt 3 ]]; do
      port2=$(( $port2 + $inc ))
      inc=$(( $inc + 2 ))
      tries=$(( $tries + 1))
      rm -f "$tmpdir/c0-err" 2>/dev/null
      
      rm -f "$tmpdir/un-err" 2>/dev/null
      (eval exec java -cp "\"$d0\" UnreliNET" "$params" "$port2" "$port" > "$tmpdir/un-err" 2>&1) &
      upid="$!"
      echo $upid >> "$tmpdir/pids"
      #
      sleep 1
      if ! kill -0 $upid 2>/dev/null; then
        port2=""
        continue
      fi
      echo "UnreliNET running"
      #
      rm -f "$tmpdir/a-log" 2>/dev/null
      echo "Starting Alice now"
      (eval exec "$acmd" $port2 < "$inf") &
      apid="$!"
      echo $apid >> "$tmpdir/pids"
      break 2
    done
  done
  
  if [[ -z "$port" ]]; then
    tput rev;
    echo "Error: could not start up Bob, perhaps due to conflicting port numbers?"
    kill -9 $bpid 2>/dev/null
    kill -9 $upid 2>/dev/null
    kill -9 $apid 2>/dev/null
    tput sgr0;
    return
  fi
  if [[ -z "$port2" ]]; then
    tput rev;
    echo "Error: could not start up UnreliNET, perhaps due to conflicting port numbers?"
    kill -9 $bpid 2>/dev/null
    kill -9 $upid 2>/dev/null
    kill -9 $apid 2>/dev/null
    tput sgr0;
    return
  fi
  
  loops=0
  added=0
  
  iSize="$(wc -c "$inf" | awk '{print $1}')"
  while [[ $loops -lt 10 ]]; do
    if ! kill -0 $apid 2>/dev/null; then
      echo "Alice finished executing"
      break
    fi
    
    sleep 1
    loops=$(($loops + 1))
    if [[ $(($loops % 5)) -eq 0 ]]; then
      echo "$loops seconds elapsed"
    fi
  done

  kill -9 $apid 2>/dev/null
  kill -9 $upid 2>/dev/null
  #kill -9 $bpid 2>/dev/null
 
  # terminate bob in a softest possible way to prevent loss of output
  sleep 1
  kill -SIGINT "$bpid" 2>/dev/null
  if ps -p "$bpid" >/dev/null; then
    sleep 1
    kill -SIGTERM "$bpid" 2>/dev/null
    if ps -p "$bpid" >/dev/null; then
      sleep 1
      kill -9 "$bpid" 2>/dev/null 
    fi
  fi

  if [[ $added -ne 1 ]]; then
    diff "$tmpdir/$cid.stdout" "$inf" >/dev/null
    res=${PIPESTATUS[0]}
    tput rev;
    if [[ $res == "0" ]];
    then
      echo "Passed!"
    else
      cat "$tmpdir/$cid.stderr"
      echo "Failed:"
      oSize="$(wc -c "$tmpdir/$cid.stdout" | awk '{print $1}')"
      if [[ $oSize -lt $iSize ]];
      then
        echo "Output size smaller than input size"
        echo "Output size: $oSize"
        echo "Input size: $iSize"
      elif [[ $oSize -gt $iSize ]];
      then
        echo "Output size larger than input size"
        echo "Output size: $oSize"
        echo "Input size: $iSize"
      else
        echo "Output and input sizes match, but contents mismatch"
      fi
    fi
    tput sgr0;
  fi
  
  
}

eval javac "$d0/UnreliNET.java"

cdir="$d0/cases"
if [[ -z "$arg1" ]]; then
  let caseid=1
  while [[ -f "$cdir/$caseid.in" ]]; do
    run "$caseid" a
    run "$caseid" b
    run "$caseid" c
    run "$caseid" d
    let caseid++
  done
else
  slen=${#arg1}
  tid=${arg1::((slen-1))}
  lastc=${arg1:((slen-1))}
  if [[ "$lastc" == a ]]; then
    run $tid a
  elif [[ "$lastc" == b ]]; then
    run $tid b
  elif [[ "$lastc" == c ]]; then
    run $tid c
  elif [[ "$lastc" == d ]]; then
    run $tid d
  elif grep '[0-9]' <(echo $lastc) >/dev/null; then
    run $arg1 a
    run $arg1 b
    run $arg1 c
    run $arg1 d
  else
    echo "Unknown test case: \"$arg1\""
  fi
fi
