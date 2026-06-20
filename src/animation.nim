import thorvg_capi
import engine, paint, picture
export engine, paint, picture

type
  AnimationObj* = object of RootObj
    handle*: TvgAnimation

  Animation* = ref AnimationObj

proc isNil*(anim: Animation): bool {.inline.} =
  anim == nil or anim.handle == nil

proc `=destroy`(anim: var AnimationObj) =
  if anim.handle != nil:
    discard tvgAnimationDel(anim.handle)
    anim.handle = nil

proc newAnimation*(): Animation =
  let h = tvgAnimationNew()
  if h == nil:
    raise newException(ThorVGError, "Failed to create ThorVG Animation object")
  result = Animation(handle: h)

proc getPicture*(anim: Animation): Picture =
  if anim.isNil:
    return nil
  
  let hPaint = tvgAnimationGetPicture(anim.handle)
  if hPaint != nil:
    discard tvgPaintRef(hPaint) 
    result = Picture(handle: hPaint)

proc `frame=`*(anim: Animation, no: float) =
  if anim.isNil:
    return
  checkResult(tvgAnimationSetFrame(anim.handle, no.cfloat))

proc frame*(anim: Animation, no: float): Animation {.discardable, inline.} =
  anim.frame = no
  result = anim

proc curFrame*(anim: Animation): float =
  if anim.isNil:
    return 0.0
  var no: cfloat
  checkResult(tvgAnimationGetFrame(anim.handle, addr no))
  result = no.float

proc totalFrame*(anim: Animation): float =
  if anim.isNil:
    return 0.0
  var cnt: cfloat
  checkResult(tvgAnimationGetTotalFrame(anim.handle, addr cnt))
  result = cnt.float

proc duration*(anim: Animation): float =
  if anim.isNil:
    return 0.0
  var dur: cfloat
  checkResult(tvgAnimationGetDuration(anim.handle, addr dur))
  result = dur.float

proc `segment=`*(anim: Animation, range: tuple[begin, `end`: float]) =
  if anim.isNil:
    return
  checkResult(
    tvgAnimationSetSegment(anim.handle, range.begin.cfloat, range.`end`.cfloat)
  )

proc segment*(anim: Animation, begin, `end`: float): Animation {.discardable, inline.} =
  anim.segment = (begin, `end`)
  result = anim

proc segment*(anim: Animation): tuple[begin, `end`: float] =
  if anim.isNil:
    return (0.0, 0.0)
  var begFrm, endFrm: cfloat
  checkResult(tvgAnimationGetSegment(anim.handle, addr begFrm, addr endFrm))
  result = (begFrm.float, endFrm.float)
