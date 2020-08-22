
import sys
import os
import time

pathpref = sys.argv[1]
fi = open(pathpref + '.in', 'rb')
fs = open(pathpref + '.sp', 'r')

fsi = open(sys.argv[2], 'wb')
fso = sys.argv[3]

time.sleep(0.1)

ret = 0

oi0 = 0
for ln in fs:
  a = [int(s) for s in ln.split(' ')]
  oi = a[0]
  oo = a[1]
  buf = fi.read(oi-oi0)
  fsi.write(buf)
  fsi.flush()
  isTimedout = True
  for i in range(10):
    if os.path.getsize(fso) >= oo:
      isTimedout = False
      break
    time.sleep(0.1)
  if isTimedout:
    sys.stderr.write("Failed: timed out\n")
    ret = 1
  oi0 = oi

oo = os.path.getsize(pathpref + '.out')

buf = fi.read()
fsi.write(buf)
fsi.flush()
isTimedout = True
for i in range(10):
  if os.path.getsize(fso) >= oo:
    isTimedout = False
    break
  time.sleep(0.1)
if isTimedout:
  sys.stderr.write("Failed: timed out\n")
  ret = 1

sys.exit(ret)
