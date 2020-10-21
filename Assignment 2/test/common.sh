
pwd0="$(pwd)"

finame="Alice"
finame2="Bob"

arg1="$1"

tput smul; tput bold; echo "   Preparation   "; tput sgr0

# Checking OS
if ! grep '^SunOS sunfire0.comp.nus.edu.sg' < <(uname -a) >/dev/null; then
  echo "Warn: not running on sunfire!"
fi

# compile if necessary

findPy3() {
  if [[ ! -z "$py3" ]]; then
    return
  fi
  py3="/usr/local/Python-3.7.0/bin/python3"
  if [[ ! -x "$py3" ]]; then
    py3="$(which python3)"
    if [[ ! -x "$py3" ]]; then
      echo "Error: cannot find python3"
      py3=""
      return 1
    else
      echo "Warn: using python3 @ $py3"
    fi
  fi
}

mkdirTmp() {
  if [[ ! -z "$tmpdir" ]]; then
    return
  fi
  tmpdir="$(mktemp -d)"
  echo "Info: created temporary folder $tmpdir"
  trap "kill -9 \$(cat \"$tmpdir/pids\" 2>/dev/null) 2>/dev/null; rm -rf \"$tmpdir\"; exit" EXIT INT TERM KILL
}
progCompile() {
  local fname="$1"
  for ext in py java c cpp; do
    srcpath0="$fname.$ext"
    if [[ -f "$srcpath0" ]]; then
      srcpath="$srcpath0"
      srclang="$ext"
    fi
  done
  if [[ -z "$srcpath" ]]; then
    echo "Error: cannot find source file for $fname"
    exit 1
  fi
  echo "Info: found source file $srcpath"
  case $srclang in
    py)
      if ! findPy3; then
        exit 2
      fi
      evalcmd="\"$py3\" \"$pwd0/$srcpath\""
      ;;
    java)
      mkdirTmp
      echo "Info: copying $srcpath to $fname.java in temp folder"
      cp "$srcpath" "$tmpdir/$fname.java"
      echo "Info: compiling $fname.java ..."
      javac -d "$tmpdir" "$tmpdir/$fname.java" || echo
      if [[ -f "$tmpdir/$fname.class" ]]; then
        echo "Info: successfully compiled $fname.java"
      else
        echo "Error: cannot compile $fname.java"
        exit 3
      fi
      evalcmd="java -cp \"$tmpdir\" $fname"
      ;;
    c)
      mkdirTmp
      echo "Info: compiling $srcpath ..."
      gcc "$srcpath" -o "$tmpdir/$fname" -lz -lsocket -lnsl || echo
      if [[ -f "$tmpdir/$fname" ]]; then
        echo "Info: successfully compiled $srcpath"
      else
        echo "Error: cannot compile $srcpath"
        exit 3
      fi
      evalcmd="$tmpdir/$fname"
      ;;
    cpp)
      mkdirTmp
      echo "Info: compiling $srcpath ..."
      g++ "$srcpath" -o "$tmpdir/$fname" -lz -lsocket -lnsl || echo
      if [[ -f "$tmpdir/$fname" ]]; then
        echo "Info: successfully compiled $srcpath"
      else
        echo "Error: cannot compile $srcpath"
        exit 3
      fi
      evalcmd="$tmpdir/$fname"
      ;;
  esac
}

progCompile "$finame"
acmd="$evalcmd"
progCompile "$finame2"
bcmd="$evalcmd"

evalRun() {
  mkdirTmp
  local rid="$1"
  shift 1
  eval "$@" > "$tmpdir/$rid.stdout"
}

launchTest() {
  cdir="$d0/cases"
  let pcases=0
  if [[ -z "$arg1" ]]; then
    let cid=1
    while [[ -f "$cdir/$cid.in" ]]; do
      echo "-- Test Case $cid --"
      "$1" "$cid"
      let cid++
    done
    echo "-- Summary --"
    echo "Passed $pcases out of $((cid-1)) cases."
  else
    cid="$arg1"
    if [[ -f "$cdir/$cid.in" ]]; then
      echo "-- Test Case $cid --"
      "$1" "$cid"
    else
      echo "Error: invalid case id \"$cid\""
      exit 4
    fi
  fi
}
