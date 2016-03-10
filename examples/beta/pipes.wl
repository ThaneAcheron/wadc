/*
 * This is part of pipes.wl/usepipes.wl, an "Underhalls" tribute
 * I started in around 2006 and never finished.
 *                                                 -- jmtd
 */

#"standard.h"
#"water.h"

/*
 * initialise the slime stuff
 * return a slime handle, configured with the supplied parameters
 * slimeinit must be called in a position where control sectors can
 * be drawn forward/right (restriction inherited from water.h)
 *
 * caller should ensure unpegged is set
 */
slimeinit(o,
    f, -- floor level
    c, -- ceiling level
    l, -- base light level
    wh,-- water height above floor
    wf,-- water flat
    wm,-- COLORMAP for underwater
    wl -- base light level underwater
    ) {
    oset(o,"floor",f)
    oset(o,"ceil", c)
    oset(o,"light",l)
    oset(o,"whandle",onew)
    slimeset(o)
    owaterinit(oget(o,"whandle"), add(wh, f), wf, wm, wl)
    o
}
/*
 * slimeset - set our slime object handle
 */
slimeset(o) {
  set("slime", o)
}
/*
 * convenience function
 */
swater(x, fh, ch) {
  owater(oget(get("slime"),"whandle"), x, fh, ch)
}

slimetype(x,tag) {
  sectortype(0,tag)
  floor("SLIME01")
  x
  sectortype(0,0)
  floor("SLIME16")
}
slimemain(x) { slimetype(x,$slime1) }

-- normal corridor
slimecorridor(y) { _slimecorridor(y, oget(get("slime"), "floor"), oget(get("slime"), "ceil"), oget(get("slime"), "light")) }
_slimecorridor(y,f,c,l) {

  swater(
    box(add(32,f),sub(c,32),l,y,32)
    movestep(0,sub(256,32))
    box(add(32,f),sub(c,32),l,y,32),
  add(32,f), sub(c,32))

  movestep(0,mul(-1,sub(256,64)))

  swater( box(f,c,l,y,sub(256,64)), f, c )

  movestep(y,-32)
}

-- corridor with exit ramps
-- XXX: we rely on the last sector drawn here being the main floor
-- XXX: move the choke stuff out of here
slimeopening(y) { _slimeopening(y,oget(get("slime"), "floor"),oget(get("slime"), "light")) }
_slimeopening(y,f,l) {

  slimechoke
  move(sub(y,32))
  slimechoke
  move(mul(-1,y))

  swater(
      box(add(32,f),add(96,f),l,sub(y,32),32),
      add(32,f), add(96,f)
  )

  movestep(0,32)

  swater(
    box(add(16,f),add(128,f),l,sub(y,32),32)

    movestep(0,sub(256,96))

    right(32) left(sub(y,32)) left(32) left(sub(y,32))
    leftsector(add(16,f),add(128,f),l),
    add(16,f), add(128,f)
  )

  turnaround movestep(0,32)

  swater(
    box(add(32,f),add(96,f),l,sub(y,32),32),
    add(32,f), add(96,f)
  )

  movestep(0,mul(-1,sub(256,96)))

  swater(
    box(f,add(128,f),l,sub(y,32),sub(256,64)),
    f, add(128,f)
  )

  movestep(y,-64)
}

-- a curve to the right
slimecurve_r { _slimecurve_r(oget(get("slime"), "floor"), oget(get("slime"), "ceil"), oget(get("slime"), "light")) }
_slimecurve_r(f,c,l) {
  !omglol
  right(32) straight(192) straight(32)
  ^omglol
  curve(add(128,mul(2,128)),add(128,mul(2,128)),64,1)
  ^omglol
  movestep(0,32)
  curve(add(96,mul(2,128)),add(96,mul(2,128)),64,1)
  ^omglol
  movestep(0,sub(256,32))
  curve(add(32,128),add(32,128),32,1)
  ^omglol
  movestep(0,256)
  curve(128,128,32,1)

  rotleft

  straight(32)
  swater(
      leftsector(add(f,32),sub(c,32),l),
      add(f,32), sub(c,32)
  )
  swater(
      straight(sub(256,64))
      leftsector(f,c,l),
      f, c
  )
  swater(
      straight(32)
      leftsector(add(f,32),sub(c,32),l),
      add(f,32), sub(c,32)
  )

  rotright
}

-- a curve to the left
slimecurve_l { _slimecurve(oget(get("slime"), "floor"), oget(get("slime"), "ceil"), oget(get("slime"), "light")) }
_slimecurve(f,c,l) {
  curve(128,mul(-1,128),32,1)
  rotright
  straight(32)
  !secondbit
  rotright
  curve(add(32,128),add(32,128),32,1)
  rotright
  swater(
    straight(32)
    rightsector(add(32,f),sub(c,32),l),
    add(32,f), sub(c,32)
  )
  ^secondbit
  move(sub(256,64))
  !thirdbit
  rotright
  -- dodgy bit
  curve(add(96,mul(2,128)),add(96,mul(2,128)),32,1)
  rotright
  straight(sub(265,64))
  ^secondbit
  swater(
    straight(sub(256,64))
    rightsector(f,c,l)
    , f,c
  )

  ^thirdbit
  straight(32)
  rotright
  curve(add(128,mul(2,128)),add(128,mul(2,128)),32,1)
  rotright
  swater(
    straight(32)
    rightsector(add(32,f),sub(c,32),l)
    , add(32,f), sub(c,32)
  )

  ^secondbit
  rotleft
  movestep(0,-32)
}

slimebars(tag) {
  _slimebars(oget(get("slime"), "floor"), oget(get("slime"), "ceil"),
             oget(get("slime"), "light"), tag)
}
_slimebars(f,c,l,tag) {
  slimecorridor(32)
  !slimebars
  top("SUPPORT3")
  bot("-")
  sectortype(0,tag)
  movestep(-28,32)
  unpegged
  triple(
    movestep(0,30)
    xoff(0) straight(24)
    triple( xoff(0) right(24) )
    innerrightsector(f,f,l)
    popsector
    rotright
    movestep(0,24)
  )
  unpegged
  ^slimebars
  sectortype(0,0)
}
slimeswitch(y,tag) {
  _slimeswitch(y, oget(get("slime"), "floor"), oget(get("slime"), "ceil"),
               oget(get("slime"), "light"), tag)
}
_slimeswitch(y,f,c,l,tag) {
  slimecorridor(y)
  popsector
  popsector

  -- switch
  pushpop(
    movestep(-64,24)
    rotleft
    linetype(103,tag)
    bot("SW1BRIK") xoff(16) yoff(40) right(32)
    linetype(0,0)
    bot("SHAWN2") left(8) left(32) left(8)
    floor("FLAT23")
    innerleftsector(64,sub(128,32),l)
  )
}

/*
 * slimecut - cut out a section of wall for adjoining a corridor to
 * y  - length of corridor
 * nf - destination floor height
 */
biggest(a,b) { lessthaneq(a,b) ? b : a }
smallest(a,b){ lessthaneq(a,b) ? a : b }

-- return a floor height that moves towards nf from f in increments of 24
nextstep(f,nf) {
    eq(f,nf) ? f : { -- obvious case

        lessthaneq(f,nf) ? {
            -- f < nf
            smallest(nf, add(f,24))

        } : {
            -- f > nf
            biggest(nf, sub(f,24))
        }

    }
}

slimecut(y,nf) { _slimecut(y, nf, oget(get("slime"), "floor"), oget(get("slime"), "ceil"), oget(get("slime"), "light")) }
_slimecut(y,nf,f,c,l) {
  move(y) !slimecut rotright

  -- left-hand ledge/rail
  swater(
    box(add(32,f),sub(c,32),l,32,y),
    add(32,f), sub(c,32)
  )
  move(32)

  -- normal corridor floor, but shorter
  swater(
    box(f,c, l, 128, y),
    f,c
  )
  move(128)

  -- three steps down/up: two in corridor, one in ledge/rail
  swater(
    set("slimecut_stepheight", nextstep(f,nf))
    box(get("slimecut_stepheight"), c, l, 32, y) move(32)
    set("slimecut_stepheight", nextstep(get("slimecut_stepheight"),nf))
    box(get("slimecut_stepheight"), c, l, 32, y) move(32),
    f, c
  )
  swater(
    set("slimecut_stepheight", nextstep(get("slimecut_stepheight"),nf))
    box(get("slimecut_stepheight"), c, l, 32, y) move(32),
    sub(f,72), sub(c,32)
  )
  ^slimecut
}

/*
 * slimesecret: puts a secret corridor on the side
 * secret corridor is 96 units lower than base
 */
slimesecret(y,whatever) {
  _slimesecret(y, oget(get("slime"), "floor"), oget(get("slime"), "ceil"), oget(get("slime"), "light"), whatever)
}
_slimesecret(y,f,c,l,whatever) {
    -- new temporary slime object
    set("slimesecret", onew)
    set("slimebackup", get("slime"))

  slimecut(64,sub(f,96)) -- tunnel will be -96
  !slimesecret_orig
  slimeinit(get("slimesecret"), -96, 32, 120, 120, "NUKAGE1", "WATERMAP", 80)
  ^slimesecret_orig

  -- joining tunnel
  movestep(-64,256)
  swater(
      unpegged straight(64) unpegged
      right(128) right(64) right(128)
      rightsector(f, c, l),
      f, sub(c, 8)
  )

  rotleft
  movestep(-64,-384) -- tunnel + width of corridor
  slimecut(64,f)
  turnaround movestep(64,-256)

  -- north detailing
  !slimesecret
  slimecorridor(256)
  slimebars(0)
  slimefade(0)

  -- the treat
  ^slimesecret movestep(128,128) whatever

  -- south detailing
  ^slimesecret
  turnaround movestep(64,-256)
  slimecurve_l
  slimebars(0)
  slimefade(slimecurve_l)

  set("slime", get("slimebackup"))
  ^slimesecret_orig
}

slimesplit(left, centre, right) {
  _slimesplit(oget(get("slime"), "floor"), oget(get("slime"), "light"),
              left, centre, right)
}
_slimesplit( f,l, left, centre, right) {
  !slimesplitmarker
  right(32) straight(192) straight(32)

  ^slimesplitmarker 
  movestep(0,sub(256,32))
  curve(add(32,128),add(32,128),32,1)
  ^slimesplitmarker
  movestep(0,256)
  curve(128,128,32,1)

  ^slimesplitmarker 
  curve(128,-128,32,1)
  ^slimesplitmarker 
	movestep(0,32)
  curve(add(32,128),mul(-1,add(32,128)),32,1)
	rotright
  swater(
    straight(-32)
    leftsector(add(f,32),add(f,96),l)
    , add(f,32), add(f,96)
  )
	movestep(32,0)

	straight(192) straight(32)

	rotright 
    swater(
      box(add(32,f),add(96,f),l,512,32)
      , add(32,f), add(96,f)
    )
	movestep(512,32) rotright

    swater(
      straight(192)
      rightsector(f,add(128,f),l)
      , f, add(128,f)
    )

  -- centre hook, for detailing
  centre

  straight(32)
  rightsector(add(f,32),add(f,96),l)

	^slimesplitmarker
	movestep(128,-128)
	rotleft
	left

	^slimesplitmarker
	movestep(384,384)
	rotright
	right

    ^slimesplitmarker

}

-- slimechoke: walls move in a bit
slimechoke { _slimechoke(oget(get("slime"), "floor"), oget(get("slime"), "light")) }
_slimechoke(f,l) {
  !slimechoke
  movestep(0,32)
  mid("METAL") top("METAL") bot("METAL")
  swater(
      box(f,add(72,f),l,32,sub(256,64)),
      f, add(72, f)
  )
  movestep(0,-32)
  right(256)
  rotleft movestep(32,-256)
  right(256)
  ^slimechoke
  move(32)
}

-- slimefade: light level fade-off
slimefade(after) {
    set("slimefade", oget(get("slime"), "light"))
    _slimefade(16)
    after
    oset(get("slime"), "light", get("slimefade"))
}
_slimefade(i) {
    lessthaneq(i,0) ? 0 : {
        oset(get("slime"), "light", sub(oget(get("slime"), "light"), 8))
        slimecorridor(16)
        _slimefade(sub(i,1))
    }
}

-- WIP
-- need to rework slimesplit so that we can safely put inner sectors in the
-- middle bit, by re-ordering the drawing/sector creation
slime_downpipe {
  !slime_downpipe
  turnaround
  movestep(32, -320)

  -- WIP downpipe
  xoff(0)

  -- draw the outside of the pipe first
  swater(
    quad(curve(64, 64, 8, 1)) innerrightsector(0, 64, oget(get("slime"), "light")),
    0, 64
  )

  -- contortion to add linedefs to the donut
  movestep(0,120)

  mid("SFALL1")
  xoff(0) yoff(-1)
   -- simple static scroller. Major drawback: we lose control of texture
   -- offsets for their primary purpose. Solution: use one of the more
   -- complex scrollers, with a control linedef.
   linetype(255,0)
    quad( curve(56, -56, 8, 0) )
   linetype(0,0)
  xoff(0) yoff(0)

  -- trick to create a donut-shaped sector with the sidedefs pointing out
  forcesector(lastsector)
  rightsector(0,0,0)

  ^slime_downpipe
}

/*
 * slimequad - a four-way split for corridors
 * orientations assuming we're drawing northwards
 *   e,w - hooks for corridors to east and west
 *   s is assumed to be drawn prior to slimequad
 *   n is assumed to be handled after slimequad
 */
slimequad(o,e,w) { _slimequad(e,w,
  oget(get("slime"), "floor"), oget(get("slime"), "ceil"), oget(get("slime"), "light"))
}
_slimequad(east,west,f,c,l) {
  swater(
    -- XXX: quad(...) fails; moving rotright before rightsector fails.
    triple( straight(32) straight(192) straight(32) rotright)
    straight(32) straight(192) straight(32)
    rightsector(f,c,l)
    rotright,
    f, c
  )
  !slimequad movestep(256,256) rotright east
  ^slimequad rotleft west
  ^slimequad movestep(256,0)
}

slimetrap { _slimetrap(oget(get("slime"), "floor"), oget(get("slime"), "ceil"), oget(get("slime"), "light")) }
_slimetrap(f,c,l) {
  !slimetrap
  slimeopening(512)
  ^slimetrap
  movestep(48,72)
  swater(
    linetype(109,$slimetrap)
    ibox(f,c,l,112,112),
    f,c
  )
  linetype(0,0)

  ^slimetrap
  movestep(add(512,32),0) -- past choke
  slimebars(0) -- tmp stuff
  slimecorridor(128) -- tmp stuff
  slimefade(slimecurve_r)

  ^slimetrap
  movestep(64,-32) -- past choke
  slimetrap_sideroom(f,c,l)
}
slimetrap_sideroom(f,c,l) {
  -- the trap-door
  box(add(f,32),sub(c,32),l, 384, 12)
  movestep(0,12)
  sectortype(0, $slimetrap) mid("doortrak")
  box(add(f,32),add(f,32),l, 384, 8)
  sectortype(0,0)
  movestep(0,8)
  box(add(f,32),sub(c,32),l, 384, 12)

  -- the trap-room
  ^slimetrap
  movestep(0,-32) rotleft
  box(add(f,32),c,l, 256, 512)
  pushpop(
    movestep(128,128) turnaround
    for(0, 3,
      formersergeant thing
      movestep(0,-64)
    )
  )
}
