import std/os

when defined(windows):
  const
    ThorvgDll = "libthorvg-1.dll"
elif defined(macosx):
  const
    ThorvgDll = "libthorvg-1.dylib"
else:
  const
    ThorvgDll = "libthorvg-1.so"

when defined(staticThorvg) or defined(TVG_STATIC):
  when defined(windows):
    const currentFile = currentSourcePath()
    const srcDir = parentDir(currentFile)
    const projectRoot = parentDir(srcDir)
    const libsAbsPath = projectRoot / "lib"

    const staticLibPath = libsAbsPath / "libthorvg-1.a"

    {.hint: "Target Static Lib: " & staticLibPath.}

    {.passL: staticLibPath.}
    {.passL: "-lstdc++ -lstdc++fs -fopenmp -static-libgcc".}
  elif defined(macosx):
    {.passL: "-L/opt/homebrew/lib -lthorvg -lc++".}
  else:
    {.passL: "-L/usr/local/lib -lthorvg -lstdc++".}
  {.push cdecl.}
else:  
  {.push dynlib: ThorvgDll.}

type
  tvgCanvas* {.pure.} = object
  tvgPaint* {.pure.} = object
  tvgGradient* {.pure.} = object
  tvgSaver* {.pure.} = object
  tvgAnimation* {.pure.} = object
  tvgAccessor* {.pure.} = object

{.emit: "typedef struct tvgCanvas tvgCanvas;".}
{.emit: "typedef struct tvgPaint tvgPaint;".}
{.emit: "typedef struct tvgGradient tvgGradient;".}
{.emit: "typedef struct tvgSaver tvgSaver;".}
{.emit: "typedef struct tvgAnimation tvgAnimation;".}
{.emit: "typedef struct tvgAccessor tvgAccessor;".}

type TvgCanvas* = pointer

type TvgPaint* = pointer

type TvgGradient* = pointer

type TvgSaver* = pointer

type TvgAnimation* = pointer

type TvgAccessor* = pointer

type TvgResult* = enum
  TVG_RESULT_SUCCESS = 0
  TVG_RESULT_INVALID_ARGUMENT
  TVG_RESULT_INSUFFICIENT_CONDITION
  TVG_RESULT_FAILED_ALLOCATION
  TVG_RESULT_MEMORY_CORRUPTION
  TVG_RESULT_NOT_SUPPORTED
  TVG_RESULT_UNKNOWN = 255

type TvgPoint* {.bycopy.} = object
  x*: cfloat
  y*: cfloat

type TvgMatrix* {.bycopy.} = object
  e11*: cfloat
  e12*: cfloat
  e13*: cfloat
  e21*: cfloat
  e22*: cfloat
  e23*: cfloat
  e31*: cfloat
  e32*: cfloat
  e33*: cfloat

type TvgColorspace* = enum
  TVG_COLORSPACE_ABGR8888 = 0
  TVG_COLORSPACE_ARGB8888
  TVG_COLORSPACE_ABGR8888S
  TVG_COLORSPACE_ARGB8888S
  TVG_COLORSPACE_GRAYSCALE8
  TVG_COLORSPACE_UNKNOWN = 255

type TvgEngineOption* = enum
  TVG_ENGINE_OPTION_NONE = 0
  TVG_ENGINE_OPTION_DEFAULT = 1 shl 0
  TVG_ENGINE_OPTION_SMART_RENDER = 1 shl 1
  TVG_ENGINE_OPTION_ALIASED = 1 shl 2

type TvgMaskMethod* = enum
  TVG_MASK_METHOD_NONE = 0
  TVG_MASK_METHOD_ALPHA
  TVG_MASK_METHOD_INVERSE_ALPHA
  TVG_MASK_METHOD_LUMA
  TVG_MASK_METHOD_INVERSE_LUMA
  TVG_MASK_METHOD_ADD
  TVG_MASK_METHOD_SUBTRACT
  TVG_MASK_METHOD_INTERSECT
  TVG_MASK_METHOD_DIFFERENCE
  TVG_MASK_METHOD_LIGHTEN
  TVG_MASK_METHOD_DARKEN

type TvgBlendMethod* = enum
  TVG_BLEND_METHOD_NORMAL = 0
  TVG_BLEND_METHOD_MULTIPLY
  TVG_BLEND_METHOD_SCREEN
  TVG_BLEND_METHOD_OVERLAY
  TVG_BLEND_METHOD_DARKEN
  TVG_BLEND_METHOD_LIGHTEN
  TVG_BLEND_METHOD_COLORDODGE
  TVG_BLEND_METHOD_COLORBURN
  TVG_BLEND_METHOD_HARDLIGHT
  TVG_BLEND_METHOD_SOFTLIGHT
  TVG_BLEND_METHOD_DIFFERENCE
  TVG_BLEND_METHOD_EXCLUSION
  TVG_BLEND_METHOD_HUE
  TVG_BLEND_METHOD_SATURATION
  TVG_BLEND_METHOD_COLOR
  TVG_BLEND_METHOD_LUMINOSITY
  TVG_BLEND_METHOD_ADD
  TVG_BLEND_METHOD_COMPOSITION = 255

type TvgType* = enum
  TVG_TYPE_UNDEF = 0
  TVG_TYPE_SHAPE
  TVG_TYPE_SCENE
  TVG_TYPE_PICTURE
  TVG_TYPE_TEXT
  TVG_TYPE_LINEAR_GRAD = 10
  TVG_TYPE_RADIAL_GRAD

type TvgPathCommand* = uint8

const
  TVG_PATH_COMMAND_CLOSE* = 0
  TVG_PATH_COMMAND_MOVE_TO* = 1
  TVG_PATH_COMMAND_LINE_TO* = 2
  TVG_PATH_COMMAND_CUBIC_TO* = 3

type TvgStrokeCap* = enum
  TVG_STROKE_CAP_BUTT = 0
  TVG_STROKE_CAP_ROUND
  TVG_STROKE_CAP_SQUARE

type TvgStrokeJoin* = enum
  TVG_STROKE_JOIN_MITER = 0
  TVG_STROKE_JOIN_ROUND
  TVG_STROKE_JOIN_BEVEL

type TvgStrokeFill* = enum
  TVG_STROKE_FILL_PAD = 0
  TVG_STROKE_FILL_REFLECT
  TVG_STROKE_FILL_REPEAT

type TvgFillRule* = enum
  TVG_FILL_RULE_NON_ZERO = 0
  TVG_FILL_RULE_EVEN_ODD

type TvgColorStop* {.bycopy.} = object
  offset*: cfloat

  r*: uint8

  g*: uint8

  b*: uint8

  a*: uint8

type TvgTextWrap* = enum
  TVG_TEXT_WRAP_NONE = 0
  TVG_TEXT_WRAP_CHARACTER
  TVG_TEXT_WRAP_WORD
  TVG_TEXT_WRAP_SMART
  TVG_TEXT_WRAP_ELLIPSIS
  TVG_TEXT_WRAP_HYPHENATION

type TvgFilterMethod* = enum
  TVG_FILTER_METHOD_BILINEAR = 0
  TVG_FILTER_METHOD_NEAREST

type TvgTextMetrics* {.bycopy.} = object
  ascent*: cfloat

  descent*: cfloat

  linegap*: cfloat

  advance*: cfloat

type TvgGlyphMetrics* {.bycopy.} = object
  advance*: cfloat

  bearing*: cfloat

  min*: TvgPoint

  max*: TvgPoint

type TvgPictureAssetResolver* = proc(paint: TvgPaint, src: cstring, data: pointer): bool

proc tvgEngineInit*(threads: cuint): TvgResult {.importc: "tvg_engine_init".}

proc tvgEngineTerm*(): TvgResult {.importc: "tvg_engine_term".}

proc tvgEngineVersion*(
  major: ptr uint32, 
  minor: ptr uint32, 
  micro: ptr uint32, 
  version: ptr cstring
): TvgResult {.importc: "tvg_engine_version".}

proc tvgSwcanvasCreate*(op: TvgEngineOption): TvgCanvas {.importc: "tvg_swcanvas_create".}

proc tvgSwcanvasSetTarget*(
  canvas: TvgCanvas,
  buffer: ptr uint32,
  stride: uint32,
  w: uint32,
  h: uint32,
  cs: TvgColorspace,
): TvgResult {.importc: "tvg_swcanvas_set_target".}

proc tvgCanvasDestroy*(canvas: TvgCanvas): TvgResult {.importc: "tvg_canvas_destroy".}

proc tvgCanvasAdd*(canvas: TvgCanvas, paint: TvgPaint): TvgResult {.importc: "tvg_canvas_add".}

proc tvgCanvasInsert*(canvas: TvgCanvas, target: TvgPaint, at: TvgPaint): TvgResult {.importc: "tvg_canvas_insert".}

proc tvgCanvasRemove*(canvas: TvgCanvas, paint: TvgPaint): TvgResult {.importc: "tvg_canvas_remove".}

proc tvgCanvasUpdate*(canvas: TvgCanvas): TvgResult {.importc: "tvg_canvas_update".}

proc tvgCanvasDraw*(canvas: TvgCanvas, clear: bool): TvgResult {.importc: "tvg_canvas_draw".}

proc tvgCanvasSync*(canvas: TvgCanvas): TvgResult {.importc: "tvg_canvas_sync".}

proc tvgCanvasSetViewport*(
  canvas: TvgCanvas, x: int32, y: int32, w: int32, h: int32
): TvgResult {.importc: "tvg_canvas_set_viewport".}

proc tvgPaintRel*(paint: TvgPaint): TvgResult {.importc: "tvg_paint_rel".}

proc tvgPaintRef*(paint: TvgPaint): uint16 {.importc: "tvg_paint_ref".}

proc tvgPaintUnref*(paint: TvgPaint, free: bool): uint16 {.importc: "tvg_paint_unref".}

proc tvgPaintGetRef*(paint: TvgPaint): uint16 {.importc: "tvg_paint_get_ref".}

proc tvgPaintSetVisible*(
  paint: TvgPaint, visible: bool
): TvgResult {.importc: "tvg_paint_set_visible".}

proc tvgPaintGetVisible*(paint: TvgPaint): bool {.importc: "tvg_paint_get_visible".}

proc tvgPaintGetId*(paint: TvgPaint): uint32 {.importc: "tvg_paint_get_id".}

proc tvgPaintSetId*(
  paint: TvgPaint, id: uint32
): TvgResult {.importc: "tvg_paint_set_id".}

proc tvgPaintScale*(
  paint: TvgPaint, factor: cfloat
): TvgResult {.importc: "tvg_paint_scale".}

proc tvgPaintRotate*(
  paint: TvgPaint, degree: cfloat
): TvgResult {.importc: "tvg_paint_rotate".}

proc tvgPaintTranslate*(
  paint: TvgPaint, x: cfloat, y: cfloat
): TvgResult {.importc: "tvg_paint_translate".}

proc tvgPaintSetTransform*(
  paint: TvgPaint, m: ptr TvgMatrix
): TvgResult {.importc: "tvg_paint_set_transform".}

proc tvgPaintGetTransform*(
  paint: TvgPaint, m: ptr TvgMatrix
): TvgResult {.importc: "tvg_paint_get_transform".}

proc tvgPaintSetOpacity*(
  paint: TvgPaint, opacity: uint8
): TvgResult {.importc: "tvg_paint_set_opacity".}

proc tvgPaintGetOpacity*(
  paint: TvgPaint, opacity: ptr uint8
): TvgResult {.importc: "tvg_paint_get_opacity".}

proc tvgPaintDuplicate*(paint: TvgPaint): TvgPaint {.importc: "tvg_paint_duplicate".}

proc tvgPaintIntersects*(
  paint: TvgPaint, x: int32, y: int32, w: int32, h: int32
): bool {.importc: "tvg_paint_intersects".}

proc tvgPaintGetAabb*(
  paint: TvgPaint, x: ptr cfloat, y: ptr cfloat, w: ptr cfloat, h: ptr cfloat
): TvgResult {.importc: "tvg_paint_get_aabb".}

proc tvgPaintGetObb*(
  paint: TvgPaint, pt4: ptr TvgPoint
): TvgResult {.importc: "tvg_paint_get_obb".}

proc tvgPaintSetMaskMethod*(
  paint: TvgPaint, target: TvgPaint, `method`: TvgMaskMethod
): TvgResult {.importc: "tvg_paint_set_mask_method".}

proc tvgPaintGetMaskMethod*(
  paint: TvgPaint, target: TvgPaint, `method`: ptr TvgMaskMethod
): TvgResult {.importc: "tvg_paint_get_mask_method".}

proc tvgPaintSetClip*(
  paint: TvgPaint, clipper: TvgPaint
): TvgResult {.importc: "tvg_paint_set_clip".}

proc tvgPaintGetClip*(paint: TvgPaint): TvgPaint {.importc: "tvg_paint_get_clip".}

proc tvgPaintGetParent*(paint: TvgPaint): TvgPaint {.importc: "tvg_paint_get_parent".}

proc tvgPaintGetType*(
  paint: TvgPaint, `type`: ptr TvgType
): TvgResult {.importc: "tvg_paint_get_type".}

proc tvgPaintSetBlendMethod*(
  paint: TvgPaint, `method`: TvgBlendMethod
): TvgResult {.importc: "tvg_paint_set_blend_method".}

proc tvgShapeNew*(): TvgPaint {.importc: "tvg_shape_new".}

proc tvgShapeReset*(paint: TvgPaint): TvgResult {.importc: "tvg_shape_reset".}

proc tvgShapeMoveTo*(
  paint: TvgPaint, x: cfloat, y: cfloat
): TvgResult {.importc: "tvg_shape_move_to".}

proc tvgShapeLineTo*(
  paint: TvgPaint, x: cfloat, y: cfloat
): TvgResult {.importc: "tvg_shape_line_to".}

proc tvgShapeCubicTo*(
  paint: TvgPaint,
  cx1: cfloat,
  cy1: cfloat,
  cx2: cfloat,
  cy2: cfloat,
  x: cfloat,
  y: cfloat,
): TvgResult {.importc: "tvg_shape_cubic_to".}

proc tvgShapeClose*(paint: TvgPaint): TvgResult {.importc: "tvg_shape_close".}

proc tvgShapeAppendRect*(
  paint: TvgPaint,
  x: cfloat,
  y: cfloat,
  w: cfloat,
  h: cfloat,
  rx: cfloat,
  ry: cfloat,
  cw: bool,
): TvgResult {.importc: "tvg_shape_append_rect".}

proc tvgShapeAppendCircle*(
  paint: TvgPaint, cx: cfloat, cy: cfloat, rx: cfloat, ry: cfloat, cw: bool
): TvgResult {.importc: "tvg_shape_append_circle".}

proc tvgShapeAppendPath*(
  paint: TvgPaint,
  cmds: ptr TvgPathCommand,
  cmdCnt: uint32,
  pts: ptr TvgPoint,
  ptsCnt: uint32,
): TvgResult {.importc: "tvg_shape_append_path".}

proc tvgShapeGetPath*(
  paint: TvgPaint,
  cmds: ptr ptr TvgPathCommand,
  cmdsCnt: ptr uint32,
  pts: ptr ptr TvgPoint,
  ptsCnt: ptr uint32,
): TvgResult {.importc: "tvg_shape_get_path".}

proc tvgShapeSetStrokeWidth*(paint: TvgPaint, width: cfloat): TvgResult {.importc: "tvg_shape_set_stroke_width".}

proc tvgShapeGetStrokeWidth*(
  paint: TvgPaint, width: ptr cfloat
): TvgResult {.importc: "tvg_shape_get_stroke_width".}

proc tvgShapeSetStrokeColor*(
  paint: TvgPaint, r: uint8, g: uint8, b: uint8, a: uint8
): TvgResult {.importc: "tvg_shape_set_stroke_color".}

proc tvgShapeGetStrokeColor*(
  paint: TvgPaint, r: ptr uint8, g: ptr uint8, b: ptr uint8, a: ptr uint8
): TvgResult {.importc: "tvg_shape_get_stroke_color".}

proc tvgShapeSetStrokeGradient*(
  paint: TvgPaint, grad: TvgGradient
): TvgResult {.importc: "tvg_shape_set_stroke_gradient".}

proc tvgShapeGetStrokeGradient*(
  paint: TvgPaint, grad: ptr TvgGradient
): TvgResult {.importc: "tvg_shape_get_stroke_gradient".}

proc tvgShapeSetStrokeDash*(
  paint: TvgPaint, dashPattern: ptr cfloat, cnt: uint32, offset: cfloat
): TvgResult {.importc: "tvg_shape_set_stroke_dash".}

proc tvgShapeGetStrokeDash*(
  paint: TvgPaint, dashPattern: ptr ptr cfloat, cnt: ptr uint32, offset: ptr cfloat
): TvgResult {.importc: "tvg_shape_get_stroke_dash".}

proc tvgShapeSetStrokeCap*(
  paint: TvgPaint, cap: TvgStrokeCap
): TvgResult {.importc: "tvg_shape_set_stroke_cap".}

proc tvgShapeGetStrokeCap*(
  paint: TvgPaint, cap: ptr TvgStrokeCap
): TvgResult {.importc: "tvg_shape_get_stroke_cap".}

proc tvgShapeSetStrokeJoin*(
  paint: TvgPaint, join: TvgStrokeJoin
): TvgResult {.importc: "tvg_shape_set_stroke_join".}

proc tvgShapeGetStrokeJoin*(
  paint: TvgPaint, join: ptr TvgStrokeJoin
): TvgResult {.importc: "tvg_shape_get_stroke_join".}

proc tvgShapeSetStrokeMiterlimit*(
  paint: TvgPaint, miterlimit: cfloat
): TvgResult {.importc: "tvg_shape_set_stroke_miterlimit".}

proc tvgShapeGetStrokeMiterlimit*(
  paint: TvgPaint, miterlimit: ptr cfloat
): TvgResult {.importc: "tvg_shape_get_stroke_miterlimit".}

proc tvgShapeSetTrimpath*(
  paint: TvgPaint, begin: cfloat, `end`: cfloat, simultaneous: bool
): TvgResult {.importc: "tvg_shape_set_trimpath".}

proc tvgShapeSetFillColor*(
  paint: TvgPaint, r: uint8, g: uint8, b: uint8, a: uint8
): TvgResult {.importc: "tvg_shape_set_fill_color".}

proc tvgShapeGetFillColor*(
  paint: TvgPaint, r: ptr uint8, g: ptr uint8, b: ptr uint8, a: ptr uint8
): TvgResult {.importc: "tvg_shape_get_fill_color".}

proc tvgShapeSetFillRule*(
  paint: TvgPaint, rule: TvgFillRule
): TvgResult {.importc: "tvg_shape_set_fill_rule".}

proc tvgShapeGetFillRule*(
  paint: TvgPaint, rule: ptr TvgFillRule
): TvgResult {.importc: "tvg_shape_get_fill_rule".}

proc tvgShapeSetPaintOrder*(
  paint: TvgPaint, strokeFirst: bool
): TvgResult {.importc: "tvg_shape_set_paint_order".}

proc tvgShapeSetGradient*(
  paint: TvgPaint, grad: TvgGradient
): TvgResult {.importc: "tvg_shape_set_gradient".}

proc tvgShapeGetGradient*(
  paint: TvgPaint, grad: ptr TvgGradient
): TvgResult {.importc: "tvg_shape_get_gradient".}

proc tvgLinearGradientNew*(): TvgGradient {.importc: "tvg_linear_gradient_new".}

proc tvgRadialGradientNew*(): TvgGradient {.importc: "tvg_radial_gradient_new".}

proc tvgLinearGradientSet*(
  grad: TvgGradient, x1: cfloat, y1: cfloat, x2: cfloat, y2: cfloat
): TvgResult {.importc: "tvg_linear_gradient_set".}

proc tvgLinearGradientGet*(
  grad: TvgGradient, x1: ptr cfloat, y1: ptr cfloat, x2: ptr cfloat, y2: ptr cfloat
): TvgResult {.importc: "tvg_linear_gradient_get".}

proc tvgRadialGradientSet*(
  grad: TvgGradient,
  cx: cfloat,
  cy: cfloat,
  r: cfloat,
  fx: cfloat,
  fy: cfloat,
  fr: cfloat,
): TvgResult {.importc: "tvg_radial_gradient_set".}

proc tvgRadialGradientGet*(
  grad: TvgGradient,
  cx: ptr cfloat,
  cy: ptr cfloat,
  r: ptr cfloat,
  fx: ptr cfloat,
  fy: ptr cfloat,
  fr: ptr cfloat,
): TvgResult {.importc: "tvg_radial_gradient_get".}

proc tvgGradientSetColorStops*(
  grad: TvgGradient, colorStop: ptr TvgColorStop, cnt: uint32
): TvgResult {.importc: "tvg_gradient_set_color_stops".}

proc tvgGradientGetColorStops*(
  grad: TvgGradient, colorStop: ptr ptr TvgColorStop, cnt: ptr uint32
): TvgResult {.importc: "tvg_gradient_get_color_stops".}

proc tvgGradientSetSpread*(
  grad: TvgGradient, spread: TvgStrokeFill
): TvgResult {.importc: "tvg_gradient_set_spread".}

proc tvgGradientGetSpread*(
  grad: TvgGradient, spread: ptr TvgStrokeFill
): TvgResult {.importc: "tvg_gradient_get_spread".}

proc tvgGradientSetTransform*(
  grad: TvgGradient, m: ptr TvgMatrix
): TvgResult {.importc: "tvg_gradient_set_transform".}

proc tvgGradientGetTransform*(
  grad: TvgGradient, m: ptr TvgMatrix
): TvgResult {.importc: "tvg_gradient_get_transform".}

proc tvgGradientGetType*(
  grad: TvgGradient, `type`: ptr TvgType
): TvgResult {.importc: "tvg_gradient_get_type".}

proc tvgGradientDuplicate*(
  grad: TvgGradient
): TvgGradient {.importc: "tvg_gradient_duplicate".}

proc tvgGradientDel*(grad: TvgGradient): TvgResult {.importc: "tvg_gradient_del".}

proc tvgPictureNew*(): TvgPaint {.importc: "tvg_picture_new".}

proc tvgPictureLoad*(
  picture: TvgPaint, path: cstring
): TvgResult {.importc: "tvg_picture_load".}

proc tvgPictureLoadRaw*(
  picture: TvgPaint,
  data: ptr uint32,
  w: uint32,
  h: uint32,
  cs: TvgColorspace,
  copy: bool,
): TvgResult {.importc: "tvg_picture_load_raw".}

proc tvgPictureLoadData*(
  picture: TvgPaint,
  data: cstring,
  size: uint32,
  mimetype: cstring,
  rpath: cstring,
  copy: bool,
): TvgResult {.importc: "tvg_picture_load_data".}

proc tvgPictureSetAssetResolver*(
  picture: TvgPaint, resolver: TvgPictureAssetResolver, data: pointer
): TvgResult {.importc: "tvg_picture_set_asset_resolver".}

proc tvgPictureSetSize*(
  picture: TvgPaint, w: cfloat, h: cfloat
): TvgResult {.importc: "tvg_picture_set_size".}

proc tvgPictureGetSize*(
  picture: TvgPaint, w: ptr cfloat, h: ptr cfloat
): TvgResult {.importc: "tvg_picture_get_size".}

proc tvgPictureSetOrigin*(
  picture: TvgPaint, x: cfloat, y: cfloat
): TvgResult {.importc: "tvg_picture_set_origin".}

proc tvgPictureGetOrigin*(
  picture: TvgPaint, x: ptr cfloat, y: ptr cfloat
): TvgResult {.importc: "tvg_picture_get_origin".}

proc tvgPictureGetPaint*(
  picture: TvgPaint, id: uint32
): TvgPaint {.importc: "tvg_picture_get_paint".}

proc tvgPictureSetFilter*(
  picture: TvgPaint, `method`: TvgFilterMethod
): TvgResult {.importc: "tvg_picture_set_filter".}

proc tvgPictureSetAccessible*(
  picture: TvgPaint, accessible: bool
): TvgResult {.importc: "tvg_picture_set_accessible".}

proc tvgSceneNew*(): TvgPaint {.importc: "tvg_scene_new".}

proc tvgSceneAdd*(scene: TvgPaint, paint: TvgPaint): TvgResult {.importc: "tvg_scene_add".}

proc tvgSceneInsert*(
  scene: TvgPaint, target: TvgPaint, at: TvgPaint
): TvgResult {.importc: "tvg_scene_insert".}

proc tvgSceneRemove*(
  scene: TvgPaint, paint: TvgPaint
): TvgResult {.importc: "tvg_scene_remove".}

proc tvgSceneClearEffects*(
  scene: TvgPaint
): TvgResult {.importc: "tvg_scene_clear_effects".}

proc tvgSceneAddEffectGaussianBlur*(
  scene: TvgPaint, sigma: cdouble, direction: cint, border: cint, quality: cint
): TvgResult {.importc: "tvg_scene_add_effect_gaussian_blur".}

proc tvgSceneAddEffectDropShadow*(
  scene: TvgPaint,
  r: cint,
  g: cint,
  b: cint,
  a: cint,
  angle: cdouble,
  distance: cdouble,
  sigma: cdouble,
  quality: cint,
): TvgResult {.importc: "tvg_scene_add_effect_drop_shadow".}

proc tvgSceneAddEffectFill*(
  scene: TvgPaint, r: cint, g: cint, b: cint, a: cint
): TvgResult {.importc: "tvg_scene_add_effect_fill".}

proc tvgSceneAddEffectTint*(
  scene: TvgPaint,
  blackR: cint,
  blackG: cint,
  blackB: cint,
  whiteR: cint,
  whiteG: cint,
  whiteB: cint,
  intensity: cdouble,
): TvgResult {.importc: "tvg_scene_add_effect_tint".}

proc tvgSceneAddEffectTritone*(
  scene: TvgPaint,
  shadowR: cint,
  shadowG: cint,
  shadowB: cint,
  midtoneR: cint,
  midtoneG: cint,
  midtoneB: cint,
  highlightR: cint,
  highlightG: cint,
  highlightB: cint,
  blend: cint,
): TvgResult {.importc: "tvg_scene_add_effect_tritone".}

proc tvgTextNew*(): TvgPaint {.importc: "tvg_text_new".}

proc tvgTextSetFont*(text: TvgPaint, name: cstring): TvgResult {.importc: "tvg_text_set_font".}

proc tvgTextSetSize*(text: TvgPaint, size: cfloat): TvgResult {.importc: "tvg_text_set_size".}

proc tvgTextSetText*(text: TvgPaint, utf8: cstring): TvgResult {.importc: "tvg_text_set_text".}

proc tvgTextGetText*(text: TvgPaint): cstring {.importc: "tvg_text_get_text".}

proc tvgTextAlign*(text: TvgPaint, x: cfloat, y: cfloat): TvgResult {.importc: "tvg_text_align".}

proc tvgTextLayout*(text: TvgPaint, w: cfloat, h: cfloat): TvgResult {.importc: "tvg_text_layout".}

proc tvgTextWrapMode*(text: TvgPaint, mode: TvgTextWrap): TvgResult {.importc: "tvg_text_wrap_mode".}

proc tvgTextLineCount*(text: TvgPaint): uint32 {.importc: "tvg_text_line_count".}

proc tvgTextSpacing*(text: TvgPaint, letter: cfloat, line: cfloat): TvgResult {.importc: "tvg_text_spacing".}

proc tvgTextSetItalic*(text: TvgPaint, shear: cfloat): TvgResult {.importc: "tvg_text_set_italic".}

proc tvgTextSetOutline*(
  text: TvgPaint, width: cfloat, r: uint8, g: uint8, b: uint8
): TvgResult {.importc: "tvg_text_set_outline".}

proc tvgTextSetColor*(text: TvgPaint, r: uint8, g: uint8, b: uint8): TvgResult {.importc: "tvg_text_set_color".}

proc tvgTextSetGradient*(text: TvgPaint, gradient: TvgGradient): TvgResult {.importc: "tvg_text_set_gradient".}

proc tvgTextGetTextMetrics*(text: TvgPaint, metrics: ptr TvgTextMetrics): TvgResult {.importc: "tvg_text_get_text_metrics".}

proc tvgTextGetGlyphMetrics*(
  text: TvgPaint, ch: cstring, metrics: ptr TvgGlyphMetrics
): TvgResult {.importc: "tvg_text_get_glyph_metrics".}

proc tvgFontLoad*(path: cstring): TvgResult {.importc: "tvg_font_load".}

proc tvgFontLoadData*(
  name: cstring, data: cstring, size: uint32, mimetype: cstring, copy: bool
): TvgResult {.importc: "tvg_font_load_data".}

proc tvgFontUnload*(path: cstring): TvgResult {.importc: "tvg_font_unload".}

proc tvgSaverNew*(): TvgSaver {.importc: "tvg_saver_new".}

proc tvgSaverSavePaint*(
  saver: TvgSaver, paint: TvgPaint, path: cstring, quality: uint32
): TvgResult {.importc: "tvg_saver_save_paint".}

proc tvgSaverSaveAnimation*(
  saver: TvgSaver,
  animation: TvgAnimation,
  path: cstring,
  quality: uint32,
  fps: uint32,
): TvgResult {.importc: "tvg_saver_save_animation".}

proc tvgSaverSync*(saver: TvgSaver): TvgResult {.importc: "tvg_saver_sync".}

proc tvgSaverDel*(saver: TvgSaver): TvgResult {.importc: "tvg_saver_del".}

proc tvgAnimationNew*(): TvgAnimation {.importc: "tvg_animation_new".}

proc tvgAnimationSetFrame*(animation: TvgAnimation, no: cfloat): TvgResult {.importc: "tvg_animation_set_frame".}

proc tvgAnimationGetPicture*(animation: TvgAnimation): TvgPaint {.importc: "tvg_animation_get_picture".}

proc tvgAnimationGetFrame*(animation: TvgAnimation, no: ptr cfloat): TvgResult {.importc: "tvg_animation_get_frame".}

proc tvgAnimationGetTotalFrame*(animation: TvgAnimation, cnt: ptr cfloat): TvgResult {.importc: "tvg_animation_get_total_frame".}

proc tvgAnimationGetDuration*(animation: TvgAnimation, duration: ptr cfloat): TvgResult {.importc: "tvg_animation_get_duration".}

proc tvgAnimationSetSegment*(
  animation: TvgAnimation, begin: cfloat, `end`: cfloat
): TvgResult {.importc: "tvg_animation_set_segment".}

proc tvgAnimationGetSegment*(
  animation: TvgAnimation, begin: ptr cfloat, `end`: ptr cfloat
): TvgResult {.importc: "tvg_animation_get_segment".}

proc tvgAnimationDel*(animation: TvgAnimation): TvgResult {.importc: "tvg_animation_del".}

proc tvgAccessorNew*(): TvgAccessor {.importc: "tvg_accessor_new".}

proc tvgAccessorDel*(accessor: TvgAccessor): TvgResult {.importc: "tvg_accessor_del".}

proc tvgAccessorSet*(
  accessor: TvgAccessor,
  paint: TvgPaint,
  `func`: proc(paint: TvgPaint, data: pointer): bool {.cdecl.},
  data: pointer,
): TvgResult {.importc: "tvg_accessor_set".}

proc tvgAccessorGenerateId*(name: cstring): uint32 {.importc: "tvg_accessor_generate_id".}

proc tvgAccessorGetName*(accessor: TvgAccessor, id: uint32): cstring {.importc: "tvg_accessor_get_name".}

proc tvgLottieAnimationNew*(): TvgAnimation {.importc: "tvg_lottie_animation_new".}

proc tvgLottieAnimationGenSlot*(animation: TvgAnimation, slot: cstring): uint32 {.importc: "tvg_lottie_animation_gen_slot".}

proc tvgLottieAnimationApplySlot*(animation: TvgAnimation, id: uint32): TvgResult {.importc: "tvg_lottie_animation_apply_slot".}

proc tvgLottieAnimationDelSlot*(animation: TvgAnimation, id: uint32): TvgResult {.importc: "tvg_lottie_animation_del_slot".}

proc tvgLottieAnimationSetMarker*(animation: TvgAnimation, marker: cstring): TvgResult {.importc: "tvg_lottie_animation_set_marker".}

proc tvgLottieAnimationGetMarkersCnt*(
  animation: TvgAnimation, cnt: ptr uint32
): TvgResult {.importc: "tvg_lottie_animation_get_markers_cnt".}

proc tvgLottieAnimationGetMarker*(
  animation: TvgAnimation, idx: uint32, name: cstringArray
): TvgResult {.importc: "tvg_lottie_animation_get_marker".}

proc tvgLottieAnimationGetMarkerInfo*(
  animation: TvgAnimation,
  idx: uint32,
  name: cstringArray,
  begin: ptr cfloat,
  `end`: ptr cfloat,
): TvgResult {.importc: "tvg_lottie_animation_get_marker_info".}

proc tvgLottieAnimationTween*(
  animation: TvgAnimation, `from`: cfloat, to: cfloat, progress: cfloat
): TvgResult {.importc: "tvg_lottie_animation_tween".}

proc tvgLottieAnimationSetQuality*(animation: TvgAnimation, value: uint8): TvgResult {.importc: "tvg_lottie_animation_set_quality".}

type TvgAudioInfo* {.bycopy.} = object
  src*: cstring
  mimeType*: cstring
  size*: uint32
  offset*: cfloat
  volume*: cfloat
  active*: bool
  embedded*: bool

type TvgAudioResolver* = proc(info: ptr TvgAudioInfo, data: pointer) {.cdecl.}

proc tvgLottieAnimationSetAudioResolver*(
  animation: TvgAnimation, resolver: TvgAudioResolver, data: pointer
): TvgResult {.importc: "tvg_lottie_animation_set_audio_resolver".}

{.pop.}
