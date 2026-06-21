import thorvg_capi
import engine
import canvas, paint

type
  SceneObj* = object of PaintObj
  Scene* = ref SceneObj

proc newScene*(): Scene =
  let handle = tvgSceneNew()
  if handle == nil:
    raise newException(ThorVGError, "Failed to create scene")
  result = Scene(handle: handle)
  discard tvgPaintRef(handle)

proc init*(scene: var Scene, canvas: SwCanvas): bool {.discardable.} =
  if scene.handle == nil:
    scene = newScene()
    discard canvas.push(scene)
    result = true

proc add*(scene: Scene, paint: Paint) =
  checkResult(tvg_scene_add(scene.handle, paint.handle))

proc push*(scene: Scene, paint: Paint) =
  scene.add(paint)

proc insert*(scene: Scene, target: Paint, at: Paint) =
  checkResult(tvg_scene_insert(scene.handle, target.handle, at.handle))

proc remove*(scene: Scene, paint: Paint) =
  checkResult(tvg_scene_remove(scene.handle, paint.handle))

proc clearEffects*(scene: Scene) =
  checkResult(tvg_scene_clear_effects(scene.handle))

proc resetEffects*(scene: Scene) =
  scene.clearEffects()

proc gaussianBlur*(scene: Scene, sigma: float, direction, border, quality: int) =
  checkResult:
    tvgSceneAddEffectGaussianBlur(
      scene.handle, sigma.cdouble, direction.cint, border.cint, quality.cint
    )

proc dropShadow*(
    scene: Scene, r, g, b, a: uint8, angle, distance, sigma: float, quality: int
) =
  checkResult(
    tvg_scene_add_effect_drop_shadow(
      scene.handle, r.cint, g.cint, b.cint, a.cint, angle.cdouble, distance.cdouble,
      sigma.cdouble, quality.cint,
    )
  )

proc fillOverride*(scene: Scene, r, g, b, a: uint8) =
  checkResult(tvg_scene_add_effect_fill(scene.handle, r.cint, g.cint, b.cint, a.cint))

proc tint*(
    scene: Scene,
    blackR, blackG, blackB: uint8,
    whiteR, whiteG, whiteB: uint8,
    intensity: float,
) =
  checkResult(
    tvg_scene_add_effect_tint(
      scene.handle, blackR.cint, blackG.cint, blackB.cint, whiteR.cint, whiteG.cint,
      whiteB.cint, intensity.cdouble,
    )
  )

proc tritone*(
    scene: Scene,
    shadow: tuple[r, g, b: uint8],
    midtone: tuple[r, g, b: uint8],
    highlight: tuple[r, g, b: uint8],
    blend: uint8,
) =
  checkResult(
    tvg_scene_add_effect_tritone(
      scene.handle, shadow.r.cint, shadow.g.cint, shadow.b.cint, midtone.r.cint,
      midtone.g.cint, midtone.b.cint, highlight.r.cint, highlight.g.cint,
      highlight.b.cint, blend.cint,
    )
  )
