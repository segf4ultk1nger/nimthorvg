import std/math
import vmath
import engine
import thorvg_capi

type
  Matrix* = TvgMatrix
  Point* = TvgPoint

type
  PaintObj* {.inheritable.} = object of RootObj
    ## An abstract class for managing graphical elements.
    ##
    ## A graphical element in TVG is any object composed into a Canvas. `Paint`
    ## represents such a graphical object and its behaviors such as duplication,
    ## transformation, and composition. TVG recommends regarding a paint as a set
    ## of volatile commands.
    handle*: TvgPaint

  Paint* = ref PaintObj

proc `=destroy`*(paint: var PaintObj) =
  ## Automatically releases the underlying `TvgPaint` reference when the 
  ## object goes out of scope.
  if paint.handle != nil:
    discard tvgPaintUnref(paint.handle, true)
    paint.handle = nil

proc isNil*(paint: Paint): bool =
  ## Returns `true` if the underlying ThorVG paint handle is null.
  paint.handle == nil

proc newPaint*(handle: TvgPaint): Paint =
  ## Creates a new Nim `Paint` wrapper around an existing raw `TvgPaint` handle.
  ## Increments the reference count of the passed handle.
  if handle == nil:
    raise newException(ThorVGError, "Invalid paint handle")
  result = Paint(handle: handle)
  discard tvgPaintRef(handle)

proc newPicture*(): Paint =
  ## Creates a new picture object.
  ##
  ## Throws a `ThorVGError` if the underlying C engine fails to initialize 
  ## the picture instance.
  let handle = tvgPictureNew()
  if handle == nil:
    raise newException(ThorVGError, "Failed to create picture")
  result = Paint(handle: handle)
  discard tvgPaintRef(handle)

proc `visible=`*(paint: Paint, on: bool) =
  ## Sets the visibility of the `Paint` object.
  ##
  ## An invisible object is not considered inactive—it may still participate 
  ## in internal update processing if its properties are updated, but it will 
  ## not be rendered by the engine.
  checkResult(tvgPaintSetVisible(paint.handle, on))

proc visible*(paint: Paint): bool =
  ## Gets the current visibility status of the `Paint` object.
  ##
  ## Returns `true` if the object is visible and will be rendered, `false` otherwise.
  result = tvgPaintGetVisible(paint.handle)

proc `opacity=`*(paint: Paint, opacity: uint8) =
  ## Sets the opacity of the object.
  ##
  ## `opacity` must be in the range `[0 .. 255]`, where 0 is completely 
  ## transparent and 255 is opaque.
  ##
  ## .. note:: Setting the opacity with this API may require multiple render 
  ##    passes for composition. Avoid changing it frequently if possible.
  checkResult(tvgPaintSetOpacity(paint.handle, opacity))

proc opacity*(paint: Paint): uint8 =
  ## Gets the opacity value of the object.
  ##
  ## Returns the opacity value in the range `[0 .. 255]`.
  var op: uint8
  checkResult(tvgPaintGetOpacity(paint.handle, addr op))
  result = op

proc scale*(paint: Paint, factor: float) =
  ## Sets the scale value of the object.
  ##
  ## `factor` defaults to 1.0. 
  ## Throws an error in case a custom matrix transform is already applied.
  checkResult(tvgPaintScale(paint.handle, factor.cfloat))

proc rotate*(paint: Paint, degrees: float) =
  ## Sets the angle by which the object is rotated clockwise in degrees.
  ##
  ## The rotational axis passes through the point on the object with zero coordinates.
  ## Throws an error in case a custom matrix transform is already applied.
  checkResult(tvgPaintRotate(paint.handle, degrees.cfloat))

proc translate*(paint: Paint, x, y: float) =
  ## Sets the values by which the object is moved in a two-dimensional space.
  ##
  ## The origin is in the upper-left corner of the canvas. 
  ## Throws an error in case a custom matrix transform is already applied.
  checkResult(tvgPaintTranslate(paint.handle, x.cfloat, y.cfloat))

proc translate*(paint: Paint, v: Vec2) =
  ## Sets the values by which the object is moved using a 2D vector (`Vec2`).
  checkResult(tvgPaintTranslate(paint.handle, v.x.cfloat, v.y.cfloat))

proc `transform=`*(paint: Paint, transform: Matrix) =
  ## Sets the 3x3 augmented matrix of the affine transformation for the object.
  var m = transform
  checkResult(tvgPaintSetTransform(paint.handle, addr m))

proc transform*(paint: Paint): Matrix =
  ## Gets the matrix of the affine transformation of the object.
  ##
  ## In case no transformation was applied, the identity matrix is returned.
  checkResult(tvgPaintGetTransform(paint.handle, addr result))

proc mask*(paint: Paint, target: Paint, maskMethod: TvgMaskMethod) =
  ## Sets the masking target object and the masking method.
  ##
  ## Throws an error if the target already belongs to another paint, or if 
  ## `maskMethod` is set to None while `target` is not nil.
  checkResult(tvgPaintSetMaskMethod(paint.handle, target.handle, maskMethod))

proc getMaskMethod*(paint: Paint, target: Paint): TvgMaskMethod =
  ## Gets the masking target object and the masking method used.
  checkResult(tvgPaintGetMaskMethod(paint.handle, target.handle, addr result))

proc clip*(paint: Paint, clipper: Paint) =
  ## Clips the drawing region of the paint object.
  ##
  ## This function restricts the drawing area of the paint object to the 
  ## specified clipper shape's paths.
  checkResult(tvgPaintSetClip(paint.handle, clipper.handle))

proc clipper*(paint: Paint): Paint =
  ## Gets the clipper paint object that has been previously set to this paint.
  ##
  ## Returns `nil` if no clipper is set.
  let h = tvgPaintGetClip(paint.handle)
  if h != nil:
    result = newPaint(h)

proc blend*(paint: Paint, blendMethod: TvgBlendMethod) =
  ## Sets the blending method for the paint object.
  ##
  ## The blending feature allows combining colors of the source paint object with 
  ## the destination (lower layer image) using specified blending operations.
  checkResult(tvgPaintSetBlendMethod(paint.handle, blendMethod))

proc bounds*(paint: Paint): tuple[x, y, w, h: float] =
  ## Retrieves the axis-aligned bounding box (AABB) of the paint object 
  ## in canvas space.
  ##
  ## Returns the bounding box with all relevant transformations applied. 
  ## Useful for hit-testing, culling, or layout calculations.
  var x, y, w, h: cfloat
  checkResult(tvgPaintGetAabb(paint.handle, addr x, addr y, addr w, addr h))
  result = (x.float, y.float, w.float, h.float)

proc boundsObb*(paint: Paint): array[4, Point] =
  ## Retrieves the object-oriented bounding box (OBB) of the paint object 
  ## in canvas space.
  ##
  ## Returns an array of four points representing the transformed bounding region.
  checkResult(tvgPaintGetObb(paint.handle, addr result[0]))

proc intersects*(paint: Paint, x, y, w, h: int32): bool =
  ## Checks whether a given rectangular region intersects the filled area of the paint.
  ##
  ## Useful for hit-testing (e.g., mouse clicks). To test a single point, set 
  ## `w = 1` and `h = 1`. This test accounts for hidden paints but ignores blending or masking.
  result = tvgPaintIntersects(paint.handle, x, y, w, h)

proc parent*(paint: Paint): Paint =
  ## Retrieves the parent paint object if the current paint belongs to one.
  ##
  ## Returns `nil` if no parent is available.
  let h = tvgPaintGetParent(paint.handle)
  if h != nil:
    result = newPaint(h)

proc duplicate*(paint: Paint): Paint =
  ## Duplicates the object.
  ##
  ## Creates a new paint instance and copies all properties from the original object.
  let newHandle = tvgPaintDuplicate(paint.handle)
  if newHandle == nil:
    raise newException(ThorVGError, "Failed to duplicate paint")
  result = Paint(handle: newHandle)

proc load*(picture: Paint, path: string) =
  ## Loads a picture engine file from the specified system path.
  checkResult(tvgPictureLoad(picture.handle, path.cstring))

proc size*(picture: Paint): tuple[w, h: float] =
  ## Gets the width and height dimensions of the picture element.
  var w, h: cfloat
  checkResult(tvgPictureGetSize(picture.handle, addr w, addr h))
  result = (w.float, h.float)

proc insert*(scene: Paint, target: Paint, at: Paint) =
  ## Inserts a `target` paint into a `scene` layout relative to another `at` element.
  checkResult(tvgSceneInsert(scene.handle, target.handle, at.handle))

proc remove*(scene: Paint, paint: Paint) =
  ## Removes the given `paint` element out of the specified `scene`.
  checkResult(tvgSceneRemove(scene.handle, paint.handle))

proc matrix*(e11, e12, e13, e21, e22, e23, e31, e32, e33: float): Matrix =
  ## Helper to construct a raw 3x3 augmented ThorVG Matrix configuration layout.
  Matrix(
    e11: e11.cfloat,
    e12: e12.cfloat,
    e13: e13.cfloat,
    e21: e21.cfloat,
    e22: e22.cfloat,
    e23: e23.cfloat,
    e31: e31.cfloat,
    e32: e32.cfloat,
    e33: e33.cfloat,
  )

proc identityMatrix*(): Matrix =
  ## Returns a brand new standard default identity Matrix mapping frame.
  matrix(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0)

proc translationMatrix*(x, y: float): Matrix =
  ## Generates a dedicated translation Matrix instance shift mapping `x` and `y`.
  result = identityMatrix()
  result.e13 = x.cfloat
  result.e23 = y.cfloat

proc scaleMatrix*(sx, sy: float): Matrix =
  ## Generates a structural scale transformation Matrix representation.
  result = identityMatrix()
  result.e11 = sx.cfloat
  result.e22 = sy.cfloat

proc rotationMatrix*(degrees: float): Matrix =
  ## Generates a standard rotational Matrix setup angled clockwise from the horizon.
  let radians = degrees * PI / 180.0
  let cos_val = cos(radians).cfloat
  let sin_val = sin(radians).cfloat
  matrix(cos_val, -sin_val, 0.0, sin_val, cos_val, 0.0, 0.0, 0.0, 1.0)

proc `*`*(a, b: Matrix): Matrix =
  ## Performs a mathematical 3x3 matrix multiplication sequence of mapping structures `a` and `b`.
  result.e11 = a.e11 * b.e11 + a.e12 * b.e21 + a.e13 * b.e31
  result.e12 = a.e11 * b.e12 + a.e12 * b.e22 + a.e13 * b.e32
  result.e13 = a.e11 * b.e13 + a.e12 * b.e23 + a.e13 * b.e33

  result.e21 = a.e21 * b.e11 + a.e22 * b.e21 + a.e23 * b.e31
  result.e22 = a.e21 * b.e12 + a.e22 * b.e22 + a.e23 * b.e32
  result.e23 = a.e21 * b.e13 + a.e22 * b.e23 + a.e23 * b.e33

  result.e31 = a.e31 * b.e11 + a.e32 * b.e21 + a.e33 * b.e31
  result.e32 = a.e31 * b.e12 + a.e32 * b.e22 + a.e33 * b.e32
  result.e33 = a.e31 * b.e13 + a.e32 * b.e23 + a.e33 * b.e33
