import std/sequtils
import chroma
import vmath, bumpy
import thorvg_capi
import engine, canvas, paint, scene
export vmath, chroma, bumpy, engine, paint, canvas, scene

type
  # 【修改】与上面同理，Shape 必须继承 PaintObj，并声明为 ref 类型
  ShapeObj* = object of PaintObj
  Shape* = ref ShapeObj

type
  PathBuilder* = object
    shape: Shape

proc newShape*(): Shape =
  let handle = tvgShapeNew() # 统一规范底层 C 函数调用名
  if handle == nil:
    raise newException(ThorVGError, "Failed to create shape")
  result = Shape(handle: handle)
  discard tvgPaintRef(handle)

proc reset*(shape: Shape) =
  checkResult(tvgShapeReset(shape.handle))

proc init*(shape: var Shape, scene: Scene, reset: bool = true): bool {.discardable.} =
  if shape == nil or shape.handle == nil:
    shape = newShape()
    scene.push(shape)
    result = true
  elif reset:
    shape.reset()

proc moveTo*(shape: Shape, x, y: float) =
  checkResult(tvgShapeMoveTo(shape.handle, x.cfloat, y.cfloat))

proc lineTo*(shape: Shape, x, y: float) =
  checkResult(tvgShapeLineTo(shape.handle, x.cfloat, y.cfloat))

proc cubicTo*(shape: Shape, cx1, cy1, cx2, cy2, x, y: float) =
  checkResult(
    tvgShapeCubicTo(
      shape.handle, cx1.cfloat, cy1.cfloat, cx2.cfloat, cy2.cfloat, x.cfloat, y.cfloat
    )
  )

proc close*(shape: Shape) =
  checkResult(tvgShapeClose(shape.handle))

proc addRect*(
    shape: Shape,
    x, y, width, height: float,
    rx: float = 0,
    ry: float = 0,
    clockwise: bool = true,
) =
  checkResult(
    tvg_shape_append_rect(
      shape.handle, x.cfloat, y.cfloat, width.cfloat, height.cfloat, rx.cfloat,
      ry.cfloat, clockwise,
    )
  )

proc addCircle*(shape: Shape, cx, cy: float, rx, ry: float, clockwise: bool = true) =
  checkResult(
    tvgShapeAppendCircle(
      shape.handle, cx.cfloat, cy.cfloat, rx.cfloat, ry.cfloat, clockwise
    )
  )

proc addCircle*(shape: Shape, center: Vec2, radius: float, clockwise: bool = true) =
  shape.addCircle(center.x, center.y, radius, radius, clockwise)

proc add*(
    shape: var Shape,
    dims: Rect | Circle,
    rx: float = 0,
    ry: float = 0,
    clockwise: bool = true,
): Shape {.discardable.} =
  when dims is Rect:
    shape.addRect(dims.x, dims.y, dims.w, dims.h, rx, ry, clockwise)
  elif dims is Circle:
    shape.addCircle(dims.pos.x, dims.pos.y, dims.radius, dims.radius, clockwise)
  result = shape

proc setFillColor*(shape: Shape, color: SomeColor) =
  let rgba = color.asRgba()
  checkResult(tvg_shape_set_fill_color(shape.handle, rgba.r, rgba.g, rgba.b, rgba.a))

proc setFillColor*(shape: Shape, r, g, b: uint8, a: uint8 = 255) =
  checkResult(tvg_shape_set_fill_color(shape.handle, r, g, b, a))

proc getFillColor*(shape: Shape): ColorRGBA =
  var r, g, b, a: uint8
  checkResult(tvg_shape_get_fill_color(shape.handle, addr r, addr g, addr b, addr a))
  result = rgba(r, g, b, a)

proc setFillRule*(shape: Shape, rule: TvgFillRule) =
  checkResult(tvg_shape_set_fill_rule(shape.handle, rule))

proc getFillRule*(shape: Shape): TvgFillRule =
  checkResult(tvg_shape_get_fill_rule(shape.handle, addr result))

proc setStrokeWidth*(shape: Shape, width: float) =
  checkResult(tvg_shape_set_stroke_width(shape.handle, width.cfloat))

proc getStrokeWidth*(shape: Shape): float =
  var width: cfloat
  checkResult(tvg_shape_get_stroke_width(shape.handle, addr width))
  result = width.float

proc setStrokeColor*(shape: Shape, color: SomeColor) =
  let rgba = color.asRgba()
  checkResult(tvg_shape_set_stroke_color(shape.handle, rgba.r, rgba.g, rgba.b, rgba.a))

proc setStrokeColor*(shape: Shape, r, g, b: uint8, a: uint8 = 255) =
  checkResult(tvg_shape_set_stroke_color(shape.handle, r, g, b, a))

proc getStrokeColor*(shape: Shape): ColorRGBA =
  var r, g, b, a: uint8
  checkResult(tvg_shape_get_stroke_color(shape.handle, addr r, addr g, addr b, addr a))
  result = rgba(r, g, b, a)

proc setStrokeCap*(shape: Shape, cap: TvgStrokeCap) =
  checkResult(tvg_shape_set_stroke_cap(shape.handle, cap))

proc getStrokeCap*(shape: Shape): TvgStrokeCap =
  checkResult(tvg_shape_get_stroke_cap(shape.handle, addr result))

proc setStrokeJoin*(shape: Shape, join: TvgStrokeJoin) =
  checkResult(tvg_shape_set_stroke_join(shape.handle, join))

proc getStrokeJoin*(shape: Shape): TvgStrokeJoin =
  checkResult(tvg_shape_get_stroke_join(shape.handle, addr result))

proc setStrokeMiterLimit*(shape: Shape, limit: float) =
  checkResult(tvg_shape_set_stroke_miterlimit(shape.handle, limit.cfloat))

proc getStrokeMiterLimit*(shape: Shape): float =
  var limit: cfloat
  checkResult(tvg_shape_get_stroke_miterlimit(shape.handle, addr limit))
  result = limit.float

proc setStrokeDashInternal(shape: Shape, dash: seq[cfloat], offset: float) =
  if dash.len > 0:
    checkResult(
      tvg_shape_set_stroke_dash(
        shape.handle, unsafeAddr dash[0], dash.len.uint32, offset.cfloat
      )
    )
  else:
    checkResult(tvg_shape_set_stroke_dash(shape.handle, nil, 0, offset.cfloat))

proc setStrokeDash*(shape: Shape, dash: seq[float], offset: float = 0.0) =
  let cfloatDash = dash.mapIt(it.cfloat)
  shape.setStrokeDashInternal(cfloatDash, offset)

proc getStrokeDash*(shape: Shape): tuple[dash: seq[float], offset: float] =
  var dashPtr: ptr cfloat
  var cnt: uint32
  var offset: cfloat
  checkResult(
    tvg_shape_get_stroke_dash(shape.handle, addr dashPtr, addr cnt, addr offset)
  )

  var resDash = newSeq[float](cnt)
  if cnt > 0 and dashPtr != nil:
    let arr = cast[ptr UncheckedArray[cfloat]](dashPtr)
    for i in 0 ..< cnt:
      resDash[i] = arr[i].float
  result = (dash: resDash, offset: offset.float)

proc setTrimPath*(shape: Shape, start, finish: float, simultaneous: bool = true) =
  checkResult(
    tvg_shape_set_trimpath(shape.handle, start.cfloat, finish.cfloat, simultaneous)
  )

proc setPaintOrder*(shape: Shape, strokeFirst: bool) =
  checkResult(tvg_shape_set_paint_order(shape.handle, strokeFirst))

proc path*(shape: Shape): PathBuilder =
  PathBuilder(shape: shape)

proc moveTo*(builder: var PathBuilder, x, y: float): var PathBuilder {.discardable.} =
  builder.shape.moveTo(x, y)
  result = builder

proc lineTo*(builder: var PathBuilder, x, y: float): var PathBuilder {.discardable.} =
  builder.shape.lineTo(x, y)
  result = builder

proc cubicTo*(
    builder: var PathBuilder, cx1, cy1, cx2, cy2, x, y: float
): var PathBuilder {.discardable.} =
  builder.shape.cubicTo(cx1, cy1, cx2, cy2, x, y)
  result = builder

proc close*(builder: var PathBuilder): var PathBuilder {.discardable.} =
  builder.shape.close()
  result = builder

proc rect*(
    builder: var PathBuilder, x, y, width, height: float, rx: float = 0, ry: float = 0
): var PathBuilder {.discardable.} =
  builder.shape.addRect(x, y, width, height, rx, ry)
  result = builder

proc circle*(
    builder: var PathBuilder, center: Vec2, radius: float
): var PathBuilder {.discardable.} =
  builder.shape.addCircle(center, radius)
  result = builder

proc ellipse*(
    builder: var PathBuilder, center: Vec2, rx, ry: float
): var PathBuilder {.discardable.} =
  builder.shape.addCircle(center.x, center.y, rx, ry)
  result = builder

proc newRect*(x, y, width, height: float, rx: float = 0, ry: float = 0): Shape =
  result = newShape()
  result.addRect(x, y, width, height, rx, ry)

proc newCircle*(center: Vec2, radius: float): Shape =
  result = newShape()
  result.addCircle(center, radius)

proc newEllipse*(center: Vec2, rx, ry: float): Shape =
  result = newShape()
  result.addCircle(center.x, center.y, rx, ry)

proc fill*(shape: Shape, color: SomeColor): Shape {.discardable.} =
  shape.setFillColor(color)
  result = shape

proc fill*(shape: Shape, r, g, b: uint8, a: uint8 = 255): Shape {.discardable.} =
  shape.setFillColor(r, g, b, a)
  result = shape

proc stroke*(
    shape: Shape, color: SomeColor, width: float = 1.0
): Shape {.discardable.} =
  shape.setStrokeColor(color)
  shape.setStrokeWidth(width)
  result = shape

proc stroke*(
    shape: Shape, r, g, b: uint8, width: float = 1.0, a: uint8 = 255
): Shape {.discardable.} =
  shape.setStrokeColor(r, g, b, a)
  shape.setStrokeWidth(width)
  result = shape

proc strokeWidth*(shape: Shape, width: float): Shape {.discardable.} =
  shape.setStrokeWidth(width)
  result = shape
