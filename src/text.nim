import thorvg_capi
import engine, paint, shape, gradient

type
  TextObj* = object of PaintObj

  Text* = ref TextObj

  TextMetrics* = TvgTextMetrics
  GlyphMetrics* = TvgGlyphMetrics

proc newText*(): Text =
  let h = tvgTextNew()
  if h == nil:
    raise newException(ThorVGError, "Failed to create ThorVG Text object")
  result = Text(handle: h)
  discard tvgPaintRef(h)

proc `font=`*(text: Text, name: string) =
  let fontName = if name.len == 0: nil else: name.cstring
  checkResult(tvgTextSetFont(text.handle, fontName))

proc font*(text: Text, name: string): Text {.discardable, inline.} =
  text.font = name
  result = text

proc `size=`*(text: Text, size: float) =
  if not (size > 0.0) or size == Inf:
    raise newException(ValueError, "Font size must be a valid, finite positive number")
  checkResult(tvgTextSetSize(text.handle, size.cfloat))

proc size*(text: Text, size: float): Text {.discardable, inline.} =
  text.size = size
  result = text

proc `text=`*(text: Text, utf8: string) =
  checkResult(tvgTextSetText(text.handle, utf8.cstring))

proc text*(text: Text, utf8: string): Text {.discardable, inline.} =
  text.text = utf8
  result = text

proc text*(text: Text): string =
  let res = tvgTextGetText(text.handle)
  if res != nil:
    result = $res

proc align*(text: Text, x, y: float): Text {.discardable, inline.} =
  checkResult(tvgTextAlign(text.handle, x.cfloat, y.cfloat))
  result = text

proc layout*(text: Text, w, h: float): Text {.discardable, inline.} =
  checkResult(tvgTextLayout(text.handle, w.cfloat, h.cfloat))
  result = text

proc `wrapMode=`*(text: Text, mode: TvgTextWrap) =
  checkResult(tvgTextWrapMode(text.handle, mode))

proc wrapMode*(text: Text, mode: TvgTextWrap): Text {.discardable, inline.} =
  text.wrapMode = mode
  result = text

proc lineCount*(text: Text): uint32 {.inline.} =
  result = tvgTextLineCount(text.handle).uint32

proc spacing*(text: Text, letter, line: float): Text {.discardable, inline.} =
  if letter < 0.0 or line < 0.0:
    raise newException(ValueError, "Spacing scale factors must be >= 0.0")
  checkResult(tvgTextSpacing(text.handle, letter.cfloat, line.cfloat))
  result = text

proc `italic=`*(text: Text, shear: float) =
  checkResult(tvgTextSetItalic(text.handle, shear.cfloat))

proc italic*(text: Text, shear: float = 0.18): Text {.discardable, inline.} =
  text.italic = shear
  result = text

proc outline*(
    text: Text, width: float, color: ColorRGBA
): Text {.discardable, inline.} =
  checkResult(tvgTextSetOutline(text.handle, width.cfloat, color.r, color.g, color.b))
  result = text

proc outline*(text: Text, width: float, r, g, b: uint8): Text {.discardable, inline.} =
  checkResult(tvgTextSetOutline(text.handle, width.cfloat, r, g, b))
  result = text

proc `color=`*(text: Text, color: ColorRGBA) =
  checkResult(tvgTextSetColor(text.handle, color.r, color.g, color.b))

proc color*(text: Text, r, g, b: uint8): Text {.discardable, inline.} =
  checkResult(tvgTextSetColor(text.handle, r, g, b))
  result = text

proc `gradient=`*(text: Text, grad: Gradient) =
  let hGrad = if grad.isNil: nil else: grad.handle
  checkResult(tvgTextSetGradient(text.handle, hGrad))

proc fill*(text: Text, grad: Gradient): Text {.discardable, inline.} =
  text.gradient = grad
  result = text

proc getTextMetrics*(text: Text): TextMetrics =
  checkResult(tvgTextGetTextMetrics(text.handle, addr result))

proc getGlyphMetrics*(text: Text, ch: string): GlyphMetrics =
  if ch.len == 0:
    raise newException(ValueError, "Character string cannot be empty")
  checkResult(tvgTextGetGlyphMetrics(text.handle, ch.cstring, addr result))

proc loadFont*(path: string) =
  if path.len == 0:
    raise newException(ValueError, "Font path cannot be empty")
  checkResult(tvgFontLoad(path.cstring))

proc loadFontData*(
    name: string, data: string, mimetype: string = "ttf", copy: bool = false
) =
  if name.len == 0 or data.len == 0:
    raise newException(ValueError, "Font name and data buffer cannot be empty")
  checkResult(
    tvgFontLoadData(name.cstring, data.cstring, data.len.uint32, mimetype.cstring, copy)
  )

proc unloadFont*(path: string) =
  if path.len == 0:
    raise newException(ValueError, "Font path cannot be empty")
  checkResult(tvgFontUnload(path.cstring))
