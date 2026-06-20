import engine, thorvg_capi, paint

type
  Colorspace* = distinct TvgColorspace

  EngineOption* {.pure.} = enum
    None = 0
    Default = 1
    SmartRender = 2

  SwCanvasObj* = object
    handle*: TvgCanvas
    width*: uint32
    height*: uint32
    colorspace*: Colorspace

  SwCanvas* = ref SwCanvasObj

const
  ColorspaceABGR8888* = Colorspace(TVG_COLORSPACE_ABGR8888)
  ColorspaceARGB8888* = Colorspace(TVG_COLORSPACE_ARGB8888)
  ColorspaceABGR8888S* = Colorspace(TVG_COLORSPACE_ABGR8888S)
  ColorspaceARGB8888S* = Colorspace(TVG_COLORSPACE_ARGB8888S)
  ColorspaceUNKNOWN* = Colorspace(TVG_COLORSPACE_UNKNOWN)

proc toTvgColorspace*(colorspace: Colorspace): TvgColorspace {.inline.} =
  cast[TvgColorspace](colorspace)

proc `=destroy`*(canvas: var SwCanvasObj) =
  if canvas.handle != nil:
    discard tvgCanvasDestroy(canvas.handle)
    canvas.handle = nil

proc newSwCanvas*(opt: EngineOption = EngineOption.Default): SwCanvas =
  let hCanvas = tvgSwcanvasCreate(cast[TvgEngineOption](opt))
  if hCanvas == nil:
    raise newException(ThorVGError, "Failed to create Software Canvas")

  result = SwCanvas(handle: hCanvas, width: 0, height: 0, colorspace: ColorspaceUNKNOWN)

proc setTarget*(
    canvas: SwCanvas,
    buffer: ptr uint32,
    stride: uint32,
    width: uint32,
    height: uint32,
    colorspace: Colorspace = ColorspaceARGB8888,
) =
  checkResult(
    tvgSwcanvasSetTarget(
      canvas.handle, buffer, stride, width, height, colorspace.toTvgColorspace()
    )
  )
  canvas.width = width
  canvas.height = height
  canvas.colorspace = colorspace

proc setTarget*(
    canvas: SwCanvas,
    buffer: var openArray[uint32],
    stride: uint32,
    width: uint32,
    height: uint32,
    colorspace: Colorspace = ColorspaceARGB8888,
) =
  if buffer.len < int(stride * height):
    raise newException(
      ValueError, "Buffer size is smaller than stride * height requirement"
    )
  canvas.setTarget(addr buffer[0], stride, width, height, colorspace)

proc viewport*(canvas: SwCanvas, x, y, width, height: int32) =
  checkResult(tvgCanvasSetViewport(canvas.handle, x, y, width, height))

proc remove*(canvas: SwCanvas, paint: Paint): bool {.discardable.} =
  let res = tvgCanvasRemove(canvas.handle, paint.handle)
  result = (res == TVG_RESULT_SUCCESS)

proc remove*(canvas: SwCanvas): bool {.discardable.} =
  let res = tvgCanvasRemove(canvas.handle, nil)
  result = (res == TVG_RESULT_SUCCESS)

proc insert*(canvas: SwCanvas, target: Paint, at: Paint): bool {.discardable.} =
  if canvas.handle == nil or target.handle == nil:
    return false

  let res = tvgCanvasInsert(canvas.handle, target.handle, at.handle)
  result = (res == TVG_RESULT_SUCCESS)

proc push*(canvas: SwCanvas, paint: Paint): bool {.discardable.} =
  if canvas.handle == nil or paint.handle == nil:
    return false

  let res = tvgCanvasAdd(canvas.handle, paint.handle)
  result = (res == TVG_RESULT_SUCCESS)

proc insert*(canvas: SwCanvas, target: Paint): bool {.discardable.} =
  canvas.push(target)

proc update*(canvas: SwCanvas) =
  checkResult(tvgCanvasUpdate(canvas.handle))

proc draw*(canvas: SwCanvas, clear: bool = false) =
  checkResult(tvgCanvasDraw(canvas.handle, clear))

proc sync*(canvas: SwCanvas) =
  checkResult(tvgCanvasSync(canvas.handle))

proc render*(canvas: SwCanvas, clear: bool = false) =
  canvas.update()
  canvas.draw(clear)
  canvas.sync()
