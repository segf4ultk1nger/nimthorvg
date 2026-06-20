import thorvg_capi
import paint, canvas, engine

type
  PictureObj* = object of Paint
  Picture* = ref PictureObj

proc `=destroy`(obj: var PictureObj) =
  if obj.handle != nil:
    discard tvgPaintUnref(obj.handle, true) 
    obj.handle = nil

proc newPicture*(): Picture =
  let h = tvgPictureNew()
  if h == nil:
    raise newException(ThorVGError, "Failed to create ThorVG Picture object")
  result = Picture(handle: h)

proc load*(picture: Picture, path: string): Picture {.discardable, inline.} =
  if path.len == 0:
    raise newException(ValueError, "Path cannot be empty")
  checkResult(tvgPictureLoad(picture.handle, path.cstring))
  result = picture

proc loadRaw*(
    picture: Picture, data: ptr uint32, w, h: uint32, cs: Colorspace, copy: bool = false
): Picture {.discardable, inline.} =
  if data == nil or w <= 0 or h <= 0:
    raise newException(ValueError, "Invalid raw image data dimensions or null pointer")

  checkResult(
    tvgPictureLoadRaw(
      picture.handle,
      cast[ptr uint32](data),
      w.uint32,
      h.uint32,
      cs.toTvgColorspace(),
      copy,
    )
  )
  result = picture

proc loadData*(
    picture: Picture,
    data: string,
    mimetype: string,
    rpath: string = "",
    copy: bool = false,
): Picture {.discardable, inline.} =
  if data.len == 0:
    raise newException(ValueError, "Data buffer cannot be empty")

  let rpathStr = if rpath.len == 0: nil else: rpath.cstring
  checkResult(
    tvgPictureLoadData(
      picture.handle, data.cstring, data.len.uint32, mimetype.cstring, rpathStr, copy
    )
  )
  result = picture

proc setAssetResolver*(
    picture: Picture, resolver: TvgPictureAssetResolver, userData: pointer = nil
): Picture {.discardable, inline.} =
  checkResult(tvgPictureSetAssetResolver(picture.handle, resolver, userData))
  result = picture

proc `size=`*(picture: Picture, size: tuple[w, h: float]) =
  checkResult(tvgPictureSetSize(picture.handle, size.w.cfloat, size.h.cfloat))

proc size*(picture: Picture, w, h: float): Picture {.discardable, inline.} =
  picture.size = (w, h)
  result = picture

proc size*(picture: Picture): tuple[w, h: float] =
  var w, h: cfloat
  checkResult(tvgPictureGetSize(picture.handle, addr w, addr h))
  result = (w.float, h.float)

proc `origin=`*(picture: Picture, origin: tuple[x, y: float]) =
  checkResult(tvgPictureSetOrigin(picture.handle, origin.x.cfloat, origin.y.cfloat))

proc origin*(picture: Picture, x, y: float): Picture {.discardable, inline.} =
  picture.origin = (x, y)
  result = picture

proc origin*(picture: Picture): tuple[x, y: float] =
  var x, y: cfloat
  checkResult(tvgPictureGetOrigin(picture.handle, addr x, addr y))
  result = (x.float, y.float)

proc getPaint*(picture: Picture, id: uint32): Paint =
  let hPaint = tvgPictureGetPaint(picture.handle, id.uint32)
  if hPaint != nil:
    discard tvgPaintRef(hPaint)
    result = Paint(handle: hPaint)

proc `accessible=`*(picture: Picture, accessible: bool) =
  checkResult(tvgPictureSetAccessible(picture.handle, accessible))

proc `filter=`*(picture: Picture, filterMethod: TvgFilterMethod) =
  checkResult(tvgPictureSetFilter(picture.handle, filterMethod))
