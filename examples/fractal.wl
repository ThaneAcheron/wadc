#"standard.h"
#"quaketextures.h"

main {
  thing
  frac
}

frac {
  chouter
  straight(128)
  eleft(64)
  frac3
  eleft(64)
  straight(128)
  eleft(256)
  straight(128)
  eleft(64)
  frac3
  eleft(64)
  straight(128)
  left(752)
  left(752)
  secch2
  leftsector(0,128,128)
}

frac3 {
  straight(64)
  move(32)
  rotleft
  frac2
  eleft(32)
  frac2
  eleft(32)
  frac2
  left(32)
  eleft(32)
  straight(32)
  eleft(32)
  straight(192)
  eleft(32)
  straight(240)
  eleft(32)
  straight(192)
  eleft(32)
  straight(32)
  eleft(32)
  straight(32)
  leftsector(16,112,144)
  turnaround
  movestep(32,-112)
  straight(64)
}

frac2 {
  frac1
  rotright
  frac1
  rotright
  frac1
}

frac1 {
  brick
  straight(8)
  !a
  straight(8)
  chouter2
  left(16)
  right(16)
  right(16)
  brick
  left(8)
  straight(8)
  !b
  ^a
  brick2
  left(16)
  eright(8)
  straight(16)
  eright(8)
  straight(16)
  secmet8
  rightsector(64,96,192)
  ^b
}

