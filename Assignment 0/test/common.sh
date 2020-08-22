
pwd0="$(pwd)"

fname="$(basename "$0")"
fname="${fname%.*}"

arg1="$1"

echo "-- Preparation --"
# looking for source file
for ext in py java c cpp; do
  srcpath0="$fname.$ext"
  if [[ -f "$srcpath0" ]]; then
    srcpath="$srcpath0"
    srclang="$ext"
    break
  fi
done
if [[ -z "$srcpath" ]]; then
  echo "Error: cannot find source file for $fname"
  exit 1
fi
echo "Info: found source file $srcpath"

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
#   echo "Info: created temporary folder $tmpdir"
  trap "rm -rf \"$tmpdir\"" EXIT INT TERM KILL
}

case $srclang in
  py)
    if ! findPy3; then
      exit 2
    fi
    evalcmd="\"$py3\" \"$pwd0/$srcpath\""
    ;;
  java)
    mkdirTmp
    echo "Info: compiling $srcpath ..."
    javac -d "$tmpdir" "$srcpath" || echo
    if [[ -f "$tmpdir/$fname.class" ]]; then
      echo "Info: successfully compiled $srcpath"
    else
      echo "Error: cannot compile $srcpath"
      exit 3
    fi
    evalcmd="java -cp \"$tmpdir\" $fname"
    ;;
  c)
    mkdirTmp
    echo "Info: compiling $srcpath ..."
    gcc "$srcpath" -o "$tmpdir/$fname" -lz || echo
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
    g++ "$srcpath" -o "$tmpdir/$fname" -lz || echo
    if [[ -f "$tmpdir/$fname" ]]; then
      echo "Info: successfully compiled $srcpath"
    else
      echo "Error: cannot compile $srcpath"
      exit 3
    fi
    evalcmd="$tmpdir/$fname"
    ;;
esac 

evalRun() {
  mkdirTmp
  local rid="$1"
  shift 1
  eval "$@" > "$tmpdir/$rid.stdout"
}

launchTest() {
  cdir="$d0/cases/$fname"
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
