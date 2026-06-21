import engine, thorvg_capi, paint

type
  Colorspace* = distinct TvgColorspace
    ## Specifies the pixel format and byte ordering of the 32-bit colors 
    ## used when reading from or writing to the canvas buffer.

  EngineOption* {.pure.} = enum
    ## Options to configure the internal behavior of the rendering engine.
    None = 0
    Default = 1
    SmartRender = 2

  SwCanvasObj* = object
    ## A canvas entity responsible for rendering graphical elements using 
    ## a software raster engine. It manages the target buffer and scene-graph elements.
    handle*: TvgCanvas
    width*: uint32
    height*: uint32
    colorspace*: Colorspace

  SwCanvas* = ref SwCanvasObj

const
  ColorspaceABGR8888* = Colorspace(TVG_COLORSPACE_ABGR8888)    ## Unmultiplied ABGR color space (8 bits per channel).
  ColorspaceARGB8888* = Colorspace(TVG_COLORSPACE_ARGB8888)    ## Unmultiplied ARGB color space (8 bits per channel).
  ColorspaceABGR8888S* = Colorspace(TVG_COLORSPACE_ABGR8888S)  ## Premultiplied ABGR color space (8 bits per channel).
  ColorspaceARGB8888S* = Colorspace(TVG_COLORSPACE_ARGB8888S)  ## Premultiplied ARGB color space (8 bits per channel).
  ColorspaceUNKNOWN* = Colorspace(TVG_COLORSPACE_UNKNOWN)      ## Unknown or uninitialized color space.

proc toTvgColorspace*(colorspace: Colorspace): TvgColorspace {.inline.} =
  ## Internal helper to cast the distinct type back to the underlying C-api enum.
  cast[TvgColorspace](colorspace)

proc `=destroy`*(canvas: var SwCanvasObj) =
  ## Automatically releases and destroys the underlying native canvas resources 
  ## when the `SwCanvasObj` goes out of scope or is garbage collected.
  if canvas.handle != nil:
    discard tvgCanvasDestroy(canvas.handle)
    canvas.handle = nil

proc newSwCanvas*(opt: EngineOption = EngineOption.Default): SwCanvas =
  ## Creates a new `SwCanvas` instance with optional rendering engine settings.
  ##
  ## Throws a `ThorVGError` if the backend software engine could not be created or is unsupported.
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
  ## Sets the drawing target buffer for software rasterization.
  ##
  ## The memory block must be allocated and owned by the caller, and must be at least 
  ## `stride * height` in size.
  ##
  ## **Warning:** Do not access or modify the `buffer` contents while the engine is drawing 
  ## (between `push()` and `sync()`).
  ##
  ## **Note:** Resetting the target will automatically reset the canvas viewport to match the new target size.
  ##
  ## Throws an error if arguments are invalid or if the canvas is currently busy rendering.
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
  ## Sets the drawing target using a safe Nim `openArray`.
  ## 
  ## Validates that the provided buffer size satisfies the `stride * height` memory requirement 
  ## before passing it to the underlying rendering context.
  if buffer.len < int(stride * height):
    raise newException(
      ValueError, "Buffer size is smaller than stride * height requirement"
    )
  canvas.setTarget(addr buffer[0], stride, width, height, colorspace)

proc viewport*(canvas: SwCanvas, x, y, width, height: int32) =
  ## Sets the drawing region (clipping boundary) of the canvas.
  ##
  ## The viewport restricts the final rendering output to the specified rectangular boundaries.
  ##
  ## **Warning:** Changing the viewport is strictly forbidden after calling structural or rendering 
  ## commands like `push()`, `remove()`, `update()`, or `draw()`. It must only be adjusted 
  ## when the canvas is in a fully synced state.
  checkResult(tvgCanvasSetViewport(canvas.handle, x, y, width, height))

proc remove*(canvas: SwCanvas, paint: Paint): bool {.discardable.} =
  ## Removes a specific `Paint` object from the root scene.
  ##
  ## Returns `true` if the paint node was successfully located and removed.
  let res = tvgCanvasRemove(canvas.handle, paint.handle)
  result = (res == TVG_RESULT_SUCCESS)

proc remove*(canvas: SwCanvas): bool {.discardable.} =
  ## Removes all paint objects from the root scene, clearing the canvas layout.
  ##
  ## Returns `true` on success.
  let res = tvgCanvasRemove(canvas.handle, nil)
  result = (res == TVG_RESULT_SUCCESS)

proc insert*(canvas: SwCanvas, target: Paint, at: Paint): bool {.discardable.} =
  ## Inserts a `target` paint object immediately before an existing `at` paint object 
  ## in the root scene.
  ##
  ## **Note:** The ownership of the paint object is transferred to the canvas upon addition.
  ## Returns `false` if either handle is invalid, or `true` upon a successful insertion.
  if canvas.handle == nil or target.handle == nil:
    return false

  let res = tvgCanvasInsert(canvas.handle, target.handle, at.handle)
  result = (res == TVG_RESULT_SUCCESS)

proc push*(canvas: SwCanvas, paint: Paint): bool {.discardable.} =
  ## Appends a `Paint` object to the end of the root scene.
  ##
  ## Elements are rendered sequentially in the order they are pushed. If you intend to use 
  ## layered composition, make sure to sort or push elements from bottom to top.
  ##
  ## **Warning:** The `Paint` object cannot be shared among multiple canvases simultaneously.
  ## The canvas assumes ownership of the node.
  if canvas.handle == nil or paint.handle == nil:
    return false

  let res = tvgCanvasAdd(canvas.handle, paint.handle)
  result = (res == TVG_RESULT_SUCCESS)

proc insert*(canvas: SwCanvas, target: Paint): bool {.discardable.} =
  ## Shortcut alias to append a `Paint` object to the end of the root scene. 
  ## See `push()`.
  canvas.push(target)

proc update*(canvas: SwCanvas) =
  ## Requests the canvas to prepare modified paint objects for rendering.
  ##
  ## This processes internal state transformations for any scene nodes altered since the 
  ## last cycle. If the canvas is multi-threaded, this calculation may execute asynchronously.
  checkResult(tvgCanvasUpdate(canvas.handle))

proc draw*(canvas: SwCanvas, clear: bool = false) =
  ## Requests the canvas to render the current queue of `Paint` objects into its target buffer.
  ##
  ## If `clear` is set to `true`, the target buffer is wiped to zero before drawing begins.
  ##
  ## **Note:** Skipping `clear` can optimize performance if you guarantee that opaque elements 
  ## fully cover the canvas region. Rendering can happen asynchronously; always accompany with 
  ## `sync()` to verify completion before attempting to process or swap buffers.
  checkResult(tvgCanvasDraw(canvas.handle, clear))

proc sync*(canvas: SwCanvas) =
  ## Blocks and guarantees that any ongoing asynchronous drawing tasks on this canvas are completed.
  ##
  ## Must be explicitly called after `draw()` to guarantee thread safety before accessing 
  ## your target framebuffers or attempting to alter the viewport.
  checkResult(tvgCanvasSync(canvas.handle))

proc render*(canvas: SwCanvas, clear: bool = false) =
  ## High-level composite operation that sequentially calls `update()`, `draw()`, and 
  ## blocks via `sync()` to output a finalized frame in a single call.
  canvas.update()
  canvas.draw(clear)
  canvas.sync()
