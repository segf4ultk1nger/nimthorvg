import thorvg_capi
import engine
type
  LottieAnimationObj* = object of RootObj
    handle*: TvgAnimation

  LottieAnimation* = ref LottieAnimationObj

  AudioInfo* = TvgAudioInfo
  AudioResolver* = TvgAudioResolver

proc isNil*(anim: LottieAnimation): bool {.inline.} =
  anim == nil or anim.handle == nil

proc `=destroy`(anim: var LottieAnimationObj) =
  if anim.handle != nil:
    discard tvgAnimationDel(anim.handle)
    anim.handle = nil

proc newLottieAnimation*(): LottieAnimation =
  let h = tvgLottieAnimationNew()
  if h == nil:
    raise newException(ThorVGError, "Failed to create ThorVG LottieAnimation object")
  result = LottieAnimation(handle: h)

proc genSlot*(anim: LottieAnimation, slotJson: string): uint32 =
  if anim.isNil:
    return 0
  if slotJson.len == 0:
    raise newException(ValueError, "Slot JSON data cannot be empty")
  result = tvgLottieAnimationGenSlot(anim.handle, slotJson.cstring).uint32

proc applySlot*(
    anim: LottieAnimation, id: uint32
): LottieAnimation {.discardable, inline.} =
  checkResult(tvgLottieAnimationApplySlot(anim.handle, id.uint32))
  result = anim

proc delSlot*(
    anim: LottieAnimation, id: uint32
): LottieAnimation {.discardable, inline.} =
  checkResult(tvgLottieAnimationDelSlot(anim.handle, id.uint32))
  result = anim

proc setMarker*(
    anim: LottieAnimation, marker: string
): LottieAnimation {.discardable, inline.} =
  if marker.len == 0:
    raise newException(ValueError, "Marker name cannot be empty")
  checkResult(tvgLottieAnimationSetMarker(anim.handle, marker.cstring))
  result = anim

proc segment*(
    anim: LottieAnimation, marker: string
): LottieAnimation {.discardable, inline.} =
  anim.setMarker(marker)

proc markersCount*(anim: LottieAnimation): uint32 =
  if anim.isNil:
    return 0
  var cnt: uint32 = 0
  checkResult(tvgLottieAnimationGetMarkersCnt(anim.handle, addr cnt))
  result = cnt.uint32

proc getMarkerName*(anim: LottieAnimation, idx: uint32): string =
  if anim.isNil:
    return ""
  var arr: cstringArray = cast[cstringArray](alloc0(2 * sizeof(cstring)))
  defer:
    dealloc(arr)

  checkResult(tvgLottieAnimationGetMarker(anim.handle, idx.uint32, arr))
  if arr != nil and arr[0] != nil:
    result = $arr[0]

proc getMarkerInfo*(
    anim: LottieAnimation, idx: uint32
): tuple[name: string, beginFrame: float, endFrame: float] =
  if anim.isNil:
    return ("", 0.0, 0.0)
  var arr: cstringArray = cast[cstringArray](alloc0(2 * sizeof(cstring)))
  defer:
    dealloc(arr)
  var beginFrame: cfloat = 0.0
  var endFrame: cfloat = 0.0

  checkResult(
    tvgLottieAnimationGetMarkerInfo(
      anim.handle, idx.uint32, arr, addr beginFrame, addr endFrame
    )
  )

  let nameStr =
    if arr != nil and arr[0] != nil:
      $arr[0]
    else:
      ""
  result = (nameStr, beginFrame.float, endFrame.float)

proc tween*(
    anim: LottieAnimation, `from`, to, progress: float
): LottieAnimation {.discardable, inline.} =
  checkResult(
    tvgLottieAnimationTween(anim.handle, `from`.cfloat, to.cfloat, progress.cfloat)
  )
  result = anim

proc `quality=`*(anim: LottieAnimation, value: uint8) =
  let val = if value > 100: 100.uint8 else: value
  checkResult(tvgLottieAnimationSetQuality(anim.handle, val.uint8))

proc quality*(
    anim: LottieAnimation, value: uint8
): LottieAnimation {.discardable, inline.} =
  anim.quality = value
  result = anim

proc setAudioResolver*(
    anim: LottieAnimation, resolver: AudioResolver, userData: pointer = nil
): LottieAnimation {.discardable, inline.} =
  checkResult(tvgLottieAnimationSetAudioResolver(anim.handle, resolver, userData))
  result = anim
