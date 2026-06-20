import thorvg_capi
import engine, paint, animation

type
  SaverObj* = object of RootObj
    handle*: TvgSaver

  Saver* = ref SaverObj

proc `=destroy`(saver: var SaverObj) =
  if saver.handle != nil:
    discard tvgSaverDel(saver.handle)
    saver.handle = nil

proc newSaver*(): Saver =
  let h = tvgSaverNew()
  if h == nil:
    raise newException(ThorVGError, "Failed to create ThorVG Saver object")
  result = Saver(handle: h)

proc save*(
    saver: Saver, paint: Paint, path: string, quality: uint32 = 100
): Saver {.discardable.} =
  if saver.isNil:
    return saver
  if path.len == 0:
    raise newException(ValueError, "Save path cannot be empty")
  if paint.isNil:
    raise newException(ValueError, "Cannot save an empty or nil Paint object")

  checkResult(
    tvgSaverSavePaint(saver.handle, paint.handle, path.cstring, quality.uint32)
  )
  result = saver

proc save*(
    saver: Saver,
    animation: Animation,
    path: string,
    quality: uint32 = 100,
    fps: uint32 = 0,
): Saver {.discardable.} =
  if saver.isNil:
    return saver
  if path.len == 0:
    raise newException(ValueError, "Save path cannot be empty")
  if animation.isNil:
    raise newException(ValueError, "Cannot save an empty or nil Animation object")

  checkResult(
    tvgSaverSaveAnimation(
      saver.handle, animation.handle, path.cstring, quality.uint32, fps.uint32
    )
  )
  result = saver

proc sync*(saver: Saver): Saver {.discardable, inline.} =
  if saver.isNil:
    return saver
  checkResult(tvgSaverSync(saver.handle))
  result = saver
