import thorvg_capi
import engine, paint, shape
export engine, paint, shape

type
  GradientObj* = object of RootObj
    handle*: TvgGradient

  Gradient* = ref GradientObj

  LinearGradient* = ref object of Gradient
    x1*, y1*, x2*, y2*: float

  RadialGradient* = ref object of Gradient
    cx*, cy*, r*, fx*, fy*, fr*: float

  ColorStop* = object
    offset*: float
    color*: ColorRGBA

proc isNil*(grad: Gradient): bool {.inline.} =
  grad == nil or grad.handle == nil

proc `=destroy`(grad: var GradientObj) =
  if grad.handle != nil:
    discard tvgGradientDel(grad.handle)
    grad.handle = nil

proc newLinearGradient*(x1, y1, x2, y2: float): LinearGradient =
  let handle = tvgLinearGradientNew()
  if handle == nil:
    raise newException(ThorVGError, "Failed to create linear gradient")

  result = LinearGradient(handle: handle, x1: x1, y1: y1, x2: x2, y2: y2)
  checkResult(tvgLinearGradientSet(handle, x1.cfloat, y1.cfloat, x2.cfloat, y2.cfloat))

proc newRadialGradient*(
    cx, cy, r: float, fx: float = 0.0, fy: float = 0.0, fr: float = 0.0
): RadialGradient =
  let handle = tvgRadialGradientNew()
  if handle == nil:
    raise newException(ThorVGError, "Failed to create radial gradient")

  let actualFx = if fx == 0.0: cx else: fx
  let actualFy = if fy == 0.0: cy else: fy

  result = RadialGradient(
    handle: handle, cx: cx, cy: cy, r: r, fx: actualFx, fy: actualFy, fr: fr
  )
  checkResult(
    tvgRadialGradientSet(
      handle, cx.cfloat, cy.cfloat, r.cfloat, actualFx.cfloat, actualFy.cfloat,
      fr.cfloat,
    )
  )

proc colorStop*(offset: float, color: ColorRGBA): ColorStop {.inline.} =
  ColorStop(offset: offset, color: color)

proc colorStop*(offset: float, r, g, b: uint8, a: uint8 = 255): ColorStop {.inline.} =
  ColorStop(offset: offset, color: ColorRGBA(r: r, g: g, b: b, a: a))

proc setColorStops*(grad: Gradient, stops: openArray[ColorStop]) =
  if grad.isNil or stops.len == 0:
    return

  var tvgStops = newSeq[TvgColorStop](stops.len)
  for i, stop in stops:
    tvgStops[i] = TvgColorStop(
      offset: stop.offset.cfloat,
      r: stop.color.r,
      g: stop.color.g,
      b: stop.color.b,
      a: stop.color.a,
    )

  checkResult(
    tvgGradientSetColorStops(grad.handle, addr tvgStops[0], tvgStops.len.uint32)
  )

proc getColorStops*(grad: Gradient): seq[ColorStop] =
  if grad.isNil:
    return @[]
  var pStops: ptr TvgColorStop = nil
  var count: uint32 = 0
  checkResult(tvgGradientGetColorStops(grad.handle, addr pStops, addr count))

  if count == 0 or pStops == nil:
    return @[]

  result = newSeq[ColorStop](count)

  let stopsArray = cast[ptr UncheckedArray[TvgColorStop]](pStops)
  for i in 0 ..< count.int:
    result[i] = ColorStop(
      offset: stopsArray[i].offset.float,
      color: ColorRGBA(
        r: stopsArray[i].r, g: stopsArray[i].g, b: stopsArray[i].b, a: stopsArray[i].a
      ),
    )

proc setSpread*(grad: Gradient, spread: TvgStrokeFill) {.inline.} =
  checkResult(tvgGradientSetSpread(grad.handle, spread))

proc getSpread*(grad: Gradient): TvgStrokeFill =
  var spread: TvgStrokeFill
  checkResult(tvgGradientGetSpread(grad.handle, addr spread))
  result = spread

proc setTransform*(grad: Gradient, matrix: TvgMatrix) =
  var m = matrix
  checkResult(tvgGradientSetTransform(grad.handle, addr m))

proc getTransform*(grad: Gradient): TvgMatrix =
  checkResult(tvgGradientGetTransform(grad.handle, addr result))

proc stops*(
    grad: Gradient, stops: openArray[ColorStop]
): Gradient {.discardable, inline.} =
  grad.setColorStops(stops)
  result = grad

proc stops*(
    grad: Gradient, stops: varargs[ColorStop]
): Gradient {.discardable, inline.} =
  grad.setColorStops(stops)
  result = grad

proc spread*(grad: Gradient, spread: TvgStrokeFill): Gradient {.discardable, inline.} =
  grad.setSpread(spread)
  result = grad

proc setGradient*(shape: Shape, grad: Gradient) =
  if shape.handle == nil:
    return
  let hGrad = if grad.isNil: nil else: grad.handle
  checkResult(tvgShapeSetGradient(shape.handle, hGrad))

proc fill*(shape: Shape, grad: Gradient): Shape {.discardable, inline.} =
  shape.setGradient(grad)
  result = shape

proc setMaskMethod*(paint: Paint, target: Paint, meth: TvgMaskMethod) =
  checkResult(tvgPaintSetMaskMethod(paint.handle, target.handle, meth))

proc getMaskMethod*(paint: Paint): (Paint, TvgMaskMethod) =
  var targetHandle: TvgPaint
  var meth: TvgMaskMethod

  checkResult(tvgPaintGetMaskMethod(paint.handle, targetHandle, addr meth))

  result = (Paint(handle: targetHandle), meth)
