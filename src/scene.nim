import thorvg_capi
import engine
import canvas, paint

type
  SceneObj* = object of PaintObj
    ## A class to composite children paints.
    ##
    ## As the traditional graphics rendering method, TVG also enables a scene-graph mechanism.
    ## This feature supports managing multiple paints as a single group paint.
    ##
    ## As a group, the scene can be transformed, made translucent, and composited with other 
    ## target paints. Its children will be affected by the scene's world transformation.
    ##
    ## .. warning:: This class is not designed for inheritance.
  Scene* = ref SceneObj

proc newScene*(): Scene =
  ## Creates a new Scene object.
  ##
  ## This function allocates and returns a new Scene instance.
  ## Throws a `ThorVGError` if the creation fails.
  let handle = tvgSceneNew()
  if handle == nil:
    raise newException(ThorVGError, "Failed to create scene")
  result = Scene(handle: handle)
  discard tvgPaintRef(handle)

proc init*(scene: var Scene, canvas: SwCanvas): bool {.discardable.} =
  ## Initializes the scene and pushes it onto the provided canvas if it hasn't been initialized yet.
  ##
  ## Returns `true` if a new scene was successfully created and pushed onto the canvas.
  if scene.handle == nil:
    scene = newScene()
    discard canvas.push(scene)
    result = true

proc add*(scene: Scene, paint: Paint) =
  ## Appends a paint object to the scene.
  ##
  ## The ownership of the paint object is transferred to the scene upon addition.
  ## The rendering order of the paints is the same as the order in which they were added.
  ## Consider sorting the paints before adding them if you intend to use layering.
  ##
  ## * `paint`: The Paint object to be added into the scene.
  checkResult(tvgSceneAdd(scene.handle, paint.handle))

proc push*(scene: Scene, paint: Paint) =
  ## An alias for `add`. Appends a paint object to the scene.
  scene.add(paint)

proc insert*(scene: Scene, target: Paint, at: Paint) =
  ## Inserts a paint object into the scene immediately before a specified paint object.
  ##
  ## * `target`: The Paint object to be added into the scene.
  ## * `at`: An existing Paint object in the scene before which the `target` paint object will be added.
  checkResult(tvgSceneInsert(scene.handle, target.handle, at.handle))

proc remove*(scene: Scene, paint: Paint) =
  ## Removes a specified paint object from the scene.
  ##
  ## * `paint`: The Paint object to be removed from the scene.
  checkResult(tvgSceneRemove(scene.handle, paint.handle))

proc clearEffects*(scene: Scene) =
  ## Clears all post-processing effects applied to the scene.
  checkResult(tvgSceneClearEffects(scene.handle))

proc resetEffects*(scene: Scene) =
  ## An alias for `clearEffects`. Clears all post-processing effects from the scene.
  scene.clearEffects()

proc gaussianBlur*(scene: Scene, sigma: float, direction, border, quality: int) =
  ## Applies a post-processing blur effect with a Gaussian filter to the scene.
  ##
  ## * `sigma`: The standard deviation of the Gaussian filter. Must be `> 0`.
  ## * `direction`: The blur direction. `0` = both, `1` = horizontal, `2` = vertical.
  ## * `border`: The border treatment type. `0` = duplicate, `1` = wrap.
  ## * `quality`: The processing quality level. Range: `0` to `100`.
  checkResult:
    tvgSceneAddEffectGaussianBlur(
      scene.handle, sigma.cdouble, direction.cint, border.cint, quality.cint
    )

proc dropShadow*(
    scene: Scene, r, g, b, a: uint8, angle, distance, sigma: float, quality: int
) =
  ## Applies a post-processing drop shadow effect with a Gaussian Blur filter to the scene.
  ##
  ## * `r`, `g`, `b`: The color components of the shadow. Range: `0` to `255`.
  ## * `a`: The opacity component of the shadow. Range: `0` to `255`.
  ## * `angle`: The angle of the shadow offset in degrees. Range: `0` to `360`.
  ## * `distance`: The distance of the shadow offset.
  ## * `sigma`: The blur radius (standard deviation) for the shadow's edge. Must be `> 0`.
  ## * `quality`: The processing quality level. Range: `0` to `100`.
  checkResult(
    tvgSceneAddEffectDropShadow(
      scene.handle, r.cint, g.cint, b.cint, a.cint, angle.cdouble, distance.cdouble,
      sigma.cdouble, quality.cint,
    )
  )

proc fillOverride*(scene: Scene, r, g, b, a: uint8) =
  ## Overrides the scene content color with the given fill information.
  ##
  ## * `r`, `g`, `b`: The fill color components. Range: `0` to `255`.
  ## * `a`: The fill opacity component. Range: `0` to `255`.
  checkResult(tvgSceneAddEffectFill(scene.handle, r.cint, g.cint, b.cint, a.cint))

proc tint*(
    scene: Scene,
    blackR, blackG, blackB: uint8,
    whiteR, whiteG, whiteB: uint8,
    intensity: float,
) =
  ## Tints the current scene color using the provided black and white color target parameters.
  ##
  ## * `blackR`, `blackG`, `blackB`: The color target mapped to black. Range: `0` to `255`.
  ## * `whiteR`, `whiteG`, `whiteB`: The color target mapped to white. Range: `0` to `255`.
  ## * `intensity`: The intensity/strength of the tint effect. Range: `0.0` to `100.0`.
  checkResult(
    tvgSceneAddEffectTint(
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
  ## Applies a tritone color effect to the scene using three color parameters for shadows, 
  ## midtones, and highlights. A blending factor determines the mix between the original 
  ## color and the tritone colors.
  ##
  ## * `shadow`: The RGB color mapping for dark tones. Each component range: `0` to `255`.
  ## * `midtone`: The RGB color mapping for midtones. Each component range: `0` to `255`.
  ## * `highlight`: The RGB color mapping for bright tones. Each component range: `0` to `255`.
  ## * `blend`: The blending intensity value. Range: `0` to `255`.
  checkResult(
    tvgSceneAddEffectTritone(
      scene.handle, shadow.r.cint, shadow.g.cint, shadow.b.cint, midtone.r.cint,
      midtone.g.cint, midtone.b.cint, highlight.r.cint, highlight.g.cint,
      highlight.b.cint, blend.cint,
    )
  )
