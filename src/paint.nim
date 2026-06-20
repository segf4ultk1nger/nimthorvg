import std/math
import chroma
import vmath

export chroma

import engine
import thorvg_capi

type
  Matrix* = TvgMatrix
  Point* = TvgPoint

type Paint* = object of RootObj
  handle*: TvgPaint

proc `=destroy`*(paint: Paint) =
  if paint.handle != nil:
    discard tvgPaintUnref(paint.handle, true)

proc `=copy`*(dest: var Paint, src: Paint) =
  if dest.handle == src.handle: return
  if dest.handle != nil:
    discard tvgPaintUnref(dest.handle, true)
  dest.handle = src.handle
  if dest.handle != nil:
    discard tvgPaintRef(dest.handle)

proc isNil*(paint: Paint): bool =
  paint.handle == nil

proc newPaint*(handle: TvgPaint): Paint =
  if handle == nil:
    raise newException(ThorVGError, "Invalid paint handle")
  result = Paint(handle: handle)
  discard tvgPaintRef(handle)

proc newPicture*(): Paint =
  let handle = tvgPictureNew()
  if handle == nil:
    raise newException(ThorVGError, "Failed to create picture")
  result = Paint(handle: handle)
  discard tvgPaintRef(handle)

proc `visible=`*(paint: Paint, on: bool) =
  checkResult(tvgPaintSetVisible(paint.handle, on))

proc visible*(paint: Paint): bool =
  result = tvgPaintGetVisible(paint.handle)

proc `opacity=`*(paint: Paint, opacity: uint8) =
  checkResult(tvgPaintSetOpacity(paint.handle, opacity))

proc opacity*(paint: Paint): uint8 =
  var op: uint8
  checkResult(tvgPaintGetOpacity(paint.handle, addr op))
  result = op

proc scale*(paint: Paint, factor: float) =
  checkResult(tvgPaintScale(paint.handle, factor.cfloat))

proc rotate*(paint: Paint, degrees: float) =
  checkResult(tvgPaintRotate(paint.handle, degrees.cfloat))

proc translate*(paint: Paint, x, y: float) =
  checkResult(tvgPaintTranslate(paint.handle, x.cfloat, y.cfloat))

proc translate*(paint: Paint, v: Vec2) =
  checkResult(tvgPaintTranslate(paint.handle, v.x.cfloat, v.y.cfloat))

proc `transform=`*(paint: Paint, transform: Matrix) =
  var m = transform
  checkResult(tvgPaintSetTransform(paint.handle, addr m))

proc transform*(paint: Paint): Matrix =
  checkResult(tvgPaintGetTransform(paint.handle, addr result))

proc mask*(paint: Paint, target: Paint, maskMethod: TvgMaskMethod) =
  checkResult(tvgPaintSetMaskMethod(paint.handle, target.handle, maskMethod))

proc getMaskMethod*(paint: Paint, target: Paint): TvgMaskMethod =
  checkResult(tvgPaintGetMaskMethod(paint.handle, target.handle, addr result))

proc clip*(paint: Paint, clipper: Paint) =
  checkResult(tvgPaintSetClip(paint.handle, clipper.handle))

proc clipper*(paint: Paint): Paint =
  let h = tvgPaintGetClip(paint.handle)
  if h != nil:
    result = newPaint(h)

proc blend*(paint: Paint, blendMethod: TvgBlendMethod) =
  checkResult(tvgPaintSetBlendMethod(paint.handle, blendMethod))

proc bounds*(paint: Paint): tuple[x, y, w, h: float] =
  var x, y, w, h: cfloat
  checkResult(tvgPaintGetAabb(paint.handle, addr x, addr y, addr w, addr h))
  result = (x.float, y.float, w.float, h.float)

proc boundsObb*(paint: Paint): array[4, Point] =
  checkResult(tvgPaintGetObb(paint.handle, addr result[0]))

proc intersects*(paint: Paint, x, y, w, h: int32): bool =
  result = tvgPaintIntersects(paint.handle, x, y, w, h)

proc parent*(paint: Paint): Paint =
  let h = tvgPaintGetParent(paint.handle)
  if h != nil:
    result = newPaint(h)

proc duplicate*(paint: Paint): Paint =
  let newHandle = tvgPaintDuplicate(paint.handle)
  if newHandle == nil:
    raise newException(ThorVGError, "Failed to duplicate paint")
  result = Paint(handle: newHandle)

proc load*(picture: Paint, path: string) =
  checkResult(tvgPictureLoad(picture.handle, path.cstring))

proc size*(picture: Paint): tuple[w, h: float] =
  var w, h: cfloat
  checkResult(tvgPictureGetSize(picture.handle, addr w, addr h))
  result = (w.float, h.float)

proc insert*(scene: Paint, target: Paint, at: Paint) =
  checkResult(tvgSceneInsert(scene.handle, target.handle, at.handle))

proc remove*(scene: Paint, paint: Paint) =
  checkResult(tvgSceneRemove(scene.handle, paint.handle))

proc matrix*(e11, e12, e13, e21, e22, e23, e31, e32, e33: float): Matrix =
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
  matrix(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0)

proc translationMatrix*(x, y: float): Matrix =
  result = identityMatrix()
  result.e13 = x.cfloat
  result.e23 = y.cfloat

proc scaleMatrix*(sx, sy: float): Matrix =
  result = identityMatrix()
  result.e11 = sx.cfloat
  result.e22 = sy.cfloat

proc rotationMatrix*(degrees: float): Matrix =
  let radians = degrees * PI / 180.0
  let cos_val = cos(radians).cfloat
  let sin_val = sin(radians).cfloat
  matrix(cos_val, -sin_val, 0.0, sin_val, cos_val, 0.0, 0.0, 0.0, 1.0)

proc `*`*(a, b: Matrix): Matrix =
  result.e11 = a.e11 * b.e11 + a.e12 * b.e21 + a.e13 * b.e31
  result.e12 = a.e11 * b.e12 + a.e12 * b.e22 + a.e13 * b.e32
  result.e13 = a.e11 * b.e13 + a.e12 * b.e23 + a.e13 * b.e33

  result.e21 = a.e21 * b.e11 + a.e22 * b.e21 + a.e23 * b.e31
  result.e22 = a.e21 * b.e12 + a.e22 * b.e22 + a.e23 * b.e32
  result.e23 = a.e21 * b.e13 + a.e22 * b.e23 + a.e23 * b.e33

  result.e31 = a.e31 * b.e11 + a.e32 * b.e21 + a.e33 * b.e31
  result.e32 = a.e31 * b.e12 + a.e32 * b.e22 + a.e33 * b.e32
  result.e33 = a.e31 * b.e13 + a.e32 * b.e23 + a.e33 * b.e33
