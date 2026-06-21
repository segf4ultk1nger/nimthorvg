import std/sequtils
import chroma
import vmath, bumpy
import thorvg_capi
import engine, canvas, paint, scene
export vmath, chroma, bumpy, engine, paint, canvas, scene

type
  ShapeObj* = object of PaintObj
  Shape* = ref ShapeObj
    ## A class representing two-dimensional figures and their properties.
    ## 
    ## A shape has three major properties: shape outline, stroking, and filling. 
    ## The outline is retained as a path composed by accumulating primitive commands 
    ## or helper interfaces.

type PathBuilder* = object
  ## A fluent interface builder to chain path commands together for a Shape.
  shape: Shape

proc newShape*(): Shape =
  ## Creates a new Shape object.
  ## 
  ## Raises `ThorVGError` if allocation fails.
  let handle = tvgShapeNew()
  if handle == nil:
    raise newException(ThorVGError, "Failed to create shape")
  result = Shape(handle: handle)
  discard tvgPaintRef(handle)

proc reset*(shape: Shape) =
  ## Resets the shape path.
  ## 
  ## The transformation matrix, color, fill, and stroke properties are retained.
  ## Memory is kept allocated for caching purposes.
  checkResult(tvgShapeReset(shape.handle))

proc init*(shape: var Shape, scene: Scene, reset: bool = true): bool {.discardable.} =
  ## Initializes the shape within a scene. If the shape is unallocated,
  ## it creates a new one and pushes it to the scene. If it already exists and `reset` is true, 
  ## it clears the path geometry.
  if shape == nil or shape.handle == nil:
    shape = newShape()
    scene.push(shape)
    result = true
  elif reset:
    shape.reset()

proc moveTo*(shape: Shape, x, y: float) =
  ## Sets the initial point of a new sub-path and sets the current point to `(x, y)`.
  checkResult(tvgShapeMoveTo(shape.handle, x.cfloat, y.cfloat))

proc lineTo*(shape: Shape, x, y: float) =
  ## Adds a new point to the sub-path, drawing a straight line from the current 
  ## point to `(x, y)`. Sets the new current point to `(x, y)`.
  ## If this is the first command in a path, it acts like a `moveTo`.
  checkResult(tvgShapeLineTo(shape.handle, x.cfloat, y.cfloat))

proc cubicTo*(shape: Shape, cx1, cy1, cx2, cy2, x, y: float) =
  ## Adds points to the sub-path, drawing a cubic Bezier curve starting from the 
  ## current point and ending at `(x, y)` using control points `(cx1, cy1)` and `(cx2, cy2)`.
  ## Sets the new current point to `(x, y)`.
  checkResult(
    tvgShapeCubicTo(
      shape.handle, cx1.cfloat, cy1.cfloat, cx2.cfloat, cy2.cfloat, x.cfloat, y.cfloat
    )
  )

proc close*(shape: Shape) =
  ## Closes the current sub-path by drawing a line from the current point back to 
  ## the initial point of the sub-path. Has no effect if the sub-path is empty.
  checkResult(tvgShapeClose(shape.handle))

proc addRect*(
    shape: Shape,
    x, y, width, height: float,
    rx: float = 0,
    ry: float = 0,
    clockwise: bool = true,
) =
  ## Appends a rectangle to the path as a new separate sub-path.
  ## `rx` and `ry` specify the radii of the ellipse defining the corner rounding.
  ## `clockwise` specifies the winding path direction.
  checkResult(
    tvgShapeAppendRect(
      shape.handle, x.cfloat, y.cfloat, width.cfloat, height.cfloat, rx.cfloat,
      ry.cfloat, clockwise,
    )
  )

proc addCircle*(shape: Shape, cx, cy: float, rx, ry: float, clockwise: bool = true) =
  ## Appends an ellipse to the path as a new separate sub-path.
  ## `cx` and `cy` mark the center, while `rx` and `ry` represent the horizontal and vertical radii.
  checkResult(
    tvgShapeAppendCircle(
      shape.handle, cx.cfloat, cy.cfloat, rx.cfloat, ry.cfloat, clockwise
    )
  )

proc addCircle*(shape: Shape, center: Vec2, radius: float, clockwise: bool = true) =
  ## Appends a uniform circle centered at `center` with the given `radius` to the path.
  shape.addCircle(center.x, center.y, radius, radius, clockwise)

proc add*(
    shape: var Shape,
    dims: Rect | Circle,
    rx: float = 0,
    ry: float = 0,
    clockwise: bool = true,
): Shape {.discardable.} =
  ## High-level geometric adapter to append either a `Rect` or a `Circle` bounding box 
  ## primitive directly into the Shape's internal path representation.
  when dims is Rect:
    shape.addRect(dims.x, dims.y, dims.w, dims.h, rx, ry, clockwise)
  elif dims is Circle:
    shape.addCircle(dims.pos.x, dims.pos.y, dims.radius, dims.radius, clockwise)
  result = shape

proc setFillColor*(shape: Shape, color: SomeColor) =
  ## Sets the solid RGBA fill color for all figures inside the path using a color type.
  let rgba = color.asRgba()
  checkResult(tvgShapeSetFillColor(shape.handle, rgba.r, rgba.g, rgba.b, rgba.a))

proc setFillColor*(shape: Shape, r, g, b: uint8, a: uint8 = 255) =
  ## Sets the solid color channel values `[0 ~ 255]` for all interior regions of the path.
  ## This overrides any previously set gradient fill.
  checkResult(tvgShapeSetFillColor(shape.handle, r, g, b, a))

proc getFillColor*(shape: Shape): ColorRGBA =
  ## Retrieves the solid RGBA color channels of the shape fill.
  var r, g, b, a: uint8
  checkResult(tvgShapeGetFillColor(shape.handle, addr r, addr g, addr b, addr a))
  result = rgba(r, g, b, a)

proc setFillRule*(shape: Shape, rule: TvgFillRule) =
  ## Sets the fill rule used to determine how intersecting/overlapping paths calculate 
  ## interior regions. The default is `FillRule::NonZero`.
  checkResult(tvgShapeSetFillRule(shape.handle, rule))

proc getFillRule*(shape: Shape): TvgFillRule =
  ## Retrieves the current fill rule applied to the shape.
  checkResult(tvgShapeGetFillRule(shape.handle, addr result))

proc setStrokeWidth*(shape: Shape, width: float) =
  ## Sets the stroke thickness in pixels. Must be a positive value.
  ## A thickness value of `0.0` disables stroke rendering.
  checkResult(tvgShapeSetStrokeWidth(shape.handle, width.cfloat))

proc getStrokeWidth*(shape: Shape): float =
  ## Gets the current stroke width thickness. Returns `0.0` if no stroke was set.
  var width: cfloat
  checkResult(tvgShapeGetStrokeWidth(shape.handle, addr width))
  result = width.float

proc setStrokeColor*(shape: Shape, color: SomeColor) =
  ## Sets the stroke outline RGBA color utilizing a structured color object.
  let rgba = color.asRgba()
  checkResult(tvgShapeSetStrokeColor(shape.handle, rgba.r, rgba.g, rgba.b, rgba.a))

proc setStrokeColor*(shape: Shape, r, g, b: uint8, a: uint8 = 255) =
  ## Sets the outline RGBA color channels `[0 ~ 255]`. Note that if the stroke width 
  ## is 0, the stroke path will remain invisible regardless of this color.
  checkResult(tvgShapeSetStrokeColor(shape.handle, r, g, b, a))

proc getStrokeColor*(shape: Shape): ColorRGBA =
  ## Retrieves the current color channels assigned to the shape's stroke outline.
  var r, g, b, a: uint8
  checkResult(tvgShapeGetStrokeColor(shape.handle, addr r, addr g, addr b, addr a))
  result = rgba(r, g, b, a)

proc setStrokeCap*(shape: Shape, cap: TvgStrokeCap) =
  ## Sets the cap style applied to the ends of open path segments. 
  ## The default style is `StrokeCap::Square`.
  checkResult(tvgShapeSetStrokeCap(shape.handle, cap))

proc getStrokeCap*(shape: Shape): TvgStrokeCap =
  ## Gets the cap style type used for open sub-paths on the shape stroke.
  checkResult(tvgShapeGetStrokeCap(shape.handle, addr result))

proc setStrokeJoin*(shape: Shape, join: TvgStrokeJoin) =
  ## Sets the style used for joining connecting path segments. 
  ## The default value is `StrokeJoin::Bevel`.
  checkResult(tvgShapeSetStrokeJoin(shape.handle, join))

proc getStrokeJoin*(shape: Shape): TvgStrokeJoin =
  ## Gets the join style value used for path segment corners.
  checkResult(tvgShapeGetStrokeJoin(shape.handle, addr result))

proc setStrokeMiterLimit*(shape: Shape, limit: float) =
  ## Sets the miter limit constraint on the extent of sharp corner joins. 
  ## Only applied when using the `StrokeJoin::Miter` style. Default is `4.0`.
  ## Raises error if limit is negative.
  checkResult(tvgShapeSetStrokeMiterlimit(shape.handle, limit.cfloat))

proc getStrokeMiterLimit*(shape: Shape): float =
  ## Gets the current stroke miter limit. Returns `4.0` if no stroke was configured.
  var limit: cfloat
  checkResult(tvgShapeGetStrokeMiterlimit(shape.handle, addr limit))
  result = limit.float

proc setStrokeDashInternal(shape: Shape, dash: seq[cfloat], offset: float) =
  if dash.len > 0:
    checkResult(
      tvgShapeSetStrokeDash(
        shape.handle, unsafeAddr dash[0], dash.len.uint32, offset.cfloat
      )
    )
  else:
    checkResult(tvgShapeSetStrokeDash(shape.handle, nil, 0, offset.cfloat))

proc setStrokeDash*(shape: Shape, dash: seq[float], offset: float = 0.0) =
  ## Sets the dash pattern sequence of alternating dash and gap lengths.
  ## Pass an empty sequence to clear the dash pattern configuration.
  ## Values less than or equal to zero are skipped or ignored.
  let cfloatDash = dash.mapIt(it.cfloat)
  shape.setStrokeDashInternal(cfloatDash, offset)

proc getStrokeDash*(shape: Shape): tuple[dash: seq[float], offset: float] =
  ## Retrieves the dash pattern lengths array along with the shift sequence offset value.
  var dashPtr: ptr cfloat
  var cnt: uint32
  var offset: cfloat
  checkResult(
    tvgShapeGetStrokeDash(shape.handle, addr dashPtr, addr cnt, addr offset)
  )

  var resDash = newSeq[float](cnt)
  if cnt > 0 and dashPtr != nil:
    let arr = cast[ptr UncheckedArray[cfloat]](dashPtr)
    for i in 0 ..< cnt:
      resDash[i] = arr[i].float
  result = (dash: resDash, offset: offset.float)

proc setTrimPath*(shape: Shape, start, finish: float, simultaneous: bool = true) =
  ## Trims visibility of the path to a segment range between `start` and `finish` (0.0 to 1.0).
  ## Values outside the standard range wrap around circularly.
  ## `simultaneous` defines if individual sub-paths trim in parallel or treat the shape as one sequential path.
  checkResult(
    tvgShapeSetTrimpath(shape.handle, start.cfloat, finish.cfloat, simultaneous)
  )

proc setPaintOrder*(shape: Shape, strokeFirst: bool) =
  ## Sets whether the stroke outline is rendered underneath the fill (`strokeFirst = true`), 
  ## or rendered over the top of the fill layer (`strokeFirst = false`).
  checkResult(tvgShapeSetPaintOrder(shape.handle, strokeFirst))

proc path*(shape: Shape): PathBuilder =
  ## Returns a `PathBuilder` targeting this Shape to begin constructing paths fluently.
  PathBuilder(shape: shape)

proc moveTo*(builder: var PathBuilder, x, y: float): var PathBuilder {.discardable.} =
  ## Fluent API to set the initial point of a sub-path.
  builder.shape.moveTo(x, y)
  result = builder

proc lineTo*(builder: var PathBuilder, x, y: float): var PathBuilder {.discardable.} =
  ## Fluent API to append a line segment to the path.
  builder.shape.lineTo(x, y)
  result = builder

proc cubicTo*(
    builder: var PathBuilder, cx1, cy1, cx2, cy2, x, y: float
): var PathBuilder {.discardable.} =
  ## Fluent API to append a cubic Bezier curve segment to the path.
  builder.shape.cubicTo(cx1, cy1, cx2, cy2, x, y)
  result = builder

proc close*(builder: var PathBuilder): var PathBuilder {.discardable.} =
  ## Fluent API to close the current active sub-path sequence back to its origin.
  builder.shape.close()
  result = builder

proc rect*(
    builder: var PathBuilder, x, y, width, height: float, rx: float = 0, ry: float = 0
): var PathBuilder {.discardable.} =
  ## Fluent API to append a rectangular shape geometry with optional rounded corners.
  builder.shape.addRect(x, y, width, height, rx, ry)
  result = builder

proc circle*(
    builder: var PathBuilder, center: Vec2, radius: float
): var PathBuilder {.discardable.} =
  ## Fluent API to append a full uniform circle at the target position coordinates.
  builder.shape.addCircle(center, radius)
  result = builder

proc ellipse*(
    builder: var PathBuilder, center: Vec2, rx, ry: float
): var PathBuilder {.discardable.} =
  ## Fluent API to append an ellipse geometry with varying horizontal/vertical radii.
  builder.shape.addCircle(center.x, center.y, rx, ry)
  result = builder

proc newRect*(x, y, width, height: float, rx: float = 0, ry: float = 0): Shape =
  ## Constructor helper allocating a new Shape containing a pre-populated rectangle path.
  result = newShape()
  result.addRect(x, y, width, height, rx, ry)

proc newCircle*(center: Vec2, radius: float): Shape =
  ## Constructor helper allocating a new Shape containing a pre-populated uniform circle path.
  result = newShape()
  result.addCircle(center, radius)

proc newEllipse*(center: Vec2, rx, ry: float): Shape =
  ## Constructor helper allocating a new Shape containing a pre-populated ellipse path.
  result = newShape()
  result.addCircle(center.x, center.y, rx, ry)

proc fill*(shape: Shape, color: SomeColor): Shape {.discardable.} =
  ## Inline convenience wrapper to set the fill color and return the original shape reference.
  shape.setFillColor(color)
  result = shape

proc fill*(shape: Shape, r, g, b: uint8, a: uint8 = 255): Shape {.discardable.} =
  ## Inline convenience wrapper to set direct RGBA fill channel properties.
  shape.setFillColor(r, g, b, a)
  result = shape

proc stroke*(
    shape: Shape, color: SomeColor, width: float = 1.0
): Shape {.discardable.} =
  ## Inline convenience wrapper to set stroke outline color and line thickness values simultaneously.
  shape.setStrokeColor(color)
  shape.setStrokeWidth(width)
  result = shape

proc stroke*(
    shape: Shape, r, g, b: uint8, width: float = 1.0, a: uint8 = 255
): Shape {.discardable.} =
  ## Inline convenience wrapper to configure basic raw RGBA channel attributes along with stroke width.
  shape.setStrokeColor(r, g, b, a)
  shape.setStrokeWidth(width)
  result = shape

proc strokeWidth*(shape: Shape, width: float): Shape {.discardable.} =
  ## Inline convenience wrapper modifying structural stroke thickness rules.
  shape.setStrokeWidth(width)
  result = shape
